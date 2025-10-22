-- Notifications table schema for Supabase
-- Run this SQL in your Supabase SQL Editor

-- Create notifications table
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipient_id TEXT NOT NULL, -- Firebase UID
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}', -- Additional data payload
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_recipient_read ON notifications(recipient_id, read);

-- Row Level Security (RLS) policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own notifications
CREATE POLICY "Users can read own notifications" ON notifications
  FOR SELECT USING (recipient_id = auth.jwt() ->> 'sub');

-- Policy: Allow service role to insert notifications (for Edge Functions)
CREATE POLICY "Service role can insert notifications" ON notifications
  FOR INSERT WITH CHECK (true);

-- Policy: Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (recipient_id = auth.jwt() ->> 'sub');

-- Create a function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create a function to be called by database trigger for sending push notifications
-- This will be called by the database trigger when a new notification is inserted
CREATE OR REPLACE FUNCTION send_push_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Call the Edge Function to send push notification
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

-- Create trigger to send push notification when new notification is inserted
CREATE TRIGGER send_push_notification_trigger
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION send_push_notification();