import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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
  if (!payload || !payload.token || !payload.platform) {
    return new Response(JSON.stringify({ error: "token and platform are required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: { Authorization: authHeader },
    },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unable to resolve user" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const { error } = await adminClient.from("device_tokens").upsert(
    {
      token: payload.token,
      platform: payload.platform,
      device_model: payload.deviceModel ?? null,
      user_id: user.id,
    },
    { onConflict: "token" },
  );

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({
      status: "ok",
      updated: true,
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
});

