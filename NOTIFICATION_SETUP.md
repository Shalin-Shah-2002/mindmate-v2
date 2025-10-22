# Firebase Cloud Messaging Setup Guide

This guide explains how to complete the Firebase Cloud Messaging (FCM) setup for MindMate notifications.

## Features Implemented

The notification system has been implemented to send push notifications when:
1. **User follows another user** - The followed user receives a notification
2. **User sends a message** - The recipient receives a notification with message preview

## What's Been Done

### 1. Flutter App Configuration ✅

- Added `firebase_messaging` and `flutter_local_notifications` packages
- Created `NotificationService` to handle:
  - FCM token management
  - Permission requests
  - Foreground and background message handling
  - Local notification display
  - Navigation based on notification type
- Updated `UserModel` to store FCM tokens
- Modified `AuthService.followUser()` to send follow notifications
- Modified `PrivateChatService.sendMessage()` to send message notifications
- Initialized notification service in `main.dart`

### 2. Android Configuration ✅

Added to `AndroidManifest.xml`:
- Notification permissions (POST_NOTIFICATIONS, VIBRATE, etc.)
- Firebase Cloud Messaging service configuration
- Default notification channel and icon settings
- Notification color resource

### 3. Cloud Functions ✅

Created Firebase Cloud Functions in `/functions/`:
- `sendPushNotification` - Triggers when a notification document is created
- `cleanupOldNotifications` - Scheduled function to clean up old notifications (runs daily)

## Deployment Steps

### Step 1: Install Flutter Dependencies

```bash
cd /Users/shalinshah/Developer-Shalin\ /mindmate-v2
flutter pub get
```

### Step 2: Install Node.js Dependencies for Cloud Functions

```bash
cd functions
npm install
```

### Step 3: Deploy Cloud Functions to Firebase

```bash
# Make sure you're logged in to Firebase
firebase login

# Deploy the functions
firebase deploy --only functions
```

### Step 4: Update iOS Configuration (If Supporting iOS)

Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### Step 5: Test the Notifications

1. **Build and run the app:**
   ```bash
   flutter run
   ```

2. **Grant notification permissions** when prompted

3. **Test follow notification:**
   - Login with two different accounts
   - Have one user follow the other
   - Check if notification appears

4. **Test message notification:**
   - Login with two different accounts
   - Send a message from one to the other
   - Check if notification appears

## How It Works

### Notification Flow

1. **Client-side:**
   - When user logs in, FCM token is generated and saved to Firestore
   - When user follows someone or sends a message, a notification document is created in Firestore

2. **Server-side (Cloud Functions):**
   - Cloud Function listens to new documents in `notifications` collection
   - Retrieves recipient's FCM token from their user profile
   - Sends push notification via Firebase Cloud Messaging
   - User receives notification on their device

3. **User interaction:**
   - Tap notification → App opens to relevant screen (profile or chat)
   - Notification marked as read

## Firestore Collections

### notifications
```javascript
{
  type: 'follow' | 'message',
  recipientId: string,
  senderId: string,
  senderName: string,
  title: string,
  body: string,
  data: {
    type: string,
    userId?: string,        // For follow notifications
    conversationId?: string // For message notifications
  },
  createdAt: timestamp,
  read: boolean
}
```

### users (updated fields)
```javascript
{
  // ... existing fields
  fcmToken: string,
  fcmTokenUpdatedAt: timestamp
}
```

## Troubleshooting

### Notifications not received?

1. **Check permissions:**
   - Ensure notification permissions are granted in app settings

2. **Check FCM token:**
   - Verify token is saved in user document in Firestore
   - Check logs for "FCM Token: ..." message

3. **Check Cloud Functions:**
   - Verify functions are deployed: `firebase functions:list`
   - Check function logs: `firebase functions:log`

4. **Check notification document:**
   - Verify notification document is created in Firestore
   - Check it has correct recipientId and FCM token

### Background notifications not working?

- Ensure `FirebaseMessagingService` is properly configured in AndroidManifest.xml
- Check that background message handler is registered

### iOS notifications not working?

- Ensure APNs certificate is configured in Firebase Console
- Add remote-notification background mode in Info.plist
- Test with physical device (notifications don't work on simulator)

## Security Considerations

1. **FCM tokens are sensitive** - Stored only in Firestore, not exposed in API
2. **Notification content** - Be careful not to include sensitive information in notification body
3. **Rate limiting** - Consider implementing rate limiting to prevent notification spam
4. **User preferences** - Consider adding notification settings to allow users to control what notifications they receive

## Future Enhancements

- [ ] Add notification preferences (allow users to mute certain notification types)
- [ ] Add rich notifications with images
- [ ] Add action buttons to notifications (e.g., "Reply" for messages)
- [ ] Add notification history screen
- [ ] Implement notification batching (group multiple notifications)
- [ ] Add notification sounds customization
- [ ] Implement notification priority levels

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)


