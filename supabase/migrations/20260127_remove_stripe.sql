-- Remove Stripe related columns and cleanup
-- Date: 2026-01-27

-- 1. Remove Stripe columns from seller_subscriptions
ALTER TABLE seller_subscriptions
DROP COLUMN IF EXISTS stripe_subscription_id,
DROP COLUMN IF EXISTS stripe_customer_id;

-- 2. Remove Stripe columns from subscription_payments
ALTER TABLE subscription_payments
DROP COLUMN IF EXISTS stripe_payment_intent_id;

-- 3. Drop any Stripe-related functions if they exist (cleanup)
-- (Assuming 'create-subscription-checkout' is an Edge Function, 
-- but we might have some RPCs or triggers related to it. 
-- Listing common ones just in case)

-- Clean up any comments or descriptions related to Stripe in the schema
COMMENT ON TABLE seller_subscriptions IS 'Stores seller subscription details (Stripe integration removed)';
