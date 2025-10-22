# Firebase Notifications - Quick Start Guide

## ✅ What's Been Implemented

Firebase Cloud Messaging notifications are now fully integrated into your MindMate app! Users will receive push notifications when:

1. **Someone follows them** 👥
2. **Someone sends them a message** 💬

## 🚀 Quick Deployment Steps

### 1. Install Dependencies
```bash
cd "/Users/shalinshah/Developer-Shalin /mindmate-v2"
flutter pub get
```

### 2. Deploy Cloud Functions
```bash
cd functions
npm install
firebase login
firebase deploy --only functions
```

### 3. Test Notifications
```bash
flutter run
```

## 📱 How It Works

### When a User Follows Someone:
1. User A follows User B
2. `AuthService.followUser()` creates a notification document in Firestore
3. Cloud Function detects new document
4. Cloud Function retrieves User B's FCM token
5. Push notification sent to User B's device
6. User B receives notification: "User A started following you"

### When Someone Sends a Message:
1. User A sends message to User B
2. `PrivateChatService.sendMessage()` creates a notification document
3. Cloud Function retrieves User B's FCM token
4. Push notification sent with message preview
5. User B receives notification: "New Message from User A"
6. Tapping notification opens the conversation

## 🔑 Key Components

### Flutter App
- **`notification_service.dart`** - Manages FCM tokens, permissions, and local notifications
- **`auth_service.dart`** - Sends follow notifications
- **`private_chat_service.dart`** - Sends message notifications
- **`user_model.dart`** - Stores FCM token for each user
- **`main.dart`** - Initializes notification service on app start

### Cloud Functions (`/functions/index.js`)
- **`sendPushNotification`** - Listens for new notification documents and sends push notifications
- **`cleanupOldNotifications`** - Removes notifications older than 30 days (runs daily)

### Firestore Collections
- **`notifications`** - Stores notification data (type, sender, recipient, etc.)
- **`users`** - Updated to include `fcmToken` and `fcmTokenUpdatedAt` fields

## 🧪 Testing Checklist

- [ ] Install dependencies (`flutter pub get`)
- [ ] Deploy cloud functions
- [ ] Run app on physical device (notifications don't work on emulators reliably)
- [ ] Grant notification permissions when prompted
- [ ] Test follow notification:
  - Login with Account A
  - Login with Account B on another device
  - Have Account A follow Account B
  - Check if Account B receives notification
- [ ] Test message notification:
  - Send message from Account A to Account B
  - Check if Account B receives notification
  - Tap notification to verify it opens the conversation

## 📋 Firebase Console Setup (if not done)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mindmate-9f6d3`
3. Navigate to **Cloud Messaging**
4. Ensure Android app is registered
5. For iOS (if applicable):
   - Upload APNs authentication key or certificate
   - Enable push notifications in Xcode capabilities

## 🔧 Troubleshooting

### Notifications not appearing?
1. Check notification permissions in device settings
2. Verify FCM token is saved in Firestore user document
3. Check Cloud Functions logs: `firebase functions:log`
4. Ensure device has internet connection
5. Try on a physical device (not emulator)

### Cloud Functions not deploying?
```bash
# Check Firebase CLI login
firebase login

# Check project
firebase projects:list

# Redeploy with verbose logging
firebase deploy --only functions --debug
```

### Token not updating?
- Check logs for "FCM Token: ..." message
- Verify `NotificationService.updateFCMToken()` is called on login
- Check Firestore rules allow token updates

## 📁 Files Modified/Created

### New Files
- `lib/services/notification_service.dart` - Main notification handler
- `functions/package.json` - Cloud Functions dependencies
- `functions/index.js` - Cloud Functions code
- `functions/.eslintrc.js` - ESLint configuration
- `functions/.gitignore` - Git ignore for node_modules
- `NOTIFICATION_SETUP.md` - Detailed setup guide
- `NOTIFICATION_QUICK_START.md` - This file!

### Modified Files
- `pubspec.yaml` - Added firebase_messaging and flutter_local_notifications
- `lib/models/user_model.dart` - Added fcmToken fields
- `lib/services/auth_service.dart` - Added follow notification trigger
- `lib/services/private_chat_service.dart` - Added message notification trigger
- `lib/viewmodels/auth_viewmodel.dart` - Added FCM token management on login/logout
- `lib/main.dart` - Initialize notification service
- `android/app/src/main/AndroidManifest.xml` - Added notification permissions
- `android/app/src/main/res/values/colors.xml` - Added notification color
- `firebase.json` - Added functions configuration

## 🎯 Next Steps

### Optional Enhancements
1. **Notification Preferences** - Let users mute certain notification types
2. **Rich Notifications** - Add images and action buttons
3. **Notification History** - Create a screen to view past notifications
4. **Custom Sounds** - Allow users to choose notification sounds
5. **Notification Badges** - Show unread count on app icon
6. **Group Notifications** - Batch multiple notifications together

## 🔒 Security Notes

- FCM tokens are stored securely in Firestore
- Cloud Functions run with admin privileges (secure by default)
- Only authenticated users can receive notifications
- Notification content should not include sensitive data
- Consider rate limiting to prevent spam

## 📚 Resources

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

---

**Need Help?** Check `NOTIFICATION_SETUP.md` for detailed documentation or review the inline comments in the code.


