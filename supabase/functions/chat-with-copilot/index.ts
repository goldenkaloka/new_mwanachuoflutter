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

    const body = await req.json();
    const { message, course_id, note_id } = body;
    
    console.log(`[Chat] Query: ${message}, Note: ${note_id}, Course: ${course_id}`);

    if (!message || (!course_id && !note_id)) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);

    // 1. Generate embedding with Gemini (using stable gemini-embedding-001)
    const embeddingModel = genAI.getGenerativeModel({ model: "gemini-embedding-001" });
    const embeddingResult = await embeddingModel.embedContent(message);
    const embedding = embeddingResult.embedding.values;

    // 2. Search database - Handle empty strings as null for UUIDs
    const { data: chunks, error: searchError } = await supabase.rpc('match_course_content', {
      p_course_id: course_id || null,
      query_embedding: embedding,
      match_threshold: 0,
      match_count: 5,
      p_filter_id: (note_id && note_id.trim() !== '') ? note_id : null
    });

    if (searchError) {
      console.error("[Chat] Search Error:", searchError);
      throw new Error(`Database search failed: ${searchError.message}`);
    }

    // 3. Build context
    const contextText = (chunks || [])
      .map((c: any) => `Source: ${c.source_title}\n${c.content}`)
      .join("\n\n---\n\n") || "No context found.";

    // 4. Generate response with Stable Model (GA)
    const chatModel = genAI.getGenerativeModel({ 
      model: "gemini-1.5-flash-002",
      generationConfig: { temperature: 1.0 }
    });

    const prompt = `You are MwanachuoCopilot.\n\nContext:\n${contextText}\n\nQuestion: ${message}\n\nAnswer based on the context above:`;

    const result = await chatModel.generateContentStream(prompt);

    // 5. Stream response
    const stream = new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        try {
          for await (const chunk of result.stream) {
            const text = chunk.text();
            if (text) {
              controller.enqueue(encoder.encode(`data: ${JSON.stringify({ answer: text })}\n\n`));
            }
          }
          controller.enqueue(encoder.encode(`data: [DONE]\n\n`));
          controller.close();
        } catch (e: any) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: e.message })}\n\n`));
          controller.error(e);
        }
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
