// import 'package:cloud_firestore/cloud_firestore.dart';

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
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      bio: map['bio'] ?? '',
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : DateTime.now(),
      moodPreferences: List<String>.from(map['moodPreferences'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      isPrivate: map['isPrivate'] ?? false,
      sosContacts: (map['sosContacts'] as List<dynamic>? ?? [])
          .map((e) => SosContact.fromMap(e as Map<String, dynamic>))
          .toList(),
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
