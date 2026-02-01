
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      throw new Error('User not authenticated')
    }

    const { amount, phone, type, provider, metadata } = await req.json()

    if (!amount || !phone || !type) {
      throw new Error('Missing required fields: amount, phone, type')
    }

    // 1. Generate Order ID
    const orderId = crypto.randomUUID()

    // 2. Create Pending Order in Database
    const { error: orderError } = await supabaseClient
      .from('zenopay_orders')
      .insert({
        order_id: orderId,
        user_id: user.id,
        amount: amount,
        status: 'pending',
        type: type, // 'wallet_topup', 'subscription', 'promotion'
        metadata: { ...metadata, provider: provider || 'unknown' }
      })

    if (orderError) throw orderError

    // 3. Call ZenoPay API
    const zenoApiKey = Deno.env.get('ZENO_API_KEY')
    if (!zenoApiKey) throw new Error('Server misconfiguration: Missing ZENO_API_KEY')

    // Webhook URL (Construct dynamically or use env var)
    const webhookUrl = Deno.env.get('ZENO_WEBHOOK_URL') || 'https://pdtjcemyrdwvlqhrzyls.supabase.co/functions/v1/zenopay-webhook'

    const response = await fetch('https://zenoapi.com/api/payments/mobile_money_tanzania', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': zenoApiKey
      },
      body: JSON.stringify({
        order_id: orderId,
        buyer_email: user.email || 'customer@mwanachuo.com',
        buyer_name: user.user_metadata?.name || 'Customer',
        buyer_phone: phone, // Must be 07XXXXXXXX
        amount: amount,
        webhook_url: webhookUrl,
        mno_name: provider
      })
    })

    const data = await response.json()
    
    // Log the ZenoPay response for debugging
    console.log('ZenoPay API Response:', JSON.stringify(data, null, 2))

    if (data.status !== 'success') {
       // Mark order as failed in DB
       await supabaseClient
        .from('zenopay_orders')
        .update({ status: 'failed', metadata: { ...metadata, error: data.message || data } })
        .eq('order_id', orderId)

       // Return detailed error to client
       return new Response(
        JSON.stringify({ 
          error: data.message || 'Payment initiation failed',
          details: data,
          order_id: orderId
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    return new Response(
      JSON.stringify({ ...data, order_id: orderId }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        stack: error.stack 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
