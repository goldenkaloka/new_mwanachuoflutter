# Fix 401 Error for Edge Function

## The Problem
The Edge Function is returning `401 Unauthorized` because JWT verification is enabled at the platform level, and the database trigger cannot provide a valid JWT.

## The Solution

According to the [official Supabase documentation](https://supabase.com/docs/guides/functions/function-configuration), you need to **disable JWT verification for the `send-notification` function in the Supabase Dashboard**.

### Steps:

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Navigate to**: Your Project → **Edge Functions**
3. **Click on**: `send-notification` function
4. **Go to Settings** (or Configuration)
5. **Find**: "Verify JWT" or "JWT Verification" setting
6. **Turn it OFF** / **Disable it**
7. **Save**

### Why This is Needed

- The `config.toml` file only works for **local development**
- For **hosted Supabase projects**, you must configure this in the Dashboard
- Database triggers calling Edge Functions cannot provide user JWTs
- The service role key approach works, but requires JWT verification to be disabled OR the platform needs to accept service_role tokens (which may not be supported for Edge Functions)

### After Disabling JWT Verification

1. The trigger will be able to call the Edge Function without authentication
2. The Edge Function will still be secure because:
   - It's only called internally by database triggers
   - It requires OneSignal API keys (stored as secrets)
   - It validates the payload structure

### Alternative: Keep JWT Enabled

If you want to keep JWT verification enabled, you would need to:
1. Store the service role key in Vault (✅ Already done)
2. Send it in the Authorization header (✅ Already done in trigger)
3. **BUT**: Supabase's platform-level JWT verification may not accept service_role tokens for Edge Functions

The recommended approach is to **disable JWT verification** for this specific function since it's only called internally by database triggers.

## Test After Fixing

After disabling JWT verification in the Dashboard:
1. Send a test message
2. Check Edge Function logs - should see `200` instead of `401`
3. Recipient should receive notification


