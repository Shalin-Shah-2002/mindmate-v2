import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_trust_level.dart';

class UserChatProfile {
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
  final UserTrustLevel trustLevel;
  final int dailyChatTimeUsed; // in minutes
  final DateTime lastChatReset;
  final List<String> safetyFlags;
  final List<String> blockedUsers;
  final int reportCount;
  final List<String>? mentorCertifications;
  final VulnerabilityIndicators vulnerabilityIndicators;
  final int communityScore;
  final DateTime accountCreatedAt;
  final bool isEmailVerified;
  final bool hasCompletedProfile;
  final DateTime? lastTrustLevelUpdate;

  const UserChatProfile({
    required this.userId,
    required this.trustLevel,
    required this.dailyChatTimeUsed,
    required this.lastChatReset,
    required this.safetyFlags,
    required this.blockedUsers,
    required this.reportCount,
    this.mentorCertifications,
    required this.vulnerabilityIndicators,
    required this.communityScore,
    required this.accountCreatedAt,
    required this.isEmailVerified,
    required this.hasCompletedProfile,
    this.lastTrustLevelUpdate,
  });

  // Factory constructor from Firestore document
  factory UserChatProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserChatProfile(
      userId: doc.id,
      trustLevel: UserTrustLevel.fromString(data['trustLevel'] ?? 'new_user'),
      dailyChatTimeUsed: data['dailyChatTimeUsed'] ?? 0,
      lastChatReset: _parseDate(data['lastChatReset']),
      safetyFlags: List<String>.from(data['safetyFlags'] ?? []),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      reportCount: data['reportCount'] ?? 0,
      mentorCertifications: data['mentorCertifications'] != null
          ? List<String>.from(data['mentorCertifications'])
          : null,
      vulnerabilityIndicators: VulnerabilityIndicators.fromMap(
        data['vulnerabilityIndicators'] ?? {},
      ),
      communityScore: data['communityScore'] ?? 0,
      accountCreatedAt: _parseDate(data['accountCreatedAt']),
      isEmailVerified: data['isEmailVerified'] ?? false,
      hasCompletedProfile: data['hasCompletedProfile'] ?? false,
      lastTrustLevelUpdate: data['lastTrustLevelUpdate'] != null
          ? _parseDate(data['lastTrustLevelUpdate'])
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'trustLevel': trustLevel.value,
      'dailyChatTimeUsed': dailyChatTimeUsed,
      'lastChatReset': Timestamp.fromDate(lastChatReset),
      'safetyFlags': safetyFlags,
      'blockedUsers': blockedUsers,
      'reportCount': reportCount,
      'mentorCertifications': mentorCertifications,
      'vulnerabilityIndicators': vulnerabilityIndicators.toMap(),
      'communityScore': communityScore,
      'accountCreatedAt': Timestamp.fromDate(accountCreatedAt),
      'isEmailVerified': isEmailVerified,
      'hasCompletedProfile': hasCompletedProfile,
      'lastTrustLevelUpdate': lastTrustLevelUpdate != null
          ? Timestamp.fromDate(lastTrustLevelUpdate!)
          : null,
    };
  }

  // Check if user can be upgraded to a higher trust level
  UserTrustLevel? getEligibleUpgrade() {
    final accountAge = DateTime.now().difference(accountCreatedAt);

    if (trustLevel == UserTrustLevel.newUser &&
        trustLevel.canProgressTo(
          UserTrustLevel.verified,
          accountAge: accountAge,
          communityScore: communityScore,
          reportCount: reportCount,
          isEmailVerified: isEmailVerified,
          hasCompletedProfile: hasCompletedProfile,
        )) {
      return UserTrustLevel.verified;
    }

    if (trustLevel == UserTrustLevel.verified &&
        trustLevel.canProgressTo(
          UserTrustLevel.trusted,
          accountAge: accountAge,
          communityScore: communityScore,
          reportCount: reportCount,
          isEmailVerified: isEmailVerified,
          hasCompletedProfile: hasCompletedProfile,
        )) {
      return UserTrustLevel.trusted;
    }

    if (trustLevel == UserTrustLevel.trusted &&
        mentorCertifications != null &&
        mentorCertifications!.isNotEmpty &&
        trustLevel.canProgressTo(
          UserTrustLevel.mentor,
          accountAge: accountAge,
          communityScore: communityScore,
          reportCount: reportCount,
          isEmailVerified: isEmailVerified,
          hasCompletedProfile: hasCompletedProfile,
        )) {
      return UserTrustLevel.mentor;
    }

    return null;
  }

  // Check if user has exceeded daily chat time limit
  bool hasExceededDailyLimit() {
    final permissions = trustLevel.chatPermissions;
    if (permissions.dailyTimeLimit == null) return false;

    // Check if we need to reset daily counter
    final now = DateTime.now();
    final shouldReset = now.difference(lastChatReset).inDays >= 1;

    if (shouldReset) return false; // Will be reset

    return dailyChatTimeUsed >= permissions.dailyTimeLimit!.inMinutes;
  }

  // Check if user can chat with another user
  bool canChatWith(UserChatProfile otherUser) {
    // Check if blocked
    if (blockedUsers.contains(otherUser.userId) ||
        otherUser.blockedUsers.contains(userId)) {
      return false;
    }

    // Check daily limits
    if (hasExceededDailyLimit()) {
      return false;
    }

    // Vulnerability protection
    if (vulnerabilityIndicators.needsSupervision &&
        otherUser.trustLevel.level < UserTrustLevel.trusted.level) {
      return false;
    }

    if (vulnerabilityIndicators.currentMoodLevel <= 3 &&
        otherUser.trustLevel == UserTrustLevel.newUser) {
      return false;
    }

    return true;
  }

  // Copy with updated fields
  UserChatProfile copyWith({
    UserTrustLevel? trustLevel,
    int? dailyChatTimeUsed,
    DateTime? lastChatReset,
    List<String>? safetyFlags,
    List<String>? blockedUsers,
    int? reportCount,
    List<String>? mentorCertifications,
    VulnerabilityIndicators? vulnerabilityIndicators,
    int? communityScore,
    bool? isEmailVerified,
    bool? hasCompletedProfile,
    DateTime? lastTrustLevelUpdate,
  }) {
    return UserChatProfile(
      userId: userId,
      trustLevel: trustLevel ?? this.trustLevel,
      dailyChatTimeUsed: dailyChatTimeUsed ?? this.dailyChatTimeUsed,
      lastChatReset: lastChatReset ?? this.lastChatReset,
      safetyFlags: safetyFlags ?? this.safetyFlags,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reportCount: reportCount ?? this.reportCount,
      mentorCertifications: mentorCertifications ?? this.mentorCertifications,
      vulnerabilityIndicators:
          vulnerabilityIndicators ?? this.vulnerabilityIndicators,
      communityScore: communityScore ?? this.communityScore,
      accountCreatedAt: accountCreatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
      lastTrustLevelUpdate: lastTrustLevelUpdate ?? this.lastTrustLevelUpdate,
    );
  }
}

class VulnerabilityIndicators {
  final int currentMoodLevel; // 1-10 scale
  final int recentCrisisFlags; // Number of crisis flags in last 7 days
  final bool needsSupervision; // Manual flag set by professionals
  final DateTime? lastCrisisEvent;
  final List<String> triggerWords; // Personal trigger words to monitor

  const VulnerabilityIndicators({
    required this.currentMoodLevel,
    required this.recentCrisisFlags,
    required this.needsSupervision,
    this.lastCrisisEvent,
    required this.triggerWords,
  });

  // Helper function to parse dates safely
  static DateTime? _parseDate(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.parse(value);
      return null;
    } catch (_) {
      return null;
    }
  }

  factory VulnerabilityIndicators.fromMap(Map<String, dynamic> map) {
    return VulnerabilityIndicators(
      currentMoodLevel: map['currentMoodLevel'] ?? 5,
      recentCrisisFlags: map['recentCrisisFlags'] ?? 0,
      needsSupervision: map['needsSupervision'] ?? false,
      lastCrisisEvent: _parseDate(map['lastCrisisEvent']),
      triggerWords: List<String>.from(map['triggerWords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentMoodLevel': currentMoodLevel,
      'recentCrisisFlags': recentCrisisFlags,
      'needsSupervision': needsSupervision,
      'lastCrisisEvent': lastCrisisEvent != null
          ? Timestamp.fromDate(lastCrisisEvent!)
          : null,
      'triggerWords': triggerWords,
    };
  }

  // Check if user is in a vulnerable state
  bool get isVulnerable {
    return currentMoodLevel <= 3 || recentCrisisFlags > 0 || needsSupervision;
  }
}
