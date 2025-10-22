import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/onesignal_config.dart';
import 'supabase_notification_service.dart';

class NotificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final SupabaseNotificationService _supabaseNotifications =
      SupabaseNotificationService();

  static bool _initialized = false;

  /// Initialize OneSignal and request permissions
  static Future<void> initialize() async {
    if (_initialized) {
      print('NotificationService (OneSignal): Already initialized');
      return;
    }

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(OneSignalConfig.appId);

      // Prompt the user for permission
      await OneSignal.Notifications.requestPermission(true);

      // Set click listener to handle taps
      OneSignal.Notifications.addClickListener((event) {
        final additional = event.notification.additionalData;
        if (additional != null) {
          try {
            final data = Map<String, dynamic>.from(additional as Map);
            _navigateBasedOnNotification(data);
          } catch (_) {}
        }
      });

      // Link device to current user if logged in
      await updateFCMToken(); // Repurposed: sets OneSignal identity

      _initialized = true;
      print('NotificationService (OneSignal): Initialization complete');
    } catch (e) {
      print('NotificationService (OneSignal): Error initializing: $e');
    }
  }

  /// Navigate based on notification data
  static void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (type == 'follow') {
      final userId = data['userId'] as String?;
      if (userId != null) {
        // Navigate to user profile
        print('NotificationService: Navigate to user profile: $userId');
        // TODO: Implement navigation to user profile
        // Get.toNamed('/profile', arguments: {'userId': userId});
      }
    } else if (type == 'message') {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        // Navigate to chat
        print('NotificationService: Navigate to conversation: $conversationId');
        // TODO: Implement navigation to chat
        // Get.toNamed('/chat', arguments: {'conversationId': conversationId});
      }
    }
  }

  /// For backward compatibility: link OneSignal device to current user.
  /// Previously saved an FCM token; now sets OneSignal external user id.
  static Future<void> updateFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await OneSignal.login(user.uid);
      print(
        'NotificationService (OneSignal): set external user id ${user.uid}',
      );
    } catch (e) {
      print(
        'NotificationService (OneSignal): Error setting external user id: $e',
      );
    }
  }

  /// For backward compatibility: clear OneSignal identity on logout
  static Future<void> deleteFCMToken() async {
    try {
      await OneSignal.logout();
      print('NotificationService (OneSignal): external user id cleared');
    } catch (e) {
      print(
        'NotificationService (OneSignal): Error clearing external user id: $e',
      );
    }
  }

  /// Send notification when someone follows a user
  static Future<void> sendFollowNotification({
    required String targetUserId,
    required String followerName,
    required String followerId,
  }) async {
    try {
      // Create notification in Supabase (which will trigger OneSignal push)
      await _supabaseNotifications.createNotification(
        recipientId: targetUserId,
        title: 'New Follower',
        body: '$followerName started following you',
        data: {
          'type': 'follow',
          'userId': followerId,
          'senderId': followerId,
          'senderName': followerName,
        },
      );

      print(
        'NotificationService: Follow notification created for user: $targetUserId',
      );
    } catch (e) {
      print('NotificationService: Error sending follow notification: $e');
    }
  }

  /// Send notification when someone sends a message
  static Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String senderId,
    required String conversationId,
    required String messagePreview,
  }) async {
    try {
      // Create notification in Supabase (which will trigger OneSignal push)
      await _supabaseNotifications.createNotification(
        recipientId: recipientId,
        title: 'New Message from $senderName',
        body: messagePreview.length > 50
            ? '${messagePreview.substring(0, 50)}...'
            : messagePreview,
        data: {
          'type': 'message',
          'conversationId': conversationId,
          'senderId': senderId,
          'senderName': senderName,
        },
      );

      print(
        'NotificationService: Message notification created for user: $recipientId',
      );
    } catch (e) {
      print('NotificationService: Error sending message notification: $e');
    }
  }

  /// Get unread notification count for current user
  static Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    // Use Supabase real-time subscription for unread count
    return _supabaseNotifications
        .watchUserNotifications(user.uid)
        .map((notifications) => notifications.where((n) => !n.read).length);
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabaseNotifications.markAsRead(notificationId);
    } catch (e) {
      print('NotificationService: Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _supabaseNotifications.markAllAsRead(user.uid);
      print('NotificationService: All notifications marked as read');
    } catch (e) {
      print('NotificationService: Error marking all notifications as read: $e');
    }
  }
}
