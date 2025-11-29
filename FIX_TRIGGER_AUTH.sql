-- =====================================================
-- FIX: Update Notification Trigger with Authentication
-- =====================================================
-- This SQL updates the database trigger to include the service role key
-- in the Authorization header when calling the Edge Function.
--
-- INSTRUCTIONS:
-- 1. First, make sure your service_role key is stored in Vault (see Step 2 below)
-- 2. Copy and paste this entire SQL into Supabase Dashboard → SQL Editor
-- 3. Click "Run" to execute
-- =====================================================

-- STEP 1: Store Service Role Key in Vault (if not already stored)
-- Replace 'YOUR_SERVICE_ROLE_KEY_HERE' with your actual service_role key
-- Get it from: Dashboard → Settings → API → service_role key
-- 
-- IMPORTANT: Replace the placeholder with your actual key before running!
INSERT INTO vault.secrets (name, secret)
VALUES ('service_role_key', 'YOUR_SERVICE_ROLE_KEY_HERE')
ON CONFLICT (name) DO UPDATE SET secret = EXCLUDED.secret;

-- STEP 2: Update the trigger function to include authentication
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
    -- Get service role key from Vault
    SELECT decrypted_secret INTO v_service_role_key
    FROM vault.decrypted_secrets
    WHERE name = 'service_role_key';
    
    -- Check if service role key was found
    IF v_service_role_key IS NULL OR v_service_role_key = '' THEN
      RAISE EXCEPTION 'Service role key not found in Vault. Please store it first.';
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

-- Verify the trigger is still attached
-- (This should already exist, but we're just checking)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'send_notification_trigger'
  ) THEN
    CREATE TRIGGER send_notification_trigger
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_notification();
  END IF;
END $$;

-- =====================================================
-- VERIFICATION QUERIES (Optional - run these to verify)
-- =====================================================

-- Check if service role key is stored in Vault
-- SELECT name FROM vault.secrets WHERE name = 'service_role_key';

-- Check the trigger function exists
-- SELECT proname, prosrc FROM pg_proc WHERE proname = 'trigger_send_notification';

-- Check the trigger is attached to notifications table
-- SELECT tgname, tgrelid::regclass FROM pg_trigger WHERE tgname = 'send_notification_trigger';


