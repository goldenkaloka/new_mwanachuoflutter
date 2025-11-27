# ⚠️ URGENT: Add Stripe Secret Key to Supabase

## The Error You're Seeing
```
Stripe not configured. Please configure STRIPE_SECRET_KEY in Supabase Edge Function secrets.
```

## ✅ Solution: Follow These Exact Steps

### Step 1: Open Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Make sure you're logged in
3. Select your project (should be visible in the project list)

### Step 2: Navigate to Edge Function Secrets
**Option A (Direct Path):**
- Go to: **https://supabase.com/dashboard/project/yhuujolmbqvntzifoaed/settings/functions**
- Click the **"Secrets"** tab at the top

**Option B (Step by Step):**
1. Click **"Project Settings"** (⚙️ gear icon in the left sidebar)
2. In the settings menu, click **"Edge Functions"**
3. Click the **"Secrets"** tab (should be at the top of the page)

### Step 3: Add the Secret
1. Click the **"New Secret"** button (or **"Add Secret"**)
2. In the form that appears:
   - **Name field**: Type exactly: `STRIPE_SECRET_KEY`
     - ⚠️ Must be exact: case-sensitive, no spaces
   - **Value field**: Paste your Stripe Secret Key (starts with `sk_test_` for test mode)
     ```
     YOUR_STRIPE_SECRET_KEY
     ```
     ⚠️ **Important**: Get your actual secret key from your Stripe Dashboard → Developers → API keys
     - ⚠️ No spaces before or after
3. Click **"Save"** or **"Add Secret"**

### Step 4: Verify It Was Added
- You should see `STRIPE_SECRET_KEY` in the secrets list
- Wait **10-30 seconds** for it to propagate to the Edge Function

### Step 5: Test Again
1. Go back to your app
2. Navigate to: **Profile → Subscription**
3. Click **"Subscribe Now"**
4. It should now work! 🎉

## 🔍 Troubleshooting

**Still getting the error?**
1. ✅ Double-check the secret name is exactly: `STRIPE_SECRET_KEY` (case-sensitive)
2. ✅ Make sure there are no extra spaces in the value
3. ✅ Wait 30 seconds after adding and try again
4. ✅ Refresh the app completely (hot restart might not be enough)
5. ✅ Check Supabase Edge Function logs to see if the secret is being read

**Can't find the Secrets section?**
- Make sure you're in: **Project Settings → Edge Functions → Secrets tab**
- If you don't see a "Secrets" tab, try refreshing the page
- Make sure you have the correct permissions (project owner/admin)

**Secret added but still not working?**
- The Edge Function might need a moment to pick up the new secret
- Try waiting 1 minute and test again
- Check the Edge Function logs in Supabase Dashboard → Edge Functions → Logs

## 📸 Visual Guide

```
Supabase Dashboard
│
├── Project Settings (⚙️)
│   │
│   └── Edge Functions
│       │
│       └── [Secrets Tab] ← Click here!
│           │
│           └── New Secret Button
│               │
│               ├── Name: STRIPE_SECRET_KEY
│               └── Value: sk_test_51SYCaRBmC0UcqX1l...
```

## 🎯 Quick Checklist

- [ ] Opened Supabase Dashboard
- [ ] Navigated to Project Settings → Edge Functions → Secrets
- [ ] Clicked "New Secret"
- [ ] Entered name: `STRIPE_SECRET_KEY` (exact, case-sensitive)
- [ ] Entered value: `YOUR_STRIPE_SECRET_KEY` (get from Stripe Dashboard)
- [ ] Clicked "Save"
- [ ] Waited 30 seconds
- [ ] Tested the subscription flow again

## 💡 Still Need Help?

If you've followed all steps and it's still not working:
1. Check Supabase Edge Function logs for detailed error messages
2. Verify the secret appears in the secrets list
3. Try removing and re-adding the secret
4. Make sure you're using the correct Supabase project

