import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupPrivacy {
  public,
  private,
  invitation_only;

  String get displayName {
    switch (this) {
      case GroupPrivacy.public:
        return 'Public';
      case GroupPrivacy.private:
        return 'Private';
      case GroupPrivacy.invitation_only:
        return 'Invitation Only';
    }
  }
}

enum GroupCategory {
  support('Support', '🤝'),
  hobby('Hobby', '🎨'),
  fitness('Fitness', '💪'),
  education('Education', '📚'),
  technology('Technology', '💻'),
  lifestyle('Lifestyle', '✨'),
  social('Social', '👥'),
  gaming('Gaming', '🎮'),
  music('Music', '🎵'),
  other('Other', '🌟');

  const GroupCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;

  String get value => name;
}

enum GroupMemberRole {
  member,
  moderator,
  admin,
  owner;

  String get displayName {
    switch (this) {
      case GroupMemberRole.member:
        return 'Member';
      case GroupMemberRole.moderator:
        return 'Moderator';
      case GroupMemberRole.admin:
        return 'Admin';
      case GroupMemberRole.owner:
        return 'Owner';
    }
  }
}

class GroupSettings {
  final bool allowMemberInvites;
  final bool requireAdminApproval;
  final bool allowFileSharing;
  final bool muteNewMembers;
  final int maxMembers;
  final Duration messageHistory;

  const GroupSettings({
    this.allowMemberInvites = true,
    this.requireAdminApproval = false,
    this.allowFileSharing = true,
    this.muteNewMembers = false,
    this.maxMembers = 100,
    this.messageHistory = const Duration(days: 30),
  });

  Map<String, dynamic> toFirestore() {
    return {
      'allowMemberInvites': allowMemberInvites,
      'requireAdminApproval': requireAdminApproval,
      'allowFileSharing': allowFileSharing,
      'muteNewMembers': muteNewMembers,
      'maxMembers': maxMembers,
      'messageHistoryDays': messageHistory.inDays,
    };
  }

  factory GroupSettings.fromFirestore(Map<String, dynamic> data) {
    return GroupSettings(
      allowMemberInvites: data['allowMemberInvites'] ?? true,
      requireAdminApproval: data['requireAdminApproval'] ?? false,
      allowFileSharing: data['allowFileSharing'] ?? true,
      muteNewMembers: data['muteNewMembers'] ?? false,
      maxMembers: data['maxMembers'] ?? 100,
      messageHistory: Duration(days: data['messageHistoryDays'] ?? 30),
    );
  }

  static GroupSettings defaultForPrivacy(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return const GroupSettings(
          requireAdminApproval: false,
          allowMemberInvites: true,
          maxMembers: 500,
        );
      case GroupPrivacy.private:
        return const GroupSettings(
          requireAdminApproval: true,
          allowMemberInvites: false,
          maxMembers: 100,
        );
      case GroupPrivacy.invitation_only:
        return const GroupSettings(
          requireAdminApproval: true,
          allowMemberInvites: true,
          maxMembers: 50,
        );
    }
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final GroupPrivacy privacy;
  final GroupCategory category;
  final List<String> tags;
  final String ownerId;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final int memberCount;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isActive;
  final GroupSettings settings;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.privacy,
    required this.category,
    this.tags = const [],
    required this.ownerId,
    this.adminIds = const [],
    this.moderatorIds = const [],
    required this.memberCount,
    required this.maxMembers,
    required this.createdAt,
    required this.lastActivity,
    this.isActive = true,
    required this.settings,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'privacy': privacy.name,
      'category': category.name,
      'tags': tags,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'moderatorIds': moderatorIds,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'isActive': isActive,
      'settings': settings.toFirestore(),
    };
  }

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      avatarUrl: data['avatarUrl'],
      privacy: GroupPrivacy.values.firstWhere(
        (p) => p.name == data['privacy'],
        orElse: () => GroupPrivacy.public,
      ),
      category: GroupCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => GroupCategory.other,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      ownerId: data['ownerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      maxMembers: data['maxMembers'] ?? 100,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity:
          (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      settings: GroupSettings.fromFirestore(data['settings'] ?? {}),
    );
  }

  Group copyWith({
    String? name,
    String? description,
    String? avatarUrl,
    GroupPrivacy? privacy,
    GroupCategory? category,
    List<String>? tags,
    String? ownerId,
    List<String>? adminIds,
    List<String>? moderatorIds,
    int? memberCount,
    int? maxMembers,
    DateTime? lastActivity,
    bool? isActive,
    GroupSettings? settings,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      privacy: privacy ?? this.privacy,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  bool get isFull => memberCount >= maxMembers;
  bool get isPublic => privacy == GroupPrivacy.public;
  bool get isPrivate => privacy == GroupPrivacy.private;
  bool get isInvitationOnly => privacy == GroupPrivacy.invitation_only;

  bool isUserAdmin(String userId) =>
      userId == ownerId || adminIds.contains(userId);

  bool isUserModerator(String userId) =>
      isUserAdmin(userId) || moderatorIds.contains(userId);

  String get displayMemberCount => '$memberCount/$maxMembers members';
}
