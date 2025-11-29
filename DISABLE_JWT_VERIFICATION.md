# How to Disable JWT Verification for Edge Functions

## Quick Summary
Your `config.toml` already has the setting configured! You just need to deploy it.

## Method 1: Using Supabase CLI (Recommended)

### Step 1: Install Supabase CLI

**Windows (PowerShell):**
```powershell
# Option A: Using Scoop
scoop install supabase

# Option B: Using Chocolatey
choco install supabase

# Option C: Manual download
# 1. Go to: https://github.com/supabase/cli/releases
# 2. Download: supabase_windows_amd64.zip
# 3. Extract and add to PATH
```

**Verify installation:**
```bash
supabase --version
```

### Step 2: Login to Supabase
```bash
supabase login
```
This will open your browser to authenticate.

### Step 3: Link Your Project
```bash
supabase link --project-ref yhuujolmbqvntzifoaed
```

### Step 4: Deploy the Function
```bash
# Deploy with the config.toml settings (JWT verification will be disabled)
supabase functions deploy send-notification
```

**OR** deploy with explicit flag:
```bash
supabase functions deploy send-notification --no-verify-jwt
```

### Step 5: Verify
After deployment, test by sending a message. The 401 errors should be gone!

---

## Method 2: Update config.toml (Already Done!)

Your `supabase/config.toml` already has:
```toml
[functions.send-notification]
verify_jwt = false
```

This setting will be applied when you deploy via CLI.

---

## Method 3: Alternative - Keep Using Service Role Key

If you can't install CLI right now, you can continue using the service role key approach (which you've already set up in `SETUP_TRIGGER_AUTH.sql`).

The trigger will include the Authorization header with the service role key, which should work even with JWT verification enabled.

---

## Which Method Should You Use?

| Method | Pros | Cons |
|--------|------|------|
| **Disable JWT** (Method 1) | ✅ Simpler trigger code<br>✅ No need to store service role key<br>✅ Standard for webhooks/triggers | ❌ Requires CLI installation<br>❌ Function is publicly callable (but protected by OneSignal keys) |
| **Service Role Key** (Method 3) | ✅ No CLI needed<br>✅ More secure (requires auth) | ❌ More complex trigger code<br>❌ Need to store service role key |

**Recommendation:** Use Method 1 (disable JWT) since your function is only called internally by database triggers and is protected by OneSignal API keys.

---

## Troubleshooting

### "supabase: command not found"
- Make sure CLI is installed and in your PATH
- Try restarting your terminal

### "Project not linked"
- Run `supabase link --project-ref yhuujolmbqvntzifoaed` again

### Still getting 401 errors
- Check Edge Function logs in Dashboard
- Verify the function was deployed successfully
- Make sure `verify_jwt = false` is in config.toml

---

## After Disabling JWT Verification

Once JWT verification is disabled:
1. ✅ Database triggers can call the function without authentication
2. ✅ No need for service role key in trigger
3. ✅ Function is still secure (protected by OneSignal API keys)
4. ✅ You can simplify the trigger code (remove auth header)

**Note:** The function will be publicly callable, but:
- It requires OneSignal API keys (stored as secrets)
- It validates the payload structure
- It's only meant to be called by your database triggers


