# Push Notifications Setup

Use this checklist to provide the platform credentials needed by Firebase Cloud Messaging (FCM). Never commit the real secrets to source control—only keep them locally or in your CI secrets manager.

## Android
1. Create or open your Firebase project in the [Firebase console](https://console.firebase.google.com/).
2. Add an Android app whose package name matches `com.example.mwanachuo` (or your release ID).
3. Download the generated `google-services.json` file and place it at `android/app/google-services.json` (this path is `.gitignore`d).
4. If you change the package ID later, regenerate a matching `google-services.json`.

## iOS
1. In the same Firebase project, add an iOS app that uses the `com.example.mwanachuo` bundle identifier (or your release ID).
2. Download the `GoogleService-Info.plist` file and copy it to `ios/Runner/GoogleService-Info.plist`.
3. In Xcode, ensure the file is part of the Runner target (Build Phases ▸ Copy Bundle Resources).
4. Upload your APNs authentication key or production cert to Firebase so that APNs can hand off notifications to FCM.

## Next Steps
With the platform files in place, run `flutterfire configure` if you prefer automatic wiring, or continue with the manual integration steps outlined in `push.plan.md` (install the Firebase SDK, request permissions, persist tokens, etc.).

