import os
import dotenv
import google.generativeai as genai

dotenv.load_dotenv()
gemini_key = os.environ.get('GEMINI_API_KEY')
genai.configure(api_key=gemini_key)

print("Models supporting 'embedContent':")
try:
    for m in genai.list_models():
        if 'embedContent' in m.supported_generation_methods:
            print(f"- {m.name}")
    
    print("\nModels supporting 'generateContent':")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"- {m.name}")
except Exception as e:
    print(f"Error: {e}")
