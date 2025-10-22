-- Cleanup script to remove problematic functions and triggers
-- Run this first in Supabase SQL Editor

-- Drop the problematic trigger and function
DROP TRIGGER IF EXISTS send_push_notification_trigger ON notifications;
DROP FUNCTION IF EXISTS send_push_notification();

-- Clean up and ensure table exists with correct structure
DROP TABLE IF EXISTS notifications CASCADE;

-- Now recreate everything properly