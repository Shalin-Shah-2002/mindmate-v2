# OneSignal Push Notifications Setup

This project has been migrated from Firebase Cloud Messaging (FCM) to OneSignal for push notifications.

## What changed

- Removed all FCM client code and local notifications usage.
- Added OneSignal SDK in the Flutter app for registration and permission prompts.
- Reworked Cloud Function to send pushes via OneSignal REST API when a document is created in `notifications/`.
- Kept Firestore-based creation of app notifications (for unread counts/history) unchanged.

## Prerequisites

1. Create a OneSignal app at https://onesignal.com
2. Obtain the following:
   - OneSignal App ID
   - OneSignal REST API Key

## App configuration (Flutter)

1. Set your OneSignal App ID in `lib/config/onesignal_config.dart`:

   ```dart
   class OneSignalConfig {
     static const String appId = 'YOUR-ONESIGNAL-APP-ID';
   }
   ```

2. Ensure dependencies are installed:

   ```bash
   flutter pub get
   ```

3. The app initializes OneSignal in `NotificationService.initialize()` and links the device to the logged-in Firebase user by setting the OneSignal external user id to the Firebase Auth UID.

   - On login, we call `NotificationService.updateFCMToken()` which now maps to `OneSignal.login(<uid>)`.
   - On logout, we call `NotificationService.deleteFCMToken()` which now maps to `OneSignal.logout()`.

No other app-side changes are required for sending. Your code continues to create documents in `notifications/`, which triggers the Cloud Function to deliver a push via OneSignal.

## Android

- FCM-specific services and metadata were removed from `android/app/src/main/AndroidManifest.xml`.
- OneSignal's Flutter SDK manages required Android components automatically.

Permissions kept:
- `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`.

## iOS

- Ensure Push Notifications capability is enabled in Xcode.
- Ensure Background Modes -> Remote notifications is enabled if you want background delivery.

## Cloud Functions (OneSignal REST)

We refactored `functions/index.js` to send notifications via OneSignal.
It expects the following environment variables in the Functions runtime:

- `ONESIGNAL_APP_ID`
- `ONESIGNAL_REST_API_KEY`

Set them with Firebase CLI (Node 18 / Functions v2 supports process.env):

```bash
# From the repository root
cd functions
firebase functions:config:set onesignal.app_id="<YOUR_APP_ID>" onesignal.api_key="<YOUR_REST_API_KEY>"
# Also export to env for v2 runtime if you prefer using .env or build-time envs
# Alternatively, deploy with Google Cloud secrets and read them into env vars.
```

Then deploy functions:

```bash
npm i
firebase deploy --only functions
```

Note: The function targets recipients by `include_external_user_ids: [recipientId]`, where `recipientId` is the Firebase Auth UID you already place in the `notifications` document. The Flutter app sets this UID as OneSignal external id during login.

## Testing

1. Run the app on a physical device.
2. Accept the push permission prompt.
3. Log in; the device is linked to your user.
4. Trigger app events that create entries in `notifications/` (follow, message).
5. You should receive a OneSignal push with the same title/body/data.

## Cleanups and notes

- We no longer store `fcmToken` fields on user documents.
- `NotificationService.updateFCMToken()`/`deleteFCMToken()` are kept for backward compatibility but now call OneSignal login/logout.
- If you used any FCM-only server flows, migrate them to OneSignal or remove them.

## Troubleshooting

- No push received:
  - Confirm `ONESIGNAL_APP_ID` and `ONESIGNAL_REST_API_KEY` are configured in the Functions environment.
  - Check Functions logs for OneSignal API responses.
  - Ensure the device has called `OneSignal.login(<uid>)` (you can verify in OneSignal dashboard under All Users by external id).
- iOS background delivery:
  - Requires physical device and proper APNs (handled by OneSignal setup). Ensure iOS capabilities are enabled.
