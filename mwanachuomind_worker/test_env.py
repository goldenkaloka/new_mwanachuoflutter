import os
import dotenv
from supabase import create_client, Client
import google.generativeai as genai

dotenv.load_dotenv()

url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
gemini_key = os.environ.get('GEMINI_API_KEY')

print(f"URL: {url}")
print(f"Key Check: {bool(key)}")
print(f"Gemini Key Check: {bool(gemini_key)}")

try:
    genai.configure(api_key=gemini_key)
    model = genai.GenerativeModel('gemini-1.5-flash')
    response = model.generate_content("Hello")
    print(f"Gemini Response: {response.text}")
    
    embed = genai.embed_content(model="models/text-embedding-004", content="Hello")
    print(f"Embedding Dim: {len(embed['embedding'])}")
    
    supabase: Client = create_client(url, key)
    res = supabase.table('documents').select('id').limit(1).execute()
    print(f"Supabase Connection: Success ({len(res.data)} docs)")
except Exception as e:
    print(f"Error: {e}")
