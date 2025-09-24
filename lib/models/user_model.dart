import 'package:cloud_firestore/cloud_firestore.dart';

class SosContact {
  final String name;
  final String phone;
  final String relation;

  SosContact({required this.name, required this.phone, required this.relation});

  factory SosContact.fromMap(Map<String, dynamic> map) {
    return SosContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'relation': relation};
  }
}

class UserSettings {
  final bool darkMode;
  final String fontSize;
  final bool ttsEnabled;

  UserSettings({
    required this.darkMode,
    required this.fontSize,
    required this.ttsEnabled,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      darkMode: map['darkMode'] ?? false,
      fontSize: map['fontSize'] ?? 'medium',
      ttsEnabled: map['ttsEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'fontSize': fontSize,
      'ttsEnabled': ttsEnabled,
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String bio;
  final DateTime dob;
  final List<String> moodPreferences;
  final DateTime createdAt;
  final List<String> followers;
  final List<String> following;
  final bool isPrivate;
  final List<SosContact> sosContacts;
  final UserSettings settings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.bio,
    required this.dob,
    required this.moodPreferences,
    required this.createdAt,
    required this.followers,
    required this.following,
    required this.isPrivate,
    required this.sosContacts,
    required this.settings,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime _parseDate(dynamic value) {
      try {
        if (value == null) return DateTime.now();
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String && value.isNotEmpty) return DateTime.parse(value);
        return DateTime.now();
      } catch (_) {
        return DateTime.now();
      }
    }

    String _string(
      Map<String, dynamic> m,
      List<String> keys, {
      String def = '',
    }) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return def;
    }

    return UserModel(
      id: id,
      name: _string(map, ['name', 'displayName', 'fullName', 'username']),
      email: _string(map, ['email']),
      photoUrl: _string(map, [
        'photoUrl',
        'photoURL',
        'avatarUrl',
        'profilePhotoUrl',
        'imageUrl',
      ]),
      bio: _string(map, ['bio']),
      dob: _parseDate(map['dob']),
      moodPreferences: List<String>.from(map['moodPreferences'] ?? const []),
      createdAt: _parseDate(map['createdAt']),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      isPrivate: map['isPrivate'] ?? false,
      sosContacts: (map['sosContacts'] is List)
          ? (map['sosContacts'] as List)
                .whereType<Map<String, dynamic>>()
                .map(SosContact.fromMap)
                .toList()
          : const <SosContact>[],
      settings: map['settings'] != null
          ? UserSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : UserSettings(
              darkMode: false,
              fontSize: 'medium',
              ttsEnabled: false,
            ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'dob': dob.toIso8601String(),
      'moodPreferences': moodPreferences,
      'createdAt': createdAt.toIso8601String(),
      'followers': followers,
      'following': following,
      'isPrivate': isPrivate,
      'sosContacts': sosContacts.map((e) => e.toMap()).toList(),
      'settings': settings.toMap(),
    };
  }
}
