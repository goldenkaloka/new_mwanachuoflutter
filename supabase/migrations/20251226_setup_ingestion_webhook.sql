-- Migration: Setup Ingestion Webhook
-- This trigger will automatically call the process-docs edge function 
-- whenever a new document record is inserted.

-- 1. Enable net extension if not already enabled
create extension if not exists "pg_net" with schema "extensions";

-- 2. Create the trigger function
create or replace function public.handle_document_ingestion()
returns trigger
language plpgsql
security definer
as $$
declare
  api_url text;
  service_role_key text;
begin
  -- Get configuration from vault or environment if needed, 
  -- but usually we can hardcode for local/project internal
  -- or use supabase project settings.
  
  -- NOTE: Replace the URL with your actual project URL if not using relative internal addressing
  -- For Edge Functions within the same project, we use the local net.http_post
  
  perform
    net.http_post(
      url := 'https://yhuujolmbqvntzifoaed.supabase.co/functions/v1/process-docs',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('request.jwt.claims', true)::jsonb->>'role' -- Or use service role if required
      ),
      body := jsonb_build_object(
        'record', row_to_json(new)
      ),
      timeout_milliseconds := 2000
    );

  return new;
end;
$$;

-- 3. Create the trigger
drop trigger if exists on_document_created on public.documents;
create trigger on_document_created
  after insert on public.documents
  for each row
  execute function public.handle_document_ingestion();

comment on function public.handle_document_ingestion() is 'Automatically triggers the process-docs Edge Function when a new document is added.';
