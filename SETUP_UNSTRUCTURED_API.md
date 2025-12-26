# Unstructured.io API Setup Guide

## Step 1: Get Your Free API Key

1. Go to [https://unstructured.io/api-key-hosted](https://unstructured.io/api-key-hosted)
2. Sign up for a free account
3. You get **15,000 free pages** with no expiration
4. Copy your API key

## Step 2: Add API Key to Supabase

### Option A: Via Supabase Dashboard
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard/project/yhuujolmbqvntzifoaed/settings/functions)
2. Navigate to: **Project Settings** → **Edge Functions** → **Secrets**
3. Click **Add new secret**
4. Name: `UNSTRUCTURED_API_KEY`
5. Value: (paste your API key)
6. Click **Save**

### Option B: Via Supabase CLI
```bash
supabase secrets set UNSTRUCTURED_API_KEY=your_api_key_here --project-ref yhuujolmbqvntzifoaed
```

## Step 3: Test the Integration

Run this PowerShell command to test:

```powershell
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlodXVqb2xtYnF2bnR6aWZvYWVkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjI4NzYzMywiZXhwIjoyMDc3ODYzNjMzfQ.lP5nu-NvKJXNT_jTeM6TipV7yxmCrUGUwF4J0kt-lDg"
}
$body = @{ document_id = "f26b78e1-7882-4c86-a642-d45371309f14" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://yhuujolmbqvntzifoaed.supabase.co/functions/v1/process-docs-v2" -Method Post -Headers $headers -Body $body -TimeoutSec 300
```

## What Happens Next

Once configured, the system will:
1. Download your PDF from Supabase Storage
2. Send it to Unstructured.io for professional text extraction
3. Split the extracted text into chunks using LangChain-compatible algorithm
4. Generate embeddings using Gemini
5. Store everything in `document_chunks` table
6. Your AI chat will have full context!

## Supported File Types

| Format | Extraction Method |
|--------|-------------------|
| PDF | Unstructured.io API |
| PPTX/PPT | Unstructured.io API |
| DOCX/DOC | Unstructured.io API |
| XLSX/XLS | Unstructured.io API |
| TXT | Direct TextDecoder |
| MD | Direct TextDecoder |
| CSV | Direct TextDecoder |
| JSON | Direct TextDecoder |

## Pricing

- **Free Tier**: 15,000 pages (no expiration)
- **Pay-as-you-go**: $1 per 1,000 pages (Fast) or $10 per 1,000 pages (Hi-Res)

For your "land law 1" PDF, you'll use approximately 1 page credit per PDF page.
