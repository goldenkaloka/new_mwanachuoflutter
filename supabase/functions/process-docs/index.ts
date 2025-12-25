import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai";
import { Buffer } from "node:buffer";
// @ts-ignore
import pdf from "npm:pdf-parse";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  console.log("Processing document request received...");

  try {
    const body = await req.json();
    const { document_id } = body;
    
    if (!document_id) throw new Error("document_id is required");

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') ?? '');

    // 1. Get document metadata
    console.log(`Fetching metadata for document: ${document_id}`);
    const { data: doc, error: docError } = await supabase
      .from('documents')
      .select('*')
      .eq('id', document_id)
      .single();

    if (docError) throw docError;
    if (!doc) throw new Error("Document not found");

    // 2. Download file
    console.log(`Downloading file from storage: ${doc.file_path}`);
    const { data: fileData, error: downloadError } = await supabase
      .storage
      .from('mwanachuomind_docs')
      .download(doc.file_path);

    if (downloadError) throw downloadError;

    // 3. Extract Text
    console.log("Extracting text from document...");
    let text = '';
    const arrayBuffer = await fileData.arrayBuffer();
    const buffer = new Uint8Array(arrayBuffer);
    
    try {
        const data = await pdf(Buffer.from(buffer));
        text = data.text;
        console.log(`Extracted ${text.length} characters using pdf-parse`);
    } catch (e) {
        console.warn("pdf-parse failed, falling back to text decoding", e);
        text = new TextDecoder().decode(buffer);
    }
    
    if (!text || text.trim().length === 0) {
        throw new Error("No text could be extracted from the document");
    }

    // 4. Split Text (Simple recursive-like splitting)
    const chunkSize = 1000;
    const overlap = 200;
    const chunks: string[] = [];
    
    for (let i = 0; i < text.length; i += (chunkSize - overlap)) {
        const chunk = text.slice(i, i + chunkSize).trim();
        if (chunk.length > 50) { 
            chunks.push(chunk);
        }
    }

    console.log(`Split text into ${chunks.length} chunks`);

    // 5. Embed & Bulk Insert
    const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004"});
    const batchSize = 10; 
    const allChunksToInsert = [];

    for (let i = 0; i < chunks.length; i += batchSize) {
        const batch = chunks.slice(i, i + batchSize);
        console.log(`Processing embedding batch ${Math.floor(i / batchSize) + 1} of ${Math.ceil(chunks.length / batchSize)}`);
        
        await Promise.all(batch.map(async (chunk) => {
            try {
                const result = await embeddingModel.embedContent(chunk);
                const embedding = result.embedding.values;
                allChunksToInsert.push({
                    document_id: document_id,
                    content: chunk,
                    embedding: embedding,
                });
            } catch (embedError) {
                console.error(`Failed to embed chunk starting with: ${chunk.slice(0, 50)}`, embedError);
            }
        }));
    }

    if (allChunksToInsert.length > 0) {
        console.log(`Inserting ${allChunksToInsert.length} chunks into database...`);
        // Use multiple smaller inserts if total is very large to avoid payload limits
        const dbBatchSize = 50;
        for (let i = 0; i < allChunksToInsert.length; i += dbBatchSize) {
            const dbBatch = allChunksToInsert.slice(i, i + dbBatchSize);
            const { error: insertError } = await supabase
                .from('document_chunks')
                .insert(dbBatch);
            
            if (insertError) throw insertError;
        }
    }

    console.log("Document processing completed successfully");

    return new Response(JSON.stringify({ 
        success: true, 
        chunks: allChunksToInsert.length 
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error("Critical error in process-docs:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
