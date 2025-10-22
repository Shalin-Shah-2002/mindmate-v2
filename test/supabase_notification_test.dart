import 'package:flutter_test/flutter_test.dart';
import 'package:mindmate/services/supabase_notification_service.dart';
import 'package:mindmate/config/supabase_config.dart';

/// Test file for Supabase + OneSignal notification integration
///
/// Before running these tests:
/// 1. Set up your Supabase project and update lib/config/supabase_config.dart
/// 2. Run the SQL schema from supabase_notifications_schema.sql in your Supabase dashboard
/// 3. Deploy the Edge Function from supabase_edge_function.ts
/// 4. Set OneSignal environment variables in Supabase
///
/// To run tests: flutter test test/supabase_notification_test.dart

void main() {
  group('Supabase Notification Integration Tests', () {
    late SupabaseNotificationService notificationService;

    setUpAll(() async {
      // Initialize Supabase for tests
      await SupabaseConfig.initialize();
      notificationService = SupabaseNotificationService();
    });

    test('should create notification in Supabase', () async {
      const testUserId = 'test_user_123';
      const testTitle = 'Test Notification';
      const testBody = 'This is a test notification from Flutter test';

      final result = await notificationService.createNotification(
        recipientId: testUserId,
        title: testTitle,
        body: testBody,
        data: {'type': 'test', 'source': 'flutter_test'},
      );

      expect(result, isTrue);
      print('✅ Notification created successfully');
    });

    test('should fetch notifications for user', () async {
      const testUserId = 'test_user_123';

      final notifications = await notificationService.getUserNotifications(
        testUserId,
      );

      expect(notifications, isNotEmpty);
      expect(notifications.first.recipientId, equals(testUserId));
      print('✅ Fetched ${notifications.length} notifications for user');
    });

    test('should get unread count', () async {
      const testUserId = 'test_user_123';

      final unreadCount = await notificationService.getUnreadCount(testUserId);

      expect(unreadCount, greaterThanOrEqualTo(0));
      print('✅ Unread count: $unreadCount');
    });

    test('should mark notification as read', () async {
      const testUserId = 'test_user_123';

      // Get a notification to mark as read
      final notifications = await notificationService.getUserNotifications(
        testUserId,
      );
      if (notifications.isNotEmpty) {
        final notificationId = notifications.first.id;

        final result = await notificationService.markAsRead(notificationId);
        expect(result, isTrue);
        print('✅ Marked notification as read');
      }
    });

    test('should test real-time notifications stream', () async {
      const testUserId = 'test_user_123';

      // Listen to notification stream
      final stream = notificationService.watchUserNotifications(testUserId);

      // Create a new notification
      await notificationService.createNotification(
        recipientId: testUserId,
        title: 'Real-time Test',
        body: 'Testing real-time notifications',
      );

      // Wait for the stream to emit the new notification
      final notifications = await stream.first;

      expect(notifications, isNotEmpty);
      expect(notifications.any((n) => n.title == 'Real-time Test'), isTrue);
      print('✅ Real-time notifications working');
    });
  });
}

/// Manual test function to verify end-to-end flow
/// Call this from your app's debug menu or test screen
Future<void> testNotificationEndToEnd({required String currentUserId}) async {
  try {
    final notificationService = SupabaseNotificationService();

    print('🧪 Starting end-to-end notification test...');

    // 1. Create a test notification
    final createResult = await notificationService.createNotification(
      recipientId: currentUserId,
      title: 'End-to-End Test',
      body: 'Testing Supabase + OneSignal integration',
      data: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
    );

    if (createResult) {
      print('✅ Step 1: Notification created in Supabase');
    } else {
      print('❌ Step 1: Failed to create notification');
      return;
    }

    // 2. Wait a moment for database trigger to fire
    await Future.delayed(const Duration(seconds: 2));

    // 3. Check if notification appears in user's list
    final notifications = await notificationService.getUserNotifications(
      currentUserId,
    );
    final testNotification = notifications
        .where((n) => n.title == 'End-to-End Test')
        .firstOrNull;

    if (testNotification != null) {
      print('✅ Step 2: Notification found in user\'s list');
      print('   - ID: ${testNotification.id}');
      print('   - Title: ${testNotification.title}');
      print('   - Body: ${testNotification.body}');
      print('   - Created: ${testNotification.createdAt}');
    } else {
      print('❌ Step 2: Notification not found in user\'s list');
    }

    // 4. Check push notification delivery
    print('📱 Step 3: Check your device for OneSignal push notification');
    print(
      '   If you received a push notification, the integration is working!',
    );

    print('🎉 End-to-end test completed!');
  } catch (e) {
    print('❌ End-to-end test failed: $e');
  }
}
