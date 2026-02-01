
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // ZenoPay sends x-api-key in header, verify it matches ours? 
  // Docs say: "ZenoPay will send the x-api-key in the request header... Verify this key"
  
  const requestApiKey = req.headers.get('x-api-key')
  const envApiKey = Deno.env.get('ZENO_API_KEY')

  if (requestApiKey !== envApiKey) {
     return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
    )
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Use Service Role to bypass RLS for updates
    )

    const payload = await req.json()
    // Payload: { order_id, payment_status, reference, metadata, ... }

    if (payload.payment_status === 'COMPLETED') {
        const orderId = payload.order_id

        // 1. Fetch Order Details
        const { data: order, error: orderError } = await supabaseClient
            .from('zenopay_orders')
            .select('*')
            .eq('order_id', orderId)
            .single()

        if (orderError || !order) {
             throw new Error('Order not found')
        }

        if (order.status === 'completed') {
             return new Response(JSON.stringify({ message: 'Already processed' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 })
        }

        // 2. Process based on Type
        if (order.type === 'wallet_topup') {
            // Credit Wallet
            const { error: rpcError } = await supabaseClient.rpc('credit_wallet_balance', {
                p_user_id: order.user_id,
                p_amount: order.amount,
                p_order_id: orderId,
                p_description: 'ZenoPay Deposit: ' + payload.reference
            })
            if (rpcError) throw rpcError
        } 
        else if (order.type === 'subscription') {
             // Activate Subscription
             // Assuming seller_id is user_id for now
             // Calculate end date (1 month from now)
             const startDate = new Date()
             const endDate = new Date()
             endDate.setMonth(endDate.getMonth() + 1)

             // Update or Insert Subscription
             // Note: You should have a table logic for this. Adapting to existing `seller_subscriptions`
             const { error: subError } = await supabaseClient
                .from('seller_subscriptions')
                .upsert({
                    seller_id: order.user_id,
                    plan_id: 'premium_business', // or from metadata
                    status: 'active',
                    billing_period: 'monthly',
                    current_period_start: startDate.toISOString(),
                    current_period_end: endDate.toISOString(),
                    auto_renew: false, // Default to false for manual mobile money payments?
                    is_trial: false
                })
             
             if (subError) throw subError

             // Mark order completed
             await supabaseClient.from('zenopay_orders').update({ status: 'completed', completed_at: new Date().toISOString() }).eq('order_id', orderId)
        }
        else if (order.type === 'promotion') {
             // Activate Promotion
             // Metadata should contain promotion_id or details
             const promotionId = order.metadata?.promotion_id
             if (promotionId) {
                await supabaseClient
                    .from('promotions')
                    .update({ status: 'active', start_date: new Date().toISOString() }) // Simplified logic
                    .eq('id', promotionId)
             }
             // Mark order completed
             await supabaseClient.from('zenopay_orders').update({ status: 'completed', completed_at: new Date().toISOString() }).eq('order_id', orderId)
        }
    }

    return new Response(
      JSON.stringify({ message: 'Webhook received' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
