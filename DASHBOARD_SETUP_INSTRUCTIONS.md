# Fix 401 Error - Dashboard Setup Instructions

## Quick Summary
The database trigger is getting `401 Unauthorized` errors when calling the Edge Function. We need to update the trigger to include the service role key in the Authorization header.

## Step-by-Step Instructions

### Step 1: Get Your Service Role Key

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Find the **`service_role`** key (NOT the `anon` key)
5. **Copy** the entire key (it's long, make sure you get it all)

### Step 2: Open SQL Editor

1. In the Supabase Dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New Query"** or use an existing query tab

### Step 3: Run the Setup SQL

1. Open the file `SETUP_TRIGGER_AUTH.sql` in this project
2. **IMPORTANT**: Find this line:
   ```sql
   VALUES ('service_role_key', 'YOUR_SERVICE_ROLE_KEY_HERE')
   ```
3. Replace `'YOUR_SERVICE_ROLE_KEY_HERE'` with your actual service role key (from Step 1)
   - Keep the single quotes around it!
   - Example: `VALUES ('service_role_key', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...')`

4. Copy the **entire** SQL file content
5. Paste it into the SQL Editor
6. Click **"Run"** (or press Ctrl+Enter)

### Step 4: Verify It Worked

After running, you should see:
- ✅ No errors
- ✅ A success message: "Setup complete!"

### Step 5: Test

1. Send a message from one user to another in your app
2. Check **Edge Functions** → **`send-notification`** → **Logs**
3. You should **NOT** see `401 Unauthorized` errors anymore
4. Notifications should now be sent successfully!

## What This Does

The SQL script:
1. ✅ Enables required extensions (`pg_net` and `vault`)
2. ✅ Stores your service role key securely in Vault
3. ✅ Updates the trigger function to include the Authorization header
4. ✅ Ensures the trigger is properly attached

## Troubleshooting

### Error: "Service role key not found in Vault"
- **Solution**: Make sure you replaced `YOUR_SERVICE_ROLE_KEY_HERE` with your actual key
- Run the SQL again with the correct key

### Error: "extension pg_net does not exist"
- **Solution**: The script enables it automatically, but if it fails, you may need to enable it manually:
  ```sql
  CREATE EXTENSION IF NOT EXISTS pg_net;
  ```

### Still Getting 401 Errors
- **Check**: Make sure the Edge Function JWT verification is disabled OR accepts service_role tokens
- **Alternative**: You can also disable JWT verification for the Edge Function (see Option 1 in the main guide)

## Files Created

- `SETUP_TRIGGER_AUTH.sql` - Complete setup script (use this one)
- `FIX_TRIGGER_AUTH.sql` - Alternative version (if you already have extensions enabled)

## Next Steps

After this is working:
1. ✅ Test sending messages
2. ✅ Verify notifications are received
3. ✅ Check Edge Function logs for any other errors


