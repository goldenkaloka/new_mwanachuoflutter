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
    const { message, query, course_id, note_id, history, mode, limit } = body;
    const userQuery = message || query;
    
    console.log(`[Chat] Mode: ${mode || 'chat'}, Query: ${userQuery}, Note: ${note_id}, Course: ${course_id}`);

    if (!userQuery) {
      return new Response(
        JSON.stringify({ error: "Missing query/message" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);

    // 1. Generate embedding with models/text-embedding-004
    console.log(`[Chat] Step 1: Generating embedding for: "${userQuery.substring(0, 20)}..."`);
    const embeddingModel = genAI.getGenerativeModel({ model: "models/text-embedding-004" });
    const embeddingResult = await embeddingModel.embedContent(userQuery);
    const embedding = embeddingResult.embedding.values;
    console.log(`[Chat] Step 2: Embedding ready. Length: ${embedding.length}`);

    // Helper to ensure valid UUIDs or null
    const toUuid = (id: any) => (id && typeof id === 'string' && id.length === 36) ? id : null;

    // 2. Handle SEARCH mode (Return raw notes/documents)
    if (mode === 'search') {
      console.log("[Chat] Step 3: Search Mode");
      const { data: searchResults, error: searchError } = await supabase.rpc('search_notes', {
        p_query_embedding: embedding,
        p_course_id: toUuid(course_id),
        p_match_count: limit || 10,
        p_match_threshold: 0.2
      });
      
      if (searchError) {
        console.error("[Chat] Search Error:", searchError);
        throw searchError;
      }
      
      return new Response(JSON.stringify(searchResults || []), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 3. Proceed with CHAT mode (Existing logic)
    console.log("[Chat] Step 3: Context Retrieval");
    const { data: chunks, error: contextError } = await supabase.rpc('match_course_content', {
      p_course_id: toUuid(course_id),
      query_embedding: embedding,
      match_threshold: 0.2,
      match_count: 5,
      p_filter_id: toUuid(note_id)
    });

    if (contextError) {
      console.error("[Chat] Context Search Error:", contextError);
      throw new Error(`Database search failed: ${contextError.message}`);
    }

    // 4. Build context
    const contextText = (chunks || [])
      .map((c: any) => `Source: [${c.source_type}] ${c.source_title}\n${c.content}`)
      .join("\n\n---\n\n") || "No specific context found in the course materials.";

    // 5. Generate response with Gemini 3 Flash Preview (Latest Dec 2025)
    console.log("[Chat] Step 4: LLM Generation");
    const chatModel = genAI.getGenerativeModel({ 
      model: "models/gemini-3-flash-preview",
      generationConfig: { temperature: 0.7, topP: 0.95, topK: 40, maxOutputTokens: 2048 }
    });

    const systemPrompt = `You are MwanachuoCopilot, a professional AI study assistant for the Mwanachuo platform.
Your goal is to help students understand their course materials (notes and documents).

Context from Course Materials:
${contextText}

Conversation History:
${JSON.stringify(history || [])}

Question: ${userQuery}

Assistant:`;

    const result = await chatModel.generateContentStream(systemPrompt);

    // 6. Stream response
    console.log("[Chat] Step 5: Streaming start");
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
          console.error("[Stream Error]", e);
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
    console.error("[Chat 500 Detail]", {
      message: error.message,
      stack: error.stack,
      cause: error.cause
    });
    return new Response(
      JSON.stringify({ 
        error: error.message || String(error),
        details: error.stack
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

