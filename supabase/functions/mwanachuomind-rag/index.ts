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
    const { query, course_id, document_id, history = [] } = await req.json();

    console.log(`[RAG] Received request: ${query}, Doc: ${document_id}`);
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') ?? '');

    // 1. Generate Query Embedding
    console.log(`[RAG] Embedding query...`);
    const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004"});
    const embedResult = await embeddingModel.embedContent(query);
    const queryEmbedding = embedResult.embedding.values;
    console.log(`[RAG] Query embedded. Dim: ${queryEmbedding.length}`);

    // 2. Perform Vector Similarity Search via RPC
    const { data: chunks, error: rpcError } = await supabase.rpc('match_documents_v2', {
      query_embedding: queryEmbedding,
      match_threshold: 0.5,
      match_count: 5,
      filter_course_id: course_id || null,
      filter_document_id: document_id || null
    });

    if (rpcError) {
      console.error(`[RAG] RPC Error:`, rpcError);
      throw rpcError;
    }
    console.log(`[RAG] Found ${chunks?.length || 0} chunks.`);

    // 3. Construct Prompt with Context
    const context = chunks?.map((c: any) => c.content).join('\n---\n') || 'No relevant context found.';
    console.log(`[RAG] Calling Gemini 2.0 Flash...`);
    const systemPrompt = `You are "Mwanachuomind", an expert academic assistant for university students.
    Your goal is to provide high-quality, grounded answers based on the provided course material.
    
    Context:
    ${context}
    
    Chat History:
    ${JSON.stringify(history)}
    
    User Question: ${query}
    
    Instructions:
    - Use the provided context to answer.
    - If the user asks for a "Report", "Summary", or "Revision Guide", format the output with clear H1/H2 headers, bullet points, and bold key terms.
    - Use tables if comparisons are requested (IBM Docling helps preserve these).
    - If the answer isn't in the context, but is related to the course, use your general knowledge but clearly state what is "outside the provided document".
    - Respond in a helpful, encouraging tone.
    - Output MUST be in valid Markdown.`;

    // 4. Generate Answer using Gemini Flash Latest (stable naming)
    console.log(`[RAG] Using gemini-flash-latest...`);
    const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });
    const result = await model.generateContentStream(systemPrompt);

    // 5. Stream the response
    const stream = new ReadableStream({
      async start(controller) {
        for await (const chunk of result.stream) {
          const text = chunk.text();
          controller.enqueue(new TextEncoder().encode(text));
        }
        controller.close();
      },
    });

    return new Response(stream, {
      headers: { ...corsHeaders, 'Content-Type': 'text/plain' },
    });

  } catch (error) {
    console.error("[RAG] Global Error:", error);
    const envKeys = Object.keys(Deno.env.toObject());
    return new Response(JSON.stringify({ 
      error: error.message, 
      stack: error.stack,
      available_env_vars: envKeys,
      details: error
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
