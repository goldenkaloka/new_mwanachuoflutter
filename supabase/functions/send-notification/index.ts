import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') || '';
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') || '';

interface NotificationPayload {
  user_id: string;
  title: string;
  message: string;
  type: string;
  action_url?: string;
  metadata?: Record<string, any>;
}

Deno.serve(async (req) => {
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Allow calls from database triggers (internal) without JWT
    // Check if this is an internal call from pg_net (database trigger)
    const userAgent = req.headers.get('user-agent') || '';
    const isInternalCall = userAgent.includes('pg_net') || 
                          req.headers.get('authorization') === null ||
                          req.headers.get('authorization') === '';
    
    // For internal calls from database triggers, skip JWT verification
    // For external calls, you can add auth validation here if needed
    // Since this function is called internally by database triggers, we accept all calls

    const payload: NotificationPayload = await req.json();
    const { user_id, title, message, type, action_url, metadata } = payload;

    if (!user_id || !title || !message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, message' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'OneSignal credentials not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get device tokens (OneSignal player IDs) for the user
    const { data: deviceTokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('player_id, platform')
      .eq('user_id', user_id);

    if (tokensError) {
      console.error('Error fetching device tokens:', tokensError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch device tokens', details: tokensError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!deviceTokens || deviceTokens.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No device tokens found for user', user_id }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Extract player IDs
    const playerIds = deviceTokens.map(token => token.player_id).filter(Boolean);

    if (playerIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No valid player IDs found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Prepare OneSignal notification payload
    const oneSignalPayload = {
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: playerIds,
      headings: { en: title },
      contents: { en: message },
      data: {
        type: type,
        actionUrl: action_url,
        ...metadata,
      },
      // Ensure notifications show with sound and banner
      priority: 10, // High priority
      sound: 'default', // Play default notification sound
      // iOS specific
      ios_sound: 'default',
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
    };

    // Send notification via OneSignal API
    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(oneSignalPayload),
    });

    const oneSignalResult = await oneSignalResponse.json();

    if (!oneSignalResponse.ok) {
      console.error('OneSignal API error:', oneSignalResult);
      return new Response(
        JSON.stringify({ 
          error: 'Failed to send notification via OneSignal',
          details: oneSignalResult 
        }),
        { status: oneSignalResponse.status, headers: { 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Notification sent successfully',
        onesignal_response: oneSignalResult,
        players_sent_to: playerIds.length
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in send-notification function:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

