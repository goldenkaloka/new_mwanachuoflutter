# How to Store Service Role Key in Supabase Vault

## Step 1: Get Your Service Role Key

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `yhuujolmbqvntzifoaed`
3. Go to: **Settings** → **API**
4. Find **Project API keys**
5. Copy the **`service_role`** key (NOT the `anon` key)
   - It should start with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - ⚠️ **Keep this secret!** Never commit it to git or share it publicly

## Step 2: Store in Supabase Vault

You have two options:

### Option A: Using Supabase Dashboard (Recommended)

1. Go to Supabase Dashboard → **Database** → **Vault**
2. Click **"New Secret"** or **"Add Secret"**
3. Enter:
   - **Name:** `service_role_key`
   - **Value:** Paste your service role key
4. Click **Save**

### Option B: Using SQL (Alternative)

Run this in Supabase SQL Editor (replace `YOUR_SERVICE_ROLE_KEY` with your actual key):

```sql
-- Store service role key in vault
INSERT INTO vault.secrets (name, secret)
VALUES (
  'service_role_key',
  'YOUR_SERVICE_ROLE_KEY_HERE'
)
ON CONFLICT (name) 
DO UPDATE SET secret = EXCLUDED.secret;
```

**⚠️ Important:** Replace `YOUR_SERVICE_ROLE_KEY_HERE` with your actual service role key from Step 1.

## Step 3: Verify It's Stored

Run this query to verify:

```sql
-- Check if service role key is stored (will show as encrypted)
SELECT name, created_at 
FROM vault.secrets 
WHERE name = 'service_role_key';
```

## Step 4: Test the Trigger

After storing the key, test by sending a message. The trigger will:
1. Retrieve the service role key from vault
2. Use it to authenticate the Edge Function call
3. The Edge Function will accept the authenticated request

## Troubleshooting

**If you get "Service role key not found" warnings:**
- Make sure you stored it with the exact name: `service_role_key`
- Check vault permissions
- Try the SQL method if Dashboard doesn't work

**If you still get 401 errors:**
- Verify the service role key is correct
- Check Edge Function logs for authentication errors
- Make sure JWT verification is still enabled (it should be)


