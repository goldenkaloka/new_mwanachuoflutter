import os
import dotenv
import google.generativeai as genai
from supabase import create_client, Client

dotenv.load_dotenv()
gemini_key = os.environ.get('GEMINI_API_KEY')
url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

genai.configure(api_key=gemini_key)

print("Starting verification...")
try:
    print("Testing Embedding (text-embedding-004)...")
    embed = genai.embed_content(model="models/text-embedding-004", content="Hello world")
    print(f"Embedding Success! Dim: {len(embed['embedding'])}")
    
    print("Testing Generation (models/gemini-flash-latest)...")
    model = genai.GenerativeModel('models/gemini-flash-latest')
    response = model.generate_content("Say 'System OK'")
    print(f"Generation Success: {response.text}")
    
    print("Testing Supabase...")
    supabase: Client = create_client(url, key)
    res = supabase.table('documents').select('id').limit(1).execute()
    print(f"Supabase Success: {len(res.data)} docs found.")
    
except Exception as e:
    print(f"FAILED: {e}")
