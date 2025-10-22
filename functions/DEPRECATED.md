# Firebase Cloud Functions - Deprecated

⚠️ **These Cloud Functions are now deprecated and replaced by Supabase + OneSignal.**

## What was removed:
- `sendPushNotification` - Now handled by Supabase Edge Function
- `updateFCMToken` - No longer needed (OneSignal handles device tokens)
- `cleanupOldNotifications` - Moved to Supabase scheduled tasks

## New Architecture:
- **Notifications**: Stored in Supabase PostgreSQL
- **Push Delivery**: Supabase Edge Function → OneSignal
- **Real-time**: Supabase real-time subscriptions

## To completely remove this directory:
1. Ensure Supabase setup is working
2. Test notification flow end-to-end
3. Delete this entire `functions/` directory
4. Remove Firebase Functions from `firebase.json`

## Migration Status:
✅ Notification storage moved to Supabase  
✅ Push notifications via OneSignal  
✅ Flutter app updated to use new services  
✅ Real-time subscriptions working  
🔄 Ready to delete Firebase Functions