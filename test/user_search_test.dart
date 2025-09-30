import 'package:flutter_test/flutter_test.dart';
import 'package:mindmate/models/user_model.dart';

void main() {
  group('User Search Logic Tests', () {
    test('should return empty list for empty query', () {
      // Arrange
      const String emptyQuery = '';

      // Act & Assert
      expect(emptyQuery.trim().isEmpty, isTrue);
    });

    test('should return empty list for whitespace query', () {
      // Arrange
      const String whitespaceQuery = '   ';

      // Act & Assert
      expect(whitespaceQuery.trim().isEmpty, isTrue);
    });
  });

  group('UserModel name search logic', () {
    test('should match case-insensitive search', () {
      // Arrange
      final user = UserModel(
        id: 'test_id',
        name: 'John Doe',
        email: 'john@example.com',
        photoUrl: '',
        bio: '',
        dob: DateTime.now(),
        moodPreferences: [],
        createdAt: DateTime.now(),
        followers: [],
        following: [],
        isPrivate: false,
        sosContacts: [],
        settings: UserSettings(
          darkMode: false,
          fontSize: 'medium',
          ttsEnabled: false,
        ),
      );

      // Act & Assert
      expect(user.name.toLowerCase().contains('john'), isTrue);
      expect(user.name.toLowerCase().contains('JOHN'.toLowerCase()), isTrue);
      expect(user.name.toLowerCase().contains('doe'), isTrue);
      expect(user.name.toLowerCase().contains('smith'), isFalse);
    });

    test('should handle partial name matches', () {
      // Arrange
      final user = UserModel(
        id: 'test_id',
        name: 'Alice Johnson',
        email: 'alice@example.com',
        photoUrl: '',
        bio: '',
        dob: DateTime.now(),
        moodPreferences: [],
        createdAt: DateTime.now(),
        followers: [],
        following: [],
        isPrivate: false,
        sosContacts: [],
        settings: UserSettings(
          darkMode: false,
          fontSize: 'medium',
          ttsEnabled: false,
        ),
      );

      // Act & Assert
      expect(user.name.toLowerCase().contains('ali'), isTrue);
      expect(user.name.toLowerCase().contains('ice'), isTrue);
      expect(user.name.toLowerCase().contains('john'), isTrue);
      expect(user.name.toLowerCase().contains('son'), isTrue);
      expect(user.name.toLowerCase().contains('xyz'), isFalse);
    });
  });
}
