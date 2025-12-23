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
    const { query, course_id, history, document_id } = await req.json();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') ?? '');

    // 1. Embed Query
    const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004"});
    const embedResult = await embeddingModel.embedContent(query);
    const queryEmbedding = embedResult.embedding.values;

    // 2. Search Docs - filter by document_id if provided
    let documents: any[] = [];
    
    if (document_id) {
      // If a specific document is mentioned, search only within that document's chunks
      const { data, error } = await supabase.rpc('match_documents', {
        query_embedding: queryEmbedding,
        match_threshold: 0.3, // Lower threshold for specific doc search
        match_count: 10, // Get more chunks from the specific doc
        filter_course_id: course_id
      });
      
      if (error) throw error;
      
      // Filter to only chunks from the specific document
      documents = (data || []).filter((d: any) => d.document_id === document_id);
    } else {
      // Normal search across all course documents
      const { data, error } = await supabase.rpc('match_documents', {
        query_embedding: queryEmbedding,
        match_threshold: 0.5,
        match_count: 5,
        filter_course_id: course_id
      });
      
      if (error) throw error;
      documents = data || [];
    }

    // 3. Construct Prompt
    const context = documents.map((d: any) => d.content).join('\n---\n') || '';
    
    let documentNote = '';
    if (document_id && documents.length > 0) {
      // Get document title
      const { data: docData } = await supabase
        .from('documents')
        .select('title')
        .eq('id', document_id)
        .single();
      
      if (docData) {
        documentNote = `\n\nNote: The student is specifically asking about the document "${docData.title}".`;
      }
    }
    
    const systemPrompt = `You are a helpful AI teaching assistant called Mwanachuomind.
    You are helping a student with a question based on the following course materials.${documentNote}
    
    Context:
    ${context}
    
    Question: ${query}
    
    Answer the question based on the context provided. If the answer is not in the context, say so, but try to be helpful based on general knowledge if possible, but explicitly state that it's outside the course context.`;

    // 4. Generate Response
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash"});
    const result = await model.generateContentStream(systemPrompt);

    // Streaming response
    const stream = new ReadableStream({
        async start(controller) {
            for await (const chunk of result.stream) {
                const text = chunk.text();
                controller.enqueue(new TextEncoder().encode(text));
            }
            controller.close();
        }
    });

    return new Response(stream, {
        headers: { ...corsHeaders, 'Content-Type': 'text/plain' }
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});

