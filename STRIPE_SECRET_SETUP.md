# How to Add Stripe Secret Key to Supabase

## Quick Steps

### Step 1: Open Supabase Dashboard
1. Go to: https://supabase.com/dashboard
2. Select your project: **yhuujolmbqvntzifoaed**

### Step 2: Navigate to Edge Function Secrets
1. Click **"Project Settings"** (gear icon in left sidebar)
2. Click **"Edge Functions"** in the settings menu
3. Click the **"Secrets"** tab

### Step 3: Add the Secret
1. Click **"New Secret"** button
2. Enter:
   - **Name**: `STRIPE_SECRET_KEY`
   - **Value**: `YOUR_STRIPE_SECRET_KEY` (get from Stripe Dashboard → Developers → API keys)
3. Click **"Save"** or **"Add Secret"**

### Step 4: Verify
- The secret should appear in the list
- Wait 10-30 seconds for it to propagate
- Try the subscription flow again

## Visual Guide

```
Supabase Dashboard
  └── Project Settings (⚙️)
      └── Edge Functions
          └── Secrets (tab)
              └── New Secret
                  ├── Name: STRIPE_SECRET_KEY
                  └── Value: sk_test_51SYCaRBmC0UcqX1l...
```

## Direct Link
If you're logged in, you can go directly to:
https://supabase.com/dashboard/project/yhuujolmbqvntzifoaed/settings/functions

Then click the **"Secrets"** tab.

## Troubleshooting

**Secret not working after adding:**
- Wait 30 seconds and try again
- Make sure the name is exactly: `STRIPE_SECRET_KEY` (case-sensitive)
- Make sure there are no extra spaces in the value
- Try redeploying the Edge Function (though usually not needed)

**Can't find the Secrets section:**
- Make sure you're in Project Settings → Edge Functions
- The Secrets tab should be visible at the top of the Edge Functions page
- If not visible, you may need to refresh the page

**Still getting error:**
- Check Edge Function logs in Supabase Dashboard
- Verify the secret name matches exactly: `STRIPE_SECRET_KEY`
- Make sure you're using the test secret key (starts with `sk_test_`)

