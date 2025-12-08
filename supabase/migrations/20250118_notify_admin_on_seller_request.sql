-- =====================================================
-- NOTIFY ADMINS ON SELLER REQUEST
-- =====================================================
-- This trigger notifies all admin users when a new seller request is created
-- =====================================================

-- Create function to notify admins when a seller request is created
CREATE OR REPLACE FUNCTION notify_admins_on_seller_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  admin_user RECORD;
  requester_name TEXT;
  requester_email TEXT;
BEGIN
  -- Only process new seller requests (not updates)
  IF TG_OP = 'INSERT' AND NEW.status = 'pending' THEN
    -- Get requester information
    SELECT full_name, email INTO requester_name, requester_email
    FROM users
    WHERE id = NEW.user_id;
    
    -- Loop through all admin users and create notifications
    FOR admin_user IN 
      SELECT id, full_name, email
      FROM users
      WHERE role = 'admin'
    LOOP
      -- Insert notification for each admin
      INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        action_url,
        metadata
      ) VALUES (
        admin_user.id,
        'seller_request',
        'New Seller Request',
        COALESCE(requester_name, 'A user') || ' has requested to become a seller.',
        '/admin/seller-requests',
        jsonb_build_object(
          'seller_request_id', NEW.id,
          'requester_id', NEW.user_id,
          'requester_name', requester_name,
          'requester_email', requester_email,
          'reason', NEW.reason
        )
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS notify_admins_seller_request_trigger ON seller_requests;

-- Create trigger
CREATE TRIGGER notify_admins_seller_request_trigger
AFTER INSERT ON seller_requests
FOR EACH ROW
EXECUTE FUNCTION notify_admins_on_seller_request();

-- =====================================================
-- VERIFICATION
-- =====================================================
-- To verify this works, you can:
-- 1. Check if the function exists:
--    SELECT proname FROM pg_proc WHERE proname = 'notify_admins_on_seller_request';
-- 
-- 2. Check if the trigger exists:
--    SELECT tgname FROM pg_trigger WHERE tgname = 'notify_admins_seller_request_trigger';
--
-- 3. Test by creating a seller request and checking notifications table:
--    INSERT INTO seller_requests (user_id, reason, status) 
--    VALUES ('<user_id>', 'Test request', 'pending');
--    
--    SELECT * FROM notifications WHERE type = 'seller_request' ORDER BY created_at DESC;

