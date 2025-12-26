import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai";
import { RecursiveCharacterTextSplitter } from "npm:langchain/text_splitter";
import { Buffer } from "node:buffer";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// @ts-ignore
const wait = (promise: Promise<any>) => EdgeRuntime.waitUntil(promise);

async function extractWithGemini(fileBlob: Blob, filename: string, genAI: any): Promise<string> {
  console.log(`[EXTRACT] OCR Start: ${filename}`);
  // gemini-flash-latest proven to work with available quota
  const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });
  const arrayBuffer = await fileBlob.arrayBuffer();
  const base64Data = Buffer.from(arrayBuffer).toString('base64');

  const result = await model.generateContent([
    { inlineData: { data: base64Data, mimeType: "application/pdf" } },
    "Extract all text from this study material. Perform high-quality OCR. Output only the transcribed text content.",
  ]);

  const text = result.response.text();
  console.log(`[EXTRACT] Success: ${text.length} chars`);
  return text;
}

async function processDocument(documentId: string, supabase: any, genAI: any) {
  try {
    console.log(`[BG] Start: ${documentId}`);
    const { data: doc } = await supabase.from('documents').select('*').eq('id', documentId).single();
    if (!doc) throw new Error("Doc not found");

    const { data: file } = await supabase.storage.from('mwanachuomind_docs').download(doc.file_path);
    if (!file) throw new Error("Download failed");

    const text = await extractWithGemini(file, doc.file_path, genAI);
    await supabase.from('documents').update({ extracted_text: text, updated_at: new Date().toISOString() }).eq('id', documentId);

    // Using LangChain for better context-aware splitting
    const splitter = new RecursiveCharacterTextSplitter({ chunkSize: 1000, chunkOverlap: 200 });
    const output = await splitter.createDocuments([text]);

    await supabase.from('document_chunks').delete().eq('document_id', documentId);

    const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004"});
    for (let i = 0; i < output.length; i += 10) {
      const batch = output.slice(i, i + 10);
      const records = await Promise.all(batch.map(async (chunk) => {
        const r = await embeddingModel.embedContent(chunk.pageContent);
        return { document_id: documentId, content: chunk.pageContent, embedding: r.embedding.values };
      }));
      await supabase.from('document_chunks').insert(records);
    }

    await supabase.from('document_processing_queue')
      .update({ status: 'completed', updated_at: new Date().toISOString(), error_message: null })
      .eq('document_id', documentId);
    console.log(`[BG] ✅ SUCCESS: ${documentId}`);
  } catch (err) {
    console.error(`[BG] ❌ ERROR:`, err.message);
    await supabase.from('document_processing_queue')
      .update({ status: 'failed', error_message: err.message, updated_at: new Date().toISOString() })
      .eq('document_id', documentId);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  
  try {
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);

    const body = await req.json().catch(() => ({}));
    const documentId = body.document_id || body.id || body.record?.id;

    if (documentId) {
      console.log(`[HTTP] Triggering background for: ${documentId}`);
      // Clear error_message and set status to processing
      await supabase.from('document_processing_queue')
        .update({ status: 'processing', updated_at: new Date().toISOString(), error_message: null })
        .eq('document_id', documentId);
        
      wait(processDocument(documentId, supabase, genAI));
      return new Response(JSON.stringify({ success: true, message: "Processing started in background" }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
    return new Response(JSON.stringify({ error: "Missing ID" }), { status: 400 });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
