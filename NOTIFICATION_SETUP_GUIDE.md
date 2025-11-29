# Push Notification Setup Guide

## Current Status
✅ Database trigger is configured and working
✅ Edge Function is deployed
❌ Edge Function secrets need to be configured
❌ Edge Function JWT verification may be blocking calls

## Required Setup Steps

### 1. Configure OneSignal Secrets in Edge Function

Go to your Supabase Dashboard:
1. Navigate to: **Project Settings** → **Edge Functions** → **Secrets**
2. Add these two secrets:

   **Secret 1:**
   - Name: `ONESIGNAL_APP_ID`
   - Value: `b108e16e-0426-4b7f-bd78-20f04056bade`

   **Secret 2:**
   - Name: `ONESIGNAL_REST_API_KEY`
   - Value: Your OneSignal REST API Key
     - Get it from: OneSignal Dashboard → Settings → Keys & IDs → REST API Key
     - It should look like: `YjEwOGUxNmUtMDQyNi00YjdmLWJkNzgtMjBmMDQwNTZhYWRl` (example)

### 2. Store Service Role Key in Vault (REQUIRED)

The database trigger needs the service role key to authenticate with the Edge Function.

**Steps:**
1. Get your Service Role Key:
   - Go to Supabase Dashboard → Settings → API
   - Copy the **`service_role`** key (NOT the `anon` key)

2. Store it in Vault:
   - Go to Supabase Dashboard → Database → Vault
   - Click "New Secret"
   - Name: `service_role_key`
   - Value: Paste your service role key
   - Save

**Alternative (SQL):**
```sql
INSERT INTO vault.secrets (name, secret)
VALUES ('service_role_key', 'YOUR_SERVICE_ROLE_KEY_HERE')
ON CONFLICT (name) DO UPDATE SET secret = EXCLUDED.secret;
```

See `STORE_SERVICE_ROLE_KEY.md` for detailed instructions.

### 3. Verify Device Tokens Are Registered

Check that the recipient user has a device token:
```sql
SELECT user_id, player_id, platform 
FROM device_tokens 
WHERE user_id = 'RECIPIENT_USER_ID';
```

### 4. Test the Setup

After configuring secrets:
1. Send a message from one device to another
2. Check Edge Function logs in Supabase Dashboard
3. Check OneSignal dashboard for delivery status

## Troubleshooting

### No Notifications Received

1. **Check Edge Function Logs:**
   - Supabase Dashboard → Edge Functions → `send-notification` → Logs
   - Look for errors about missing OneSignal credentials

2. **Check Database Trigger:**
   ```sql
   -- Verify trigger exists
   SELECT * FROM information_schema.triggers 
   WHERE event_object_table = 'notifications';
   ```

3. **Check Device Token Registration:**
   ```sql
   -- Verify recipient has device token
   SELECT * FROM device_tokens 
   WHERE user_id = 'RECIPIENT_USER_ID';
   ```

4. **Check Notification Insertion:**
   ```sql
   -- Verify notifications are being inserted
   SELECT * FROM notifications 
   ORDER BY created_at DESC 
   LIMIT 5;
   ```

### Common Issues

**Issue: "OneSignal credentials not configured"**
- Solution: Add `ONESIGNAL_APP_ID` and `ONESIGNAL_REST_API_KEY` secrets

**Issue: "401 Unauthorized" in Edge Function logs**
- Solution: Disable JWT verification for the Edge Function

**Issue: "No device tokens found"**
- Solution: Make sure the recipient user is logged in on their Android/iOS device and has granted notification permissions

**Issue: Notifications inserted but not sent**
- Solution: Check Edge Function logs for errors, verify secrets are configured correctly

## How It Works

1. User sends message → `sendMessage()` is called
2. Message inserted → `send_immediate_push_notification()` RPC called
3. Notification inserted → Database trigger `send_notification_trigger` fires
4. Trigger calls Edge Function → `send-notification` function executed
5. Edge Function gets device tokens → Queries `device_tokens` table
6. Edge Function calls OneSignal API → Sends push notification
7. User receives notification → With sound and banner (like WhatsApp)

## Next Steps

1. ✅ Configure OneSignal secrets (REQUIRED)
2. ✅ Disable JWT verification or configure auth (REQUIRED)
3. ✅ Test by sending a message
4. ✅ Check logs if it doesn't work

