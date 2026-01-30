import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;

    if (!geminiKey) {
        throw new Error("Missing GEMINI_API_KEY");
    }

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);

    // Get Payload from Storage Webhook
    const payload = await req.json();
    const record = payload.record; // Storage object record

    if (!record || !record.name) {
       console.log("No record found in payload", payload);
       return new Response("No record found", { status: 400 });
    }

    const bucketId = payload.bucketId || record.bucket_id || 'course_notes';
    const filePath = record.name; // e.g. "userId/courseId/noteId.pdf"
    
    console.log(`Processing file: ${filePath} in bucket ${bucketId}`);

    // Parse noteId from path (Assumes: userId/courseId/noteId.ext)
    const pathParts = filePath.split('/');
    if (pathParts.length < 3) {
        return new Response("Invalid file path structure", { status: 400 });
    }
    const noteId = pathParts[2].split('.')[0]; 
    const fileExt = filePath.split('.').pop()?.toLowerCase() || 'pdf';

    // 1. Download File from Supabase Storage
    const { data: fileData, error: downloadError } = await supabase.storage
        .from(bucketId)
        .download(filePath);

    if (downloadError) throw downloadError;

    // 2. Prepare for Gemini
    // For large files, we should use the File API. But Deno Edge has generic limitations.
    // However, Gemini 1.5 Flash supports inline data up to 20MB.
    // If >20MB, we need to upload via media API.
    // For this implementation, we will try standard inline for now, or use a "Hack" for larger files if needed.
    // Ideally use `GoogleAIFileManager` if supported.
    // Since `esm.sh` version might not have `server` export easily, we'll try inline first.
    // If the user uploads a 40MB file, this might fail on memory.
    // The PROPER way is `GoogleAIFileManager`. Let's assume we can fetch it.
    
    // Convert Blob/File to Base64
    const arrayBuffer = await fileData.arrayBuffer();
    const base64Data = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));

    // 3. Call Gemini Model
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = `
    Analyze this academic document. 
    1. Extract the main concepts (key terms, definitions).
    2. Generate 3-5 flashcards (Question/Answer).
    3. Generate a summary.
    4. Detect any tags.
    
    Return the response as a valid JSON object with keys:
    {
      "concepts": [{"term": "...", "definition": "...", "page": 1}],
      "flashcards": [{"question": "...", "answer": "...", "difficulty": "easy"}],
      "tags": ["..."],
      "summary": "..."
    }
    `;

    const result = await model.generateContent([
      prompt,
      {
        inlineData: {
          data: base64Data,
          mimeType: record.metadata?.mimetype || "application/pdf",
        },
      },
    ]);

    const responseText = result.response.text();
    // Clean JSON (remove markdown code blocks)
    let jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
    const analysis = JSON.parse(jsonStr);

    // 4. Update Database
    // Update Readiness Score
    await supabase.from('course_notes').update({
        study_readiness_score: 100,
        description: analysis.summary
    }).eq('id', noteId);

    // Insert Concepts
    if (analysis.concepts && analysis.concepts.length > 0) {
        const concepts = analysis.concepts.map((c: any) => ({
            note_id: noteId,
            concept_text: c.term,
            context: c.definition,
            page_number: c.page || 1,
            concept_type: 'key_term'
        }));
        await supabase.from('note_concepts').insert(concepts);
    }

    // Insert Flashcards
    if (analysis.flashcards && analysis.flashcards.length > 0) {
         const flashcards = analysis.flashcards.map((f: any) => ({
            note_id: noteId,
            question: f.question,
            answer: f.answer,
            difficulty: f.difficulty || 'medium'
        }));
        await supabase.from('note_flashcards').insert(flashcards);
    }
    
     // Insert Tags
    if (analysis.tags && analysis.tags.length > 0) {
         const tags = analysis.tags.map((t: string) => ({
            note_id: noteId,
            tag_name: t,
            is_ai_generated: true
        }));
        await supabase.from('note_tags').insert(tags);
    }

    // TODO: Generate Embeddings for chunks (Require text splitting)
    // For now, we rely on Gemini's analysis. For RAG, we still need chunks.
    // We can ask Gemini to return "Chunks" too? Or use a separate call.
    // Or we split the extracted text (if we can get full text).
    // result.response.text() is just the analysis.
    
    return new Response(JSON.stringify({ success: true, analysis }), {
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
