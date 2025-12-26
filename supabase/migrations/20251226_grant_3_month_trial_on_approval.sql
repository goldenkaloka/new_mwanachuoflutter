-- =====================================================
-- GRANT 3-MONTH FREE TRIAL ON SELLER APPROVAL
-- =====================================================
-- This migration modifies the approve_seller_request function to automatically
-- create a 3-month free trial subscription when a seller is approved
-- =====================================================

-- First, let's create or replace the approve_seller_request function
CREATE OR REPLACE FUNCTION approve_seller_request(
  request_id UUID,
  admin_id UUID,
  notes TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_plan_id UUID;
BEGIN
  -- Get the user_id from the seller request
  SELECT user_id INTO v_user_id
  FROM seller_requests
  WHERE id = request_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Seller request not found';
  END IF;

  -- Update the seller request status
  UPDATE seller_requests
  SET 
    status = 'approved',
    reviewed_by = admin_id,
    reviewed_at = NOW(),
    review_notes = notes,
    updated_at = NOW()
  WHERE id = request_id;

  -- Update user role to seller
  UPDATE users
  SET 
    role = 'seller',
    updated_at = NOW()
  WHERE id = v_user_id;

  -- Get the first active subscription plan (or use a default plan ID)
  -- If your subscription_plans table doesn't exist yet or has no plans,
  -- this will be NULL and we'll handle it gracefully
  SELECT id INTO v_plan_id
  FROM subscription_plans
  WHERE is_active = true
  ORDER BY created_at
  LIMIT 1;

  -- Create a 3-month free trial subscription
  -- We'll make plan_id nullable in case no plans exist yet
  INSERT INTO seller_subscriptions (
    seller_id,
    plan_id,
    status,
    is_trial,
    billing_period,
    current_period_start,
    current_period_end,
    grace_period_end,
    auto_renew
  ) VALUES (
    v_user_id,
    v_plan_id,  -- Can be NULL if no plans exist
    'active',
    true,  -- This is a trial
    'monthly',
    NOW(),
    NOW() + INTERVAL '3 months',  -- Trial expires in 3 months
    NOW() + INTERVAL '3 months' + INTERVAL '7 days',  -- 7 day grace period after trial
    false  -- Don't auto-renew (no payment method on file)
  )
  ON CONFLICT (seller_id) 
  DO UPDATE SET
    status = 'active',
    is_trial = true,
    current_period_start = NOW(),
    current_period_end = NOW() + INTERVAL '3 months',
    grace_period_end = NOW() + INTERVAL '3 months' + INTERVAL '7 days',
    updated_at = NOW();

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION approve_seller_request(UUID, UUID, TEXT) TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON FUNCTION approve_seller_request IS 'Approves a seller request and grants a 3-month free trial subscription';
