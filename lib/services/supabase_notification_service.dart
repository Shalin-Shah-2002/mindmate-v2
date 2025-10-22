import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/notification_model.dart';

class SupabaseNotificationService {
  static const String _tableName = 'notifications';

  SupabaseClient get _client => SupabaseConfig.client;

  /// Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('recipient_id', userId)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client
          .from(_tableName)
          .update({'read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _client
          .from(_tableName)
          .update({'read': true})
          .eq('recipient_id', userId)
          .eq('read', false);

      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Create a new notification and send push notification via OneSignal
  /// This will store in database and trigger OneSignal push notification
  Future<bool> createNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Insert notification into database
      final response = await _client
          .from(_tableName)
          .insert({
            'recipient_id': recipientId,
            'title': title,
            'body': body,
            'data': data ?? {},
          })
          .select()
          .single();

      // 2. Call Edge Function to send OneSignal push notification
      await _sendPushNotification(
        notificationId: response['id'],
        recipientId: recipientId,
        title: title,
        body: body,
        data: data ?? {},
      );

      print('Notification created and push sent for user: $recipientId');
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  /// Call Supabase Edge Function to send OneSignal push notification
  Future<void> _sendPushNotification({
    required String notificationId,
    required String recipientId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-push-notification',
        body: {
          'notification_id': notificationId,
          'recipient_id': recipientId,
          'title': title,
          'body': body,
          'data': data,
        },
      );

      print('Push notification sent successfully: ${response.data}');
    } catch (e) {
      print('Error sending push notification: $e');
      // Don't throw error here - notification is still saved in database
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _client.from(_tableName).delete().eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Listen to real-time notification changes for a user
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((json) => NotificationModel.fromJson(json)).toList(),
        );
  }

  /// Delete old notifications (older than specified days)
  Future<bool> deleteOldNotifications(String userId, int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      await _client
          .from(_tableName)
          .delete()
          .eq('recipient_id', userId)
          .lt('created_at', cutoffDate.toIso8601String());

      return true;
    } catch (e) {
      print('Error deleting old notifications: $e');
      return false;
    }
  }
}
