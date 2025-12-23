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

  try {
    const { document_id } = await req.json();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Get document metadata
    const { data: doc, error: docError } = await supabase
      .from('documents')
      .select('*')
      .eq('id', document_id)
      .single();

    if (docError) throw docError;

    // 2. Download file
    const { data: fileData, error: downloadError } = await supabase
      .storage
      .from('mwanachuomind_docs')
      .download(doc.file_path);

    if (downloadError) throw downloadError;

    // 3. Extract Text
    let text = '';
    const arrayBuffer = await fileData.arrayBuffer();
    const buffer = new Uint8Array(arrayBuffer);
    
    // Simple extension check or mime type check could be added
    // For now assuming PDF if it looks like one, or text
    try {
        const data = await pdf(Buffer.from(buffer));
        text = data.text;
    } catch (e) {
        // Fallback for plain text
        text = new TextDecoder().decode(buffer);
    }
    
    // 4. Split Text (Simple recursive-like splitting)
    const chunkSize = 1000;
    const overlap = 200;
    const chunks: string[] = [];
    
    for (let i = 0; i < text.length; i += (chunkSize - overlap)) {
        chunks.push(text.slice(i, i + chunkSize));
    }

    // 5. Embed & Upsert
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY') ?? '');
    const model = genAI.getGenerativeModel({ model: "text-embedding-004"});

    for (const chunk of chunks) {
        if (!chunk.trim()) continue;
        
        const result = await model.embedContent(chunk);
        const embedding = result.embedding.values;

        await supabase.from('document_chunks').insert({
            document_id: document_id,
            content: chunk,
            embedding: embedding,
        });
    }

    return new Response(JSON.stringify({ success: true, chunks: chunks.length }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
