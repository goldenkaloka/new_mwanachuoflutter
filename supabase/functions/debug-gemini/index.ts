import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;
    if (!geminiKey) throw new Error("Missing GEMINI_API_KEY");

    // We keep using the SDK to see if it has a listModels method exposed or if we need to fetch raw
    // The JS SDK doesn't always expose listModels easily in the main class, strictly speaking it's on the model manager or via REST.
    // Let's try to just hit the REST API directly to be 100% sure what the server sees, avoiding SDK wrappers.
    
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${geminiKey}`);
    const data = await response.json();
    const names = data.models ? data.models.map((m: any) => m.name).join('\n') : "No models found or error";

    return new Response(names, {
      headers: { ...corsHeaders, 'Content-Type': 'text/plain' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
