import os
import json
import tempfile
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from supabase import create_client, Client
from llama_index.readers.docling import DoclingReader
import google.generativeai as genai

@method_decorator(csrf_exempt, name='dispatch')
class ProcessDocumentView(APIView):
    def post(self, request):
        try:
            # 1. Parse payload from Supabase Webhook
            payload = request.data
            print(f"[WORKER] Received payload: {payload}")
            record = payload.get('record', {})
            document_id = record.get('id')
            file_path = record.get('file_path')
            
            if not document_id or not file_path:
                print("[WORKER] Missing document_id or file_path")
                return Response({"error": "Missing document_id or file_path"}, status=status.HTTP_400_BAD_REQUEST)

            # 2. Setup Clients
            url = os.environ.get('SUPABASE_URL')
            key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
            gemini_key = os.environ.get('GEMINI_API_KEY')
            
            if not all([url, key, gemini_key]):
                print(f"[WORKER] Missing env vars: url={bool(url)}, key={bool(key)}, gemini={bool(gemini_key)}")
                return Response({"error": "Missing environment variables"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                
            print(f"[WORKER] Creating clients...")
            supabase: Client = create_client(url, key)
            genai.configure(api_key=gemini_key)

            # 3. Download file from Storage
            try:
                print(f"[WORKER] Downloading {file_path}...")
                res = supabase.storage.from_('mwanachuomind_docs').download(file_path)
            except Exception as e:
                err_str = str(e)
                if "Object not found" in err_str or "404" in err_str:
                    print(f"[WORKER] File not found in storage: {file_path}")
                    return Response({"error": f"File not found: {file_path}"}, status=status.HTTP_404_NOT_FOUND)
                print(f"[WORKER] Storage error: {err_str}")
                raise e

            with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file_path)[1]) as temp_file:
                temp_file.write(res)
                temp_path = temp_file.name

            try:
                # 4. Parse with IBM Docling via LlamaIndex
                reader = DoclingReader()
                docs = reader.load_data(file_path=temp_path)
                
                # Combine all docs into one markdown string (Docling preserves tables in MD)
                full_markdown = "\n\n".join([doc.text for doc in docs])
                
                # Update document with extracted text
                supabase.table('documents').update({
                    "extracted_text": full_markdown,
                    "updated_at": "now()"
                }).eq('id', document_id).execute()

                # 5. Chunking & Embeddings
                chunks = self.chunk_text(full_markdown, chunk_size=1000, overlap=200)
                
                # Delete existing chunks
                supabase.table('document_chunks').delete().eq('document_id', document_id).execute()
                
                # Generate embeddings and save
                embedding_model = "models/text-embedding-004"
                
                records = []
                for chunk in chunks:
                    result = genai.embed_content(
                        model=embedding_model,
                        content=chunk,
                        task_type="retrieval_document"
                    )
                    embedding = result['embedding']
                    
                    records.append({
                        "document_id": document_id,
                        "content": chunk,
                        "embedding": embedding,
                        "metadata": {"source": file_path}
                    })
                
                if records:
                    print(f"[WORKER] Inserting {len(records)} chunks...")
                    supabase.table('document_chunks').insert(records).execute()

                print(f"[WORKER] Success: {document_id}")
                return Response({"status": "success", "chunks_created": len(chunks)}, status=status.HTTP_200_OK)

            finally:
                if os.path.exists(temp_path):
                    os.remove(temp_path)

        except Exception as e:
            print(f"Error processing document: {str(e)}")
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def chunk_text(self, text, chunk_size=1000, overlap=200):
        chunks = []
        if not text:
            return chunks
        start = 0
        while start < len(text):
            end = start + chunk_size
            chunks.append(text[start:end])
            start += chunk_size - overlap
        return chunks
