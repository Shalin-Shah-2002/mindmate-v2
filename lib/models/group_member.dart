import 'package:cloud_firestore/cloud_firestore.dart';
import 'group.dart';

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final DateTime lastSeen;
  final bool isMuted;
  final bool hasNotifications;
  final Map<String, dynamic> customData;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role = GroupMemberRole.member,
    required this.joinedAt,
    required this.lastSeen,
    this.isMuted = false,
    this.hasNotifications = true,
    this.customData = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isMuted': isMuted,
      'hasNotifications': hasNotifications,
      'customData': customData,
    };
  }

  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroupMember(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      role: GroupMemberRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => GroupMemberRole.member,
      ),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMuted: data['isMuted'] ?? false,
      hasNotifications: data['hasNotifications'] ?? true,
      customData: Map<String, dynamic>.from(data['customData'] ?? {}),
    );
  }

  GroupMember copyWith({
    String? displayName,
    String? avatarUrl,
    GroupMemberRole? role,
    DateTime? lastSeen,
    bool? isMuted,
    bool? hasNotifications,
    Map<String, dynamic>? customData,
  }) {
    return GroupMember(
      id: id,
      groupId: groupId,
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isMuted: isMuted ?? this.isMuted,
      hasNotifications: hasNotifications ?? this.hasNotifications,
      customData: customData ?? this.customData,
    );
  }

  bool get isOwner => role == GroupMemberRole.owner;
  bool get isAdmin => role == GroupMemberRole.admin || isOwner;
  bool get isModerator => role == GroupMemberRole.moderator || isAdmin;
  bool get canModerate => isModerator;
  bool get canInvite => isModerator;
  bool get canKick => isAdmin;

  String get roleDisplayName {
    switch (role) {
      case GroupMemberRole.owner:
        return 'Owner';
      case GroupMemberRole.admin:
        return 'Admin';
      case GroupMemberRole.moderator:
        return 'Moderator';
      case GroupMemberRole.member:
        return 'Member';
    }
  }
}

enum GroupMessageType { text, image, file, system, announcement }

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final GroupMessageType type;
  final DateTime timestamp;
  final DateTime? editedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final bool isFiltered;
  final double safetyScore;
  final int reportCount;
  final List<String> reactions;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = GroupMessageType.text,
    required this.timestamp,
    this.editedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.attachments = const [],
    this.metadata = const {},
    this.isFiltered = false,
    this.safetyScore = 1.0,
    this.reportCount = 0,
    this.reactions = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isPinned': isPinned,
      'attachments': attachments,
      'metadata': metadata,
      'isFiltered': isFiltered,
      'safetyScore': safetyScore,
      'reportCount': reportCount,
      'reactions': reactions,
    };
  }

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroupMessage(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      content: data['content'] ?? '',
      type: GroupMessageType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => GroupMessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isPinned: data['isPinned'] ?? false,
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isFiltered: data['isFiltered'] ?? false,
      safetyScore: (data['safetyScore'] ?? 1.0).toDouble(),
      reportCount: data['reportCount'] ?? 0,
      reactions: List<String>.from(data['reactions'] ?? []),
    );
  }

  factory GroupMessage.system({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return GroupMessage(
      id: '',
      groupId: groupId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: GroupMessageType.system,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      safetyScore: 1.0,
      isFiltered: false,
    );
  }

  factory GroupMessage.announcement({
    required String groupId,
    required String senderId,
    required String senderName,
    required String content,
    String? senderAvatar,
  }) {
    return GroupMessage(
      id: '',
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      type: GroupMessageType.announcement,
      timestamp: DateTime.now(),
      isPinned: true,
      safetyScore: 1.0,
    );
  }

  GroupMessage copyWith({
    String? content,
    DateTime? editedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isPinned,
    bool? isFiltered,
    double? safetyScore,
    int? reportCount,
    List<String>? reactions,
    Map<String, dynamic>? metadata,
  }) {
    return GroupMessage(
      id: id,
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      attachments: attachments,
      metadata: metadata ?? this.metadata,
      isFiltered: isFiltered ?? this.isFiltered,
      safetyScore: safetyScore ?? this.safetyScore,
      reportCount: reportCount ?? this.reportCount,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get isVisible => !isDeleted && (!isFiltered || safetyScore >= 0.5);
  bool get isSystemMessage => type == GroupMessageType.system;

  // Compatibility getter for UI components that expect 'message' field
  String get message => content;
  bool get isAnnouncement => type == GroupMessageType.announcement;
  bool get needsModeration => isFiltered && safetyScore < 0.6;
}
