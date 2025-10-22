# Supabase + OneSignal Notification Setup Guide

This guide shows how to set up notifications using **Supabase** for storage and **OneSignal** for push delivery, while keeping Firebase for everything else.

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Get your project credentials:
   - Go to Settings → API
   - Copy your **Project URL** and **anon public key**
3. Update `lib/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

## 2. Set Up Database Schema

1. Go to your Supabase dashboard → SQL Editor
2. Run the SQL script from `supabase_notifications_schema.sql`
3. This creates:
   - `notifications` table with proper structure
   - Row Level Security (RLS) policies
   - Database trigger for push notifications

## 3. Configure OneSignal

1. Create OneSignal app at [onesignal.com](https://onesignal.com)
2. Get your **App ID** and **REST API Key** from Settings → Keys & IDs
3. Update `lib/config/onesignal_config.dart` with your App ID

## 4. Deploy Supabase Edge Function

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login and link your project:
   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_ID
   ```

3. Create the Edge Function:
   ```bash
   supabase functions new send-push-notification
   ```

4. Copy the code from `supabase_edge_function.ts` to:
   `supabase/functions/send-push-notification/index.ts`

5. Set environment variables:
   ```bash
   supabase secrets set ONESIGNAL_APP_ID=your_app_id
   supabase secrets set ONESIGNAL_REST_API_KEY=your_rest_api_key
   ```

6. Deploy the function:
   ```bash
   supabase functions deploy send-push-notification
   ```

## 5. Update Flutter App

1. Initialize Supabase in `main.dart`:
   ```dart
   await SupabaseConfig.initialize();
   ```

2. Replace Firebase notification code with `SupabaseNotificationService`

3. Keep OneSignal initialization for receiving push notifications

## 6. Update Database Trigger

In your Supabase SQL Editor, update the trigger function with your actual project URL:

```sql
-- Update the URL in the send_push_notification function
CREATE OR REPLACE FUNCTION send_push_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://YOUR_ACTUAL_PROJECT_ID.supabase.co/functions/v1/send-push-notification',
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

## 7. Test the Setup

1. Create a test notification:
   ```dart
   final notificationService = SupabaseNotificationService();
   await notificationService.createNotification(
     recipientId: 'user_firebase_uid',
     title: 'Test Notification',
     body: 'This is a test from Supabase + OneSignal',
   );
   ```

2. Check that:
   - Notification appears in Supabase `notifications` table
   - Push notification is sent via OneSignal
   - User receives the push notification

## Architecture Overview

```
Flutter App
    ↓ (creates notification)
Supabase Database (notifications table)
    ↓ (database trigger)
Supabase Edge Function
    ↓ (sends push)
OneSignal API
    ↓ (delivers push)
User's Device
```

## Benefits

- **Firebase**: Continue using for auth, Firestore, storage
- **Supabase**: Better SQL queries, real-time subscriptions for notifications
- **OneSignal**: Advanced push notification features
- **Separation**: Notifications are isolated from other app data