-- =====================================================
-- COMPLETE SETUP: Notification Trigger with Authentication
-- =====================================================
-- This is a complete setup script that:
-- 1. Ensures required extensions are enabled
-- 2. Creates a settings table to store the service role key
-- 3. Updates the trigger function with authentication
--
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_SERVICE_ROLE_KEY_HERE' with your actual service_role key
--    Get it from: Dashboard → Settings → API → service_role key
--    ⚠️ IMPORTANT: Remove any "Value: " prefix - just use the key itself!
-- 2. Copy and paste this entire SQL into Supabase Dashboard → SQL Editor
-- 3. Click "Run" to execute
-- =====================================================

-- STEP 1: Enable required extensions (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- STEP 2: Create a settings table to store the service role key
-- (This is a simple alternative to vault extension)
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Note: We don't enable RLS on this table because:
-- 1. It's only accessed by SECURITY DEFINER functions (which run as postgres role)
-- 2. The table is in the public schema and not exposed to client apps
-- 3. The service role key is already sensitive, but it's only used internally
-- If you want extra security, you can enable RLS and create appropriate policies

-- STEP 3: Store Service Role Key in settings table
-- ⚠️ IMPORTANT: Replace with your actual key (remove "Value: " prefix if present)
-- The key should start with "eyJ" (it's a JWT token)
INSERT INTO app_settings (key, value)
VALUES ('service_role_key', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlodXVqb2xtYnF2bnR6aWZvYWVkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjI4NzYzMywiZXhwIjoyMDc3ODYzNjMzfQ.lP5nu-NvKJXNT_jTeM6TipV7yxmCrUGUwF4J0kt-lDg')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();

-- STEP 4: Update the trigger function with authentication
CREATE OR REPLACE FUNCTION trigger_send_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payload JSONB;
  v_supabase_url TEXT := 'https://yhuujolmbqvntzifoaed.supabase.co';
  v_service_role_key TEXT;
  v_request_id BIGINT;
BEGIN
  -- Only send if this is a new notification (not an update)
  IF TG_OP = 'INSERT' THEN
    -- Get service role key from settings table
    SELECT value INTO v_service_role_key
    FROM app_settings
    WHERE key = 'service_role_key';
    
    -- Check if service role key was found
    IF v_service_role_key IS NULL OR v_service_role_key = '' THEN
      RAISE EXCEPTION 'Service role key not found in app_settings. Please store it first using: INSERT INTO app_settings (key, value) VALUES (''service_role_key'', ''YOUR_KEY'');';
    END IF;
    
    -- Build the payload
    v_payload := jsonb_build_object(
      'user_id', NEW.user_id,
      'title', NEW.title,
      'message', NEW.message,
      'type', NEW.type,
      'action_url', NEW.action_url,
      'metadata', COALESCE(NEW.metadata, '{}'::jsonb)
    );

    -- Call the Edge Function via pg_net with authentication
    SELECT net.http_post(
      url := v_supabase_url || '/functions/v1/send-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_service_role_key
      ),
      body := v_payload
    ) INTO v_request_id;
    
    RAISE NOTICE 'Notification trigger: user=%, request_id=%', NEW.user_id, v_request_id;
  END IF;

  RETURN NEW;
END;
$$;

-- STEP 4: Ensure trigger is attached (should already exist)
DROP TRIGGER IF EXISTS send_notification_trigger ON notifications;

CREATE TRIGGER send_notification_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION trigger_send_notification();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Setup complete! The trigger now includes authentication.';
  RAISE NOTICE '⚠️  Make sure you replaced YOUR_SERVICE_ROLE_KEY_HERE with your actual key!';
END $$;

