# 🚀 Next Steps: Complete Supabase + OneSignal Setup

Great! You've successfully added your Supabase URL and anon key. Here's what you need to do next:

## ✅ What's Done:
- ✅ Supabase Flutter SDK added
- ✅ Configuration file updated with your credentials  
- ✅ Notification model tests passing
- ✅ Services ready for integration

## 🔧 Next Steps:

### 1. Set Up Database Schema
Go to your Supabase project dashboard and run the SQL from `supabase_notifications_schema.sql`:

1. Open [your Supabase project](https://supabase.com/dashboard/projects)
2. Go to SQL Editor
3. Copy and paste the entire content from `supabase_notifications_schema.sql`
4. Run the query - this creates:
   - `notifications` table
   - Row Level Security policies
   - Database trigger function
   - Required indexes

### 2. Deploy Edge Function for OneSignal
```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project (replace with your actual project ID)
supabase link --project-ref kyjnimuwkfrwcdbdgcyz

# Create the Edge Function
supabase functions new send-push-notification

# Copy the function code
# Replace the generated index.ts with content from supabase_edge_function.ts

# Set OneSignal credentials
supabase secrets set ONESIGNAL_APP_ID=331ee8e7-83ba-41bc-b0a4-732841a66588
supabase secrets set ONESIGNAL_REST_API_KEY=your_rest_api_key_here

# Deploy the function
supabase functions deploy send-push-notification
```

### 3. Update Database Trigger URL
After deploying the Edge Function, update the trigger in Supabase SQL Editor:

```sql
-- Update the URL in the send_push_notification function
CREATE OR REPLACE FUNCTION send_push_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://kyjnimuwkfrwcdbdgcyz.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object(
        'notification_id', NEW.id,
        'recipient_id', NEW.recipient_id,
        'title', NEW.title,
        'body', NEW.body,
        'data', NEW.data
      )
    );
  
  RETURN NEW;
END;
$$ language 'plpgsql';
```

### 4. Test the Integration

**Manual Test:**
1. Build and run your Flutter app
2. Log in with a user
3. In Supabase dashboard → Table Editor → notifications
4. Manually insert a test notification:
   ```sql
   INSERT INTO notifications (recipient_id, title, body, data)
   VALUES ('your_firebase_uid', 'Test from Supabase', 'Hello OneSignal!', '{"type": "test"}');
   ```
5. Check if you receive a push notification

**Code Test:**
```dart
// Add this to a test button in your app
final notificationService = SupabaseNotificationService();
await notificationService.createNotification(
  recipientId: FirebaseAuth.instance.currentUser!.uid,
  title: 'Test from Flutter',
  body: 'Testing Supabase + OneSignal integration',
  data: {'source': 'flutter_app'},
);
```

### 5. Monitor and Debug

**Check Supabase Logs:**
- Go to your project → Logs → Functions
- Look for Edge Function execution logs

**Check OneSignal:**
- Go to OneSignal dashboard → Delivery
- See if notifications are being sent

**Check Flutter:**
- Notifications should appear in your app's notification list
- Real-time updates should work automatically

## 🎯 Expected Flow:
1. **Create notification** → Supabase table
2. **Database trigger** → Calls Edge Function
3. **Edge Function** → Sends to OneSignal
4. **OneSignal** → Delivers push to device
5. **Flutter app** → Shows in notification list via real-time

## 📱 When It's Working:
- Notifications appear in Supabase table
- Push notifications arrive on device  
- App shows notifications in real-time
- No Firebase Cloud Functions needed

## 🆘 Need Help?
Run the tests again after database setup:
```bash
flutter test test/notification_model_test.dart  # Should pass
```

For debugging, check:
- Supabase project logs
- OneSignal delivery logs  
- Flutter debug console

Let me know when you've completed the database setup and I'll help with the next steps!