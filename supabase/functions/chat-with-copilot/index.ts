import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;

    if (!geminiKey) throw new Error("Missing GEMINI_API_KEY");

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);
    
    // Get Request Body
    const { message, note_id, history } = await req.json();

    if (!message || !note_id) {
        return new Response(JSON.stringify({ error: "Missing message or note_id" }), { status: 400, headers: corsHeaders });
    }

    // 1. Generate Embedding for the User's Question
    const embeddingModel = genAI.getGenerativeModel({ model: "embedding-001" });
    const embeddingResult = await embeddingModel.embedContent(message);
    const embedding = embeddingResult.embedding.values;

    // 2. Search for Relevant Chunks (RAG)
    const { data: chunks, error: searchError } = await supabase.rpc('match_note_chunks', {
        query_embedding: embedding,
        match_threshold: 0.5, // Adjust sensitivity
        match_count: 5,
        filter: { note_id: note_id }
    });

    if (searchError) throw searchError;

    // 3. Construct Context
    const contextText = chunks?.map((c: any) => c.content).join("\n\n") || "";
    
    // 4. Generate Answer with Gemini
    const chatModel = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const prompt = `
    You are an AI study assistant "MwanachuoCopilot". 
    Answer the user's question based ONLY on the following context derived from their course notes.
    If the answer is not in the context, say "I couldn't find the answer in this note."
    
    Context:
    ${contextText}
    
    History:
    ${JSON.stringify(history || [])}
    
    User Question: ${message}
    `;

    const result = await chatModel.generateContent(prompt);
    const response = result.response.text();

    return new Response(JSON.stringify({ answer: response }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
