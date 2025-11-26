# Push Notifications Test Plan

Use this checklist after supplying real Firebase credentials (`google-services.json`, `GoogleService-Info.plist`) and deploying the Supabase Edge Functions.

## 1. Android
1. Install the debug build on a physical device running Android 13+.
2. Launch the app, sign in, and accept the `POST_NOTIFICATIONS` permission prompt.
3. From the Supabase SQL editor, insert a fake message row or trigger a test notification via:
   ```bash
   supabase functions invoke send-notification --project-ref <ref> --body '{"title":"Test","body":"Hello","userIds":["<recipient-id>"]}'
   ```
4. Verify:
   - Foreground: in-app banner rendered via `NotificationService`.
   - Background: notification in system tray opens the conversation.
   - Token refresh: logcat shows `Push token synced` after clearing app data.

## 2. iOS
1. Upload your APNs auth key to Firebase and set the bundle identifier in Xcode.
2. Build to a physical device, enable push notifications & background modes capabilities.
3. Accept the iOS notification permission prompt and repeat the Supabase function test above.
4. Verify:
   - Foreground notifications display local alert.
   - Background notifications show in Notification Center and open the correct chat.
   - App receives silent notifications when terminated (requires APNs production cert).

## 3. Regression
- Sign out/back in to ensure tokens are upserted again.
- Delete the app; confirm `device_tokens` no longer contains stale entries after listening for 404 responses in logs (clean-up handled in Edge Function batches).
- Monitor Supabase Edge logs for failures and retry as needed.

