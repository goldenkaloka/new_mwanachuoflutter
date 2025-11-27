# Stripe Integration Setup Guide

## Quick Setup Steps

### 1. Add Stripe Secret Key to Supabase

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to: **Project Settings** → **Edge Functions** → **Secrets**
4. Click **"New Secret"**
5. Add:
   - **Name**: `STRIPE_SECRET_KEY`
   - **Value**: `sk_test_51SYCaRBmC0UcqX1lwnzaMPed7HEmSfOkmbC0UIQh4JrAbsmwBghUipu9aMq1wyNzK7mNv2LB5VfLYJB7yK6il43v0053OgNTQz`
6. Click **"Save"**

### 2. Your Stripe Credentials

**Secret Key (for backend):**
```
sk_test_51SYCaRBmC0UcqX1lwnzaMPed7HEmSfOkmbC0UIQh4JrAbsmwBghUipu9aMq1wyNzK7mNv2LB5VfLYJB7yK6il43v0053OgNTQz
```

**Publishable Key (for future frontend use):**
```
pk_test_51SYCaRBmC0UcqX1lCthSfrYFrRWE4Ahi1Bx74kpVFiiwf7NNe9NcDtIlSQBHfmiLSbZ6VGWstWZhYsEQ16w7zVLa00DsSX9nMQ
```

### 3. Verify Edge Function

The Edge Function `create-subscription-checkout` is already deployed and active. It will automatically use the `STRIPE_SECRET_KEY` secret once you add it to Supabase.

### 4. Test the Integration

1. Run your Flutter app
2. Log in as a seller
3. Navigate to: **Profile** → **Subscription** (or **Account Settings** → **Subscription**)
4. Click **"Subscribe Now"**
5. You should be redirected to Stripe Checkout

### 5. Test Mode Cards

Use these test cards in Stripe Checkout:

**Success:**
- Card: `4242 4242 4242 4242`
- Expiry: Any future date (e.g., `12/34`)
- CVC: Any 3 digits (e.g., `123`)
- ZIP: Any 5 digits (e.g., `12345`)

**Decline:**
- Card: `4000 0000 0000 0002`

### 6. Optional: Create Stripe Products/Prices

If you want to use Stripe Price IDs instead of creating prices on-the-fly:

1. Go to Stripe Dashboard → **Products**
2. Click **"Add Product"**
3. Create a product named "Standard Plan" (or match your plan name)
4. Add a recurring price:
   - **Monthly**: $9.99/month
   - **Yearly**: $99.99/year
5. Copy the Price IDs (start with `price_...`)
6. Update your `subscription_plans` table:
   ```sql
   UPDATE subscription_plans
   SET 
     stripe_price_id_monthly = 'price_xxxxx',  -- Your monthly price ID
     stripe_price_id_yearly = 'price_yyyyy'    -- Your yearly price ID
   WHERE name = 'Standard Plan';
   ```

### 7. Webhook Setup (For Production)

When ready for production:

1. Go to Stripe Dashboard → **Developers** → **Webhooks**
2. Click **"Add endpoint"**
3. URL: `https://yhuujolmbqvntzifoaed.supabase.co/functions/v1/stripe-webhook-handler`
4. Select events:
   - `checkout.session.completed`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `customer.subscription.deleted`
   - `customer.subscription.updated`
5. Copy the webhook signing secret (starts with `whsec_...`)
6. Add to Supabase Edge Function secrets as `STRIPE_WEBHOOK_SECRET`

## Current Status

✅ Edge Function deployed: `create-subscription-checkout`  
✅ Database tables created: `subscription_plans`, `seller_subscriptions`, etc.  
✅ Free trial system: New sellers get 1 month free  
✅ UI integrated: Subscription page accessible from Profile and Settings  
⏳ **Action Required**: Add `STRIPE_SECRET_KEY` to Supabase Edge Function secrets

## Troubleshooting

**Error: "Stripe not configured"**
- Make sure you added `STRIPE_SECRET_KEY` to Supabase Edge Function secrets
- Wait a few seconds after adding the secret for it to propagate

**Error: "Unauthorized"**
- Make sure you're logged in as a seller
- Check that the seller_id matches the authenticated user

**Checkout not opening**
- Check browser console for errors
- Verify `url_launcher` package is installed (already added)
- Make sure the Edge Function returned a valid checkout URL

## Next Steps After Setup

1. Test subscription flow end-to-end
2. Set up webhook handler for production
3. Create success/cancel pages for better UX
4. Add subscription management UI (view current subscription, cancel, etc.)

