import json
import urllib.request
import urllib.error
import time

DOCS_TO_PROCESS = [
    {"id":"b561090d-2d51-4214-a4e0-c75fe6c25267","file_path":"5b12f195-a738-4f37-8e34-d5847407717f/1766653453363.pdf"},
    {"id":"3e1084a8-1da8-48a0-beff-29a42da62349","file_path":"5b12f195-a738-4f37-8e34-d5847407717f/1766673737556.pptx"},
    {"id":"88a869d5-4246-4818-8981-4232201c34ac","file_path":"test/path.pdf"},
    {"id":"0125f451-4f30-46cd-823b-31ef904b9a11","file_path":"test/path2.pdf"},
    {"id":"cdf08904-ec11-4a3d-81b1-44fed1909375","file_path":"test/path3.pdf"},
    {"id":"54671f5e-e295-4ee5-8d74-57af7b1027c8","file_path":"test/path_final.pdf"}
]

URL = "http://127.0.0.1:8000/process/"

print(f"Starting batch processing of {len(DOCS_TO_PROCESS)} documents...")

for doc in DOCS_TO_PROCESS:
    print(f"\nProcessing {doc['id']} ({doc['file_path']})...")
    
    payload = {
        "record": {
            "id": doc['id'],
            "file_path": doc['file_path']
        }
    }
    
    try:
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(URL, data=data, headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=600) as response:
            resp_body = response.read().decode('utf-8')
            print(f"SUCCESS: {response.status} - {resp_body}")
    except urllib.error.HTTPError as e:
        print(f"FAILED: {e.code} - {e.reason}")
        print(e.read().decode('utf-8'))
    except Exception as e:
        print(f"ERROR: {str(e)}")
    
    time.sleep(1) # Be nice to the server

print("\nBatch processing complete.")
