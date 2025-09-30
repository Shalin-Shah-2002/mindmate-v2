enum UserTrustLevel {
  newUser('new_user', 'New User', 0),
  verified('verified', 'Verified', 1),
  trusted('trusted', 'Trusted', 2),
  mentor('mentor', 'Mentor', 3);

  const UserTrustLevel(this.value, this.displayName, this.level);

  final String value;
  final String displayName;
  final int level;

  static UserTrustLevel fromString(String value) {
    return UserTrustLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => UserTrustLevel.newUser,
    );
  }

  // Trust level progression requirements
  bool canProgressTo(
    UserTrustLevel targetLevel, {
    required Duration accountAge,
    required int communityScore,
    required int reportCount,
    required bool isEmailVerified,
    required bool hasCompletedProfile,
  }) {
    switch (targetLevel) {
      case UserTrustLevel.verified:
        return isEmailVerified && hasCompletedProfile;

      case UserTrustLevel.trusted:
        return accountAge.inDays >= 90 &&
            communityScore >= 100 &&
            reportCount == 0 &&
            level >= UserTrustLevel.verified.level;

      case UserTrustLevel.mentor:
        return accountAge.inDays >= 180 &&
            communityScore >= 500 &&
            reportCount == 0 &&
            level >= UserTrustLevel.trusted.level;
      // Additional mentor certification required (handled separately)

      case UserTrustLevel.newUser:
        return true; // Can always downgrade
    }
  }

  // Chat permissions based on trust level
  ChatPermissions get chatPermissions {
    switch (this) {
      case UserTrustLevel.newUser:
        return ChatPermissions(
          canJoinGroupChats: true,
          canCreatePrivateChats: false,
          canInitiateChats: false,
          dailyTimeLimit: Duration(hours: 2),
          requiresPreModeration: true,
          canModerateChats: false,
          maxGroupChats: 3,
        );

      case UserTrustLevel.verified:
        return ChatPermissions(
          canJoinGroupChats: true,
          canCreatePrivateChats: false,
          canInitiateChats: true,
          dailyTimeLimit: Duration(hours: 4),
          requiresPreModeration: false,
          canModerateChats: false,
          maxGroupChats: 10,
        );

      case UserTrustLevel.trusted:
        return ChatPermissions(
          canJoinGroupChats: true,
          canCreatePrivateChats: true,
          canInitiateChats: true,
          dailyTimeLimit: Duration(hours: 8),
          requiresPreModeration: false,
          canModerateChats: true,
          maxGroupChats: 20,
        );

      case UserTrustLevel.mentor:
        return ChatPermissions(
          canJoinGroupChats: true,
          canCreatePrivateChats: true,
          canInitiateChats: true,
          dailyTimeLimit: null, // No limit
          requiresPreModeration: false,
          canModerateChats: true,
          maxGroupChats: null, // No limit
          canHandleCrisis: true,
          canAccessProfessionalTools: true,
        );
    }
  }
}

class ChatPermissions {
  final bool canJoinGroupChats;
  final bool canCreatePrivateChats;
  final bool canInitiateChats;
  final Duration? dailyTimeLimit;
  final bool requiresPreModeration;
  final bool canModerateChats;
  final int? maxGroupChats;
  final bool canHandleCrisis;
  final bool canAccessProfessionalTools;

  const ChatPermissions({
    required this.canJoinGroupChats,
    required this.canCreatePrivateChats,
    required this.canInitiateChats,
    required this.dailyTimeLimit,
    required this.requiresPreModeration,
    required this.canModerateChats,
    required this.maxGroupChats,
    this.canHandleCrisis = false,
    this.canAccessProfessionalTools = false,
  });
}
