import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

if (!FCM_SERVER_KEY) {
  console.warn("FCM_SERVER_KEY is not set. Notifications cannot be delivered.");
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const payload = await req.json().catch(() => null);
  if (!payload) {
    return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { title, body, conversationId, senderId, userIds, data } = payload;
  if (!title || !body) {
    return new Response(JSON.stringify({ error: "title and body are required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: { Authorization: authHeader },
    },
  });

  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unable to resolve user" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  let targetUserIds: string[] = [];

  if (Array.isArray(userIds) && userIds.length > 0) {
    targetUserIds = userIds.filter((id: unknown): id is string => typeof id === "string");
  } else if (conversationId) {
    const { data: conversation, error: conversationError } = await adminClient
      .from("conversations")
      .select("user1_id, user2_id")
      .eq("id", conversationId)
      .maybeSingle();

    if (conversationError || !conversation) {
      return new Response(JSON.stringify({ error: "Conversation not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    const participants = [conversation.user1_id, conversation.user2_id].filter(Boolean);
    const sender = senderId ?? user.id;
    targetUserIds = participants.filter((id) => id !== sender);
  }

  if (targetUserIds.length === 0) {
    return new Response(JSON.stringify({ error: "No target users resolved" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { data: tokensResult, error: tokenError } = await adminClient
    .from("device_tokens")
    .select("token")
    .in("user_id", targetUserIds);

  if (tokenError) {
    return new Response(JSON.stringify({ error: tokenError.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const tokens = Array.from(
    new Set(
      (tokensResult ?? [])
        .map((row) => row.token as string | null)
        .filter((token): token is string => Boolean(token)),
    ),
  );

  if (!FCM_SERVER_KEY) {
    return new Response(
      JSON.stringify({ error: "FCM server key missing on server", discardedTokens: tokens.length }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  if (tokens.length === 0) {
    return new Response(JSON.stringify({ error: "No registered tokens" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  const chunkSize = 500;
  const results = [];

  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    const fcmPayload = {
      registration_ids: chunk,
      notification: { title, body },
      data: data ?? {},
    };

    const fcmResponse = await fetch(FCM_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify(fcmPayload),
    });

    const responseBody = await fcmResponse.text();
    results.push({
      status: fcmResponse.status,
      body: responseBody,
    });
  }

  return new Response(
    JSON.stringify({
      status: "ok",
      batches: results.length,
      tokens: tokens.length,
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
});

