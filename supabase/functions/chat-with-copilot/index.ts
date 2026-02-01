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
    console.log(`[DEBUG] Using GEMINI_API_KEY starting with: ${geminiKey?.substring(0, 6)}...`);

    if (!geminiKey) throw new Error("Missing GEMINI_API_KEY");

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);
    
    // Get Request Body
    const { message, note_id, course_id, history } = await req.json();

    if (!message || (!note_id && !course_id)) {
        return new Response(JSON.stringify({ error: "Missing message or (note_id/course_id)" }), { status: 400, headers: corsHeaders });
    }

    // 1. Generate Embedding for the User's Question
    const embeddingModel = genAI.getGenerativeModel({ model: "models/text-embedding-004" });
    const embeddingResult = await embeddingModel.embedContent(message);
    const embedding = embeddingResult.embedding.values;

    // 2. Identify Scope (Specific Note vs Course Wide)
    let validNoteIds: Set<string> | null = null;
    let rpcFilter = {};

    if (note_id) {
        console.log(`[RAG] Scoped to single note: ${note_id}`);
        rpcFilter = { note_id: note_id };
    } else if (course_id) {
        console.log(`[RAG] Scoped to course: ${course_id}`);
        // Fetch all note IDs for this course to filter results later
        const { data: notes } = await supabase.from('course_notes').select('id').eq('course_id', course_id);
        if (notes) {
            validNoteIds = new Set(notes.map((n: any) => n.id));
        }
        // We pass empty filter to RPC to search all, then filter in code (inefficient but works without SQL changes)
        // Ideally: Update match_note_chunks to accept list of note_ids
        rpcFilter = {}; 
    }

    // 3. Search for Relevant Chunks (RAG)
    // Request more chunks if course-wide to increase chance of hitting relevant course content
    const matchCount = course_id && !note_id ? 20 : 5; 

    const { data: chunks, error: searchError } = await supabase.rpc('match_note_chunks', {
        query_embedding: embedding,
        match_threshold: 0.1,
        match_count: matchCount,
        filter: rpcFilter 
    });

    if (searchError) {
        console.error("Search Error:", searchError);
        throw searchError;
    }
    
    // 4. Filter Chunks (if course-wide)
    let finalChunks = chunks || [];
    if (validNoteIds) {
        finalChunks = finalChunks.filter((c: any) => validNoteIds!.has(c.note_id));
        // Trim back to top 5 after filtering
        finalChunks = finalChunks.slice(0, 5);
    }

    console.log(`[RAG] Found ${finalChunks.length} relevant chunks`);

    // 5. Construct Context
    const contextText = finalChunks.map((c: any) => c.content).join("\n\n") || "";
    
    // 6. Generate Answer with Gemini
    const chatModel = genAI.getGenerativeModel({ model: "models/gemini-3-flash-preview" });
    
    const prompt = `
    You are an AI study assistant "MwanachuoCopilot". 
    Answer the user's question based ONLY on the following context derived from their course notes.
    If the answer is not in the context, say "I couldn't find the answer in that context."
    
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
