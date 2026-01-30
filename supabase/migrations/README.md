# Supabase Migrations

This directory contains database migrations for the MwanachuoCopilot feature.

## Running Migrations

### Option 1: Supabase Dashboard (Recommended for now)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `20260128_create_copilot_tables.sql`
4. Paste and run the SQL

### Option 2: Supabase CLI (Future)

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

## What This Migration Does

### Tables Created:
1. **course_notes** - Main notes table
2. **note_concepts** - AI-extracted concepts  
3. **note_tags** - Note categorization
4. **note_flashcards** - AI-generated flashcards
5. **user_note_downloads** - Offline download tracking
6. **note_chunks** - Text chunks with pgvector embeddings for RAG

### Extensions Enabled:
- `uuid-ossp` - UUID generation
- `pgvector` - Vector similarity search

### Security:
- Row Level Security (RLS) enabled on all tables
- Policies for public read, authenticated write
- Service-role only for AI-generated content

### Helper Functions:
- `increment_download_count()` - Track downloads
- `increment_view_count()` - Track views
- `update_updated_at_column()` - Auto-update timestamps

## Verification

After running, verify with:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%note%';

-- Check pgvector extension
SELECT * FROM pg_extension WHERE extname = 'vector';
```
