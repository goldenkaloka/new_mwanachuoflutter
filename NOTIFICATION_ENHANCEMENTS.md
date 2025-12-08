# Push Notification Enhancements

## Overview

Push notifications have been enhanced with:
- ✅ Brand colors (Mwanachuo green #078829)
- ✅ App icon in notifications
- ✅ Reply functionality for message notifications (like WhatsApp)
- ✅ Enhanced in-app notification banners with brand styling

## Configuration Required

### 1. App Icon URL

The Edge Function uses an `APP_ICON_URL` environment variable for the notification icon. You need to:

1. **Host your app icon** (from `assets/icon/app_icon.png`) on a public URL
   - Recommended: Upload to Supabase Storage, Cloudinary, or your CDN
   - The icon should be at least 256x256 pixels for best quality

2. **Set the environment variable** in Supabase:
   - Go to: **Project Settings** → **Edge Functions** → **Secrets**
   - Add secret:
     - Name: `APP_ICON_URL`
     - Value: `https://your-cdn.com/path/to/app_icon.png`

   Or update the default in `supabase/functions/send-notification/index.ts`:
   ```typescript
   const APP_ICON_URL = Deno.env.get('APP_ICON_URL') || 'https://your-cdn.com/app_icon.png';
   ```

### 2. Brand Colors

Brand colors are automatically applied:
- **Primary Color**: `#078829` (Mwanachuo green)
- **Accent Color**: Used for Android notification accent
- **Icon Background**: Light green tint for in-app banners

## Features

### Reply Functionality

Message notifications now include reply buttons (like WhatsApp):
- **Reply** button: Opens chat screen
- **View** button: Opens conversation

To enable reply for a notification, include in the payload:
```json
{
  "type": "message",
  "conversation_id": "uuid-here",
  "sender_id": "uuid-here"
}
```

### Notification Appearance

- **System Notifications**: 
  - Brand green accent color
  - App icon displayed
  - Action buttons for messages
  
- **In-App Banners**:
  - Brand green borders and accents
  - Enhanced shadows with brand color tint
  - Icon containers with brand styling

## Testing

1. **Test notification with brand colors**:
   ```dart
   await OneSignalConfig.sendTestNotification(
     title: 'Test Notification',
     message: 'This notification uses brand colors!',
   );
   ```

2. **Test message notification with reply**:
   - Send a message notification with `type: "message"` and `conversation_id`
   - Verify reply button appears
   - Test reply action opens chat screen

## Android Notification Channels

OneSignal automatically creates notification channels. The brand color is applied via:
- `android_accent_color` in OneSignal payload
- Custom channel configuration (if needed) in MainActivity

## iOS Notification Appearance

iOS notifications use:
- App icon (from app bundle)
- Brand color for notification banner accent
- Action buttons for message notifications

## Troubleshooting

### Icon Not Showing
- Verify `APP_ICON_URL` is set correctly
- Ensure icon URL is publicly accessible
- Check icon is at least 256x256 pixels

### Reply Button Not Appearing
- Ensure notification type is `"message"` or `"chat"`
- Include `conversation_id` in notification payload
- Verify OneSignal action buttons are enabled

### Brand Colors Not Applied
- Check Edge Function is using latest version
- Verify `BRAND_COLOR` constant in Edge Function
- Ensure OneSignal payload includes `android_accent_color`

