import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// @ts-ignore
const wait = (promise: Promise<any>) => EdgeRuntime.waitUntil(promise);

async function processNote(noteId: string, filePath: string, bucketId: string, supabase: any, genAI: any) {
    try {
        console.log(`[BG] Start: ${noteId}`);
        await supabase.from('course_notes').update({ description: 'Processing: Downloading file...' }).eq('id', noteId);
        
        const { data: fileData, error: downloadError } = await supabase.storage.from(bucketId).download(filePath);
        if (downloadError) throw downloadError;

        await supabase.from('course_notes').update({ description: 'Processing: AI Analysis...' }).eq('id', noteId);
        const arrayBuffer = await fileData.arrayBuffer();
        const uint8Array = new Uint8Array(arrayBuffer);
        let binary = '';
        const len = uint8Array.byteLength;
        for (let i = 0; i < len; i += 8192) {
            binary += String.fromCharCode.apply(null, uint8Array.subarray(i, i + 8192));
        }
        const base64Data = btoa(binary);
        
        // Use models/gemini-3-flash-preview (full path often required by SDK)
        const model = genAI.getGenerativeModel({ model: "models/gemini-3-flash-preview" });

        const prompt = `Analyze this document. Return JSON: {concepts:[], flashcards:[], tags:[], summary:""}`;
        const result = await model.generateContent([
          prompt,
          { inlineData: { data: base64Data, mimeType: "application/pdf" } },
        ]);

        const analysis = JSON.parse(result.response.text().replace(/```json/g, '').replace(/```/g, '').trim());

        await supabase.from('course_notes').update({
            study_readiness_score: 100,
            description: 'Processing: Saving metadata...'
        }).eq('id', noteId);

        // ... Batched inserts for concepts, flashcards, tags ...
        if (analysis.concepts?.length > 0) await supabase.from('note_concepts').insert(analysis.concepts.map((c: any) => ({ note_id: noteId, concept_text: c.term, context: c.definition, page_number: c.page || 1, concept_type: 'key_term' })));
        if (analysis.flashcards?.length > 0) await supabase.from('note_flashcards').insert(analysis.flashcards.map((f: any) => ({ note_id: noteId, question: f.question, answer: f.answer, difficulty: f.difficulty || 'medium' })));
        
        await supabase.from('course_notes').update({ description: 'Processing: RAG Indexing...' }).eq('id', noteId);

        const extractionResult = await model.generateContent([
           "Extract plain text.",
           { inlineData: { data: base64Data, mimeType: "application/pdf" } },
        ]);
        const fullText = extractionResult.response.text();
        const chunks = fullText.match(/[\s\S]{1,1000}/g) || [];
        const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004" });

        for (let i = 0; i < chunks.length; i++) {
            const embedResult = await embeddingModel.embedContent(chunks[i]);
            await supabase.from('note_chunks').insert({
                note_id: noteId,
                content: chunks[i],
                chunk_index: i,
                embedding: embedResult.embedding.values
            });
        }
        await supabase.from('course_notes').update({ description: analysis.summary }).eq('id', noteId);
        console.log(`[BG] Done: ${noteId}`);
    } catch (error) {
        console.error(`[BG] Error: ${noteId}`, error);
        await supabase.from('course_notes').update({ description: `Error: ${error.message}` }).eq('id', noteId);
    }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;
    
    if (!geminiKey) throw new Error("Missing GEMINI_API_KEY");

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);

    const payload = await req.json();
    let noteId = payload.note_id || payload.record?.metadata?.course_note_id;
    let filePath = payload.record?.name;
    let bucketId = payload.bucketId || payload.record?.bucket_id || 'course_notes';

    if (!noteId && filePath) {
      const parts = filePath.split('/');
      noteId = parts.length >= 3 ? parts[2].split('.')[0] : null;
    }

    if (!noteId) return new Response(JSON.stringify({ error: 'Missing note_id' }), { status: 400 });

    const { data: note } = await supabase.from('course_notes').select('file_url').eq('id', noteId).single();
    if (!note) return new Response(JSON.stringify({ error: 'Note not found' }), { status: 404 });

    if (!filePath && note.file_url) {
        const urlParts = note.file_url.split('/course_notes/');
        filePath = urlParts.length > 1 ? decodeURIComponent(urlParts[1].split('?')[0]) : note.file_url.split('/').pop();
    }

    // Trigger background process
    wait(processNote(noteId, filePath, bucketId, supabase, genAI));

    return new Response(JSON.stringify({ success: true, message: "Processing started" }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
```
