import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatRoomType {
  group('group'),
  private('private'),
  support('support');

  const ChatRoomType(this.value);
  final String value;

  static ChatRoomType fromString(String value) {
    return ChatRoomType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatRoomType.group,
    );
  }
}

enum ChatRoomTopic {
  depression('depression', 'Depression Support', '🌱'),
  anxiety('anxiety', 'Anxiety Relief', '😰'),
  recovery('recovery', 'Recovery Circle', '🎯'),
  general('general', 'General Chat', '💬'),
  selfCare('self_care', 'Self Care', '💆‍♀️'),
  motivation('motivation', 'Daily Motivation', '💪'),
  crisisSupport('crisis_support', 'Crisis Support', '🆘');

  const ChatRoomTopic(this.value, this.displayName, this.emoji);
  final String value;
  final String displayName;
  final String emoji;

  static ChatRoomTopic fromString(String value) {
    return ChatRoomTopic.values.firstWhere(
      (topic) => topic.value == value,
      orElse: () => ChatRoomTopic.general,
    );
  }
}

enum ChatRoomSafetyLevel {
  high('high'), // Crisis support, heavily moderated
  medium('medium'), // Support groups, regular moderation
  low('low'); // General chat, light moderation

  const ChatRoomSafetyLevel(this.value);
  final String value;

  static ChatRoomSafetyLevel fromString(String value) {
    return ChatRoomSafetyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => ChatRoomSafetyLevel.medium,
    );
  }
}

class ChatRoom {
  // Helper function to parse dates safely
  static DateTime _parseDate(dynamic value) {
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

  final String id;
  final String name;
  final String description;
  final ChatRoomType type;
  final ChatRoomTopic topic;
  final int participantCount;
  final int maxParticipants;
  final List<String> moderatorIds;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastActivity;
  final ChatRoomSafetyLevel safetyLevel;
  final ChatRoomSettings settings;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.topic,
    required this.participantCount,
    required this.maxParticipants,
    required this.moderatorIds,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
    required this.lastActivity,
    required this.safetyLevel,
    required this.settings,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ChatRoomType.fromString(data['type'] ?? 'group'),
      topic: ChatRoomTopic.fromString(data['topic'] ?? 'general'),
      participantCount: data['participantCount'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 50,
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: _parseDate(data['createdAt']),
      lastActivity: _parseDate(data['lastActivity']),
      safetyLevel: ChatRoomSafetyLevel.fromString(
        data['safetyLevel'] ?? 'medium',
      ),
      settings: ChatRoomSettings.fromMap(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.value,
      'topic': topic.value,
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'moderatorIds': moderatorIds,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'safetyLevel': safetyLevel.value,
      'settings': settings.toMap(),
    };
  }

  ChatRoom copyWith({
    String? name,
    String? description,
    ChatRoomType? type,
    ChatRoomTopic? topic,
    int? participantCount,
    int? maxParticipants,
    List<String>? moderatorIds,
    String? createdBy,
    bool? isActive,
    DateTime? lastActivity,
    ChatRoomSafetyLevel? safetyLevel,
    ChatRoomSettings? settings,
  }) {
    return ChatRoom(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      topic: topic ?? this.topic,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      settings: settings ?? this.settings,
    );
  }
}

class ChatRoomSettings {
  final bool allowAnonymous;
  final bool requireModeration;
  final bool autoArchive;
  final Duration? messageRetentionPeriod;
  final List<String> bannedWords;
  final int maxMessagesPerHour;

  const ChatRoomSettings({
    required this.allowAnonymous,
    required this.requireModeration,
    required this.autoArchive,
    this.messageRetentionPeriod,
    required this.bannedWords,
    required this.maxMessagesPerHour,
  });

  factory ChatRoomSettings.fromMap(Map<String, dynamic> map) {
    return ChatRoomSettings(
      allowAnonymous: map['allowAnonymous'] ?? false,
      requireModeration: map['requireModeration'] ?? true,
      autoArchive: map['autoArchive'] ?? true,
      messageRetentionPeriod: map['messageRetentionPeriod'] != null
          ? Duration(days: map['messageRetentionPeriod'])
          : null,
      bannedWords: List<String>.from(map['bannedWords'] ?? []),
      maxMessagesPerHour: map['maxMessagesPerHour'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowAnonymous': allowAnonymous,
      'requireModeration': requireModeration,
      'autoArchive': autoArchive,
      'messageRetentionPeriod': messageRetentionPeriod?.inDays,
      'bannedWords': bannedWords,
      'maxMessagesPerHour': maxMessagesPerHour,
    };
  }

  // Default settings for different room types
  static ChatRoomSettings defaultForSafetyLevel(
    ChatRoomSafetyLevel safetyLevel,
  ) {
    switch (safetyLevel) {
      case ChatRoomSafetyLevel.high:
        return const ChatRoomSettings(
          allowAnonymous: false,
          requireModeration: true,
          autoArchive: false, // Keep crisis support messages
          messageRetentionPeriod: null, // Never delete
          bannedWords: [],
          maxMessagesPerHour: 5, // Slower pace for crisis support
        );

      case ChatRoomSafetyLevel.medium:
        return const ChatRoomSettings(
          allowAnonymous: true,
          requireModeration: false,
          autoArchive: true,
          messageRetentionPeriod: Duration(days: 30),
          bannedWords: [],
          maxMessagesPerHour: 15,
        );

      case ChatRoomSafetyLevel.low:
        return const ChatRoomSettings(
          allowAnonymous: true,
          requireModeration: false,
          autoArchive: true,
          messageRetentionPeriod: Duration(days: 7),
          bannedWords: [],
          maxMessagesPerHour: 30,
        );
    }
  }
}

// Chat room participant model
class ChatRoomParticipant {
  // Helper function to parse dates safely
  static DateTime _parseDate(dynamic value) {
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

  final String userId;
  final String roomId;
  final DateTime joinedAt;
  final DateTime lastSeen;
  final bool isMuted;
  final bool isAnonymous;
  final String? anonymousName;

  const ChatRoomParticipant({
    required this.userId,
    required this.roomId,
    required this.joinedAt,
    required this.lastSeen,
    required this.isMuted,
    required this.isAnonymous,
    this.anonymousName,
  });

  factory ChatRoomParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoomParticipant(
      userId: doc.id,
      roomId: data['roomId'] ?? '',
      joinedAt: _parseDate(data['joinedAt']),
      lastSeen: _parseDate(data['lastSeen']),
      isMuted: data['isMuted'] ?? false,
      isAnonymous: data['isAnonymous'] ?? false,
      anonymousName: data['anonymousName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isMuted': isMuted,
      'isAnonymous': isAnonymous,
      'anonymousName': anonymousName,
    };
  }
}
