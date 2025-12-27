import os
import dotenv
import google.generativeai as genai

dotenv.load_dotenv()
gemini_key = os.environ.get('GEMINI_API_KEY')
genai.configure(api_key=gemini_key)

print(f"Listing models for key: {gemini_key[:10]}...")
try:
    for m in genai.list_models():
        print(f"Model: {m.name}, Methods: {m.supported_generation_methods}")
except Exception as e:
    print(f"Error listing models: {e}")
