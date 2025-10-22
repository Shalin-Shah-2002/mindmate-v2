import 'package:flutter_test/flutter_test.dart';
import 'package:mindmate/models/notification_model.dart';

void main() {
  group('Notification Model Tests', () {
    test('should create NotificationModel from JSON', () {
      final json = {
        'id': 'test-id',
        'recipient_id': 'user-123',
        'title': 'Test Notification',
        'body': 'This is a test',
        'data': {'type': 'test'},
        'read': false,
        'created_at': '2025-10-22T10:00:00Z',
        'updated_at': '2025-10-22T10:00:00Z',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.id, equals('test-id'));
      expect(notification.recipientId, equals('user-123'));
      expect(notification.title, equals('Test Notification'));
      expect(notification.body, equals('This is a test'));
      expect(notification.read, equals(false));
      expect(notification.data['type'], equals('test'));
    });

    test('should convert NotificationModel to JSON', () {
      final notification = NotificationModel(
        id: 'test-id',
        recipientId: 'user-123',
        title: 'Test Notification',
        body: 'This is a test',
        data: {'type': 'test'},
        read: false,
        createdAt: DateTime.parse('2025-10-22T10:00:00Z'),
        updatedAt: DateTime.parse('2025-10-22T10:00:00Z'),
      );

      final json = notification.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['recipient_id'], equals('user-123'));
      expect(json['title'], equals('Test Notification'));
      expect(json['data']['type'], equals('test'));
    });
  });
}
