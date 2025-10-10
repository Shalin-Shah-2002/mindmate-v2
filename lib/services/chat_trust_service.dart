import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_chat_profile.dart';
import '../models/user_trust_level.dart';

// Lightweight result used to provide reasons for permission checks.
// Kept at top-level to satisfy Dart's restriction on nested classes.
class TrustPermissionResult {
  final bool allowed;
  final String? reason;
  const TrustPermissionResult(this.allowed, [this.reason]);
}

class ChatTrustService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // (Removed) Date parsing helper no longer required here; models handle parsing.

  // Collection reference
  static CollectionReference get _userChatProfiles =>
      _firestore.collection('user_chat_profiles');

  // Initialize chat profile for new user
  static Future<void> initializeChatProfile(String userId) async {
    try {
      // Prefer auth metadata exclusively to avoid any parsing issues from user doc
      final authUser = FirebaseAuth.instance.currentUser;
      final DateTime accountCreatedAt =
          authUser?.metadata.creationTime ?? DateTime.now();
      final bool isEmailVerified = authUser?.emailVerified ?? false;

      final chatProfile = UserChatProfile(
        userId: userId,
        trustLevel: UserTrustLevel.newUser,
        dailyChatTimeUsed: 0,
        lastChatReset: DateTime.now(),
        safetyFlags: [],
        blockedUsers: [],
        reportCount: 0,
        vulnerabilityIndicators: VulnerabilityIndicators(
          currentMoodLevel: 5, // Default neutral mood
          recentCrisisFlags: 0,
          needsSupervision: false,
          triggerWords: [],
        ),
        communityScore: 0,
        accountCreatedAt: accountCreatedAt,
        isEmailVerified: isEmailVerified,
        hasCompletedProfile:
            false, // safe default; updated later via verification
      );

      await _userChatProfiles.doc(userId).set(chatProfile.toFirestore());
      print('ChatTrustService: Initialized chat profile for user $userId');
    } catch (e) {
      // Fallback: write a minimal, safe document without relying on any date parsing
      print('ChatTrustService: Error initializing chat profile: $e');
      try {
        await _userChatProfiles.doc(userId).set({
          'trustLevel': UserTrustLevel.newUser.value,
          'dailyChatTimeUsed': 0,
          'lastChatReset': Timestamp.now(),
          'safetyFlags': <String>[],
          'blockedUsers': <String>[],
          'reportCount': 0,
          'mentorCertifications': null,
          'vulnerabilityIndicators': {
            'currentMoodLevel': 5,
            'recentCrisisFlags': 0,
            'needsSupervision': false,
            'lastCrisisEvent': null,
            'triggerWords': <String>[],
          },
          'communityScore': 0,
          'accountCreatedAt': Timestamp.now(),
          'isEmailVerified': false,
          'hasCompletedProfile': false,
          'lastTrustLevelUpdate': null,
        });
        print(
          'ChatTrustService: Wrote minimal chat profile for user $userId (fallback).',
        );
      } catch (inner) {
        print(
          'ChatTrustService: Fallback failed while initializing chat profile: $inner',
        );
        rethrow;
      }
    }
  }

  // Get user's chat profile
  static Future<UserChatProfile?> getUserChatProfile(String userId) async {
    try {
      final doc = await _userChatProfiles.doc(userId).get();
      if (!doc.exists) {
        // Initialize if doesn't exist
        await initializeChatProfile(userId);
        final newDoc = await _userChatProfiles.doc(userId).get();
        return UserChatProfile.fromFirestore(newDoc);
      }
      return UserChatProfile.fromFirestore(doc);
    } catch (e) {
      print('ChatTrustService: Error getting chat profile: $e');
      return null;
    }
  }

  // Stream user's chat profile
  static Stream<UserChatProfile?> streamUserChatProfile(String userId) {
    return _userChatProfiles.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserChatProfile.fromFirestore(doc);
    });
  }

  // Update trust level with validation
  static Future<bool> updateTrustLevel(
    String userId,
    UserTrustLevel newLevel,
  ) async {
    try {
      final currentProfile = await getUserChatProfile(userId);
      if (currentProfile == null) return false;

      // Validate the upgrade is allowed
      final accountAge = DateTime.now().difference(
        currentProfile.accountCreatedAt,
      );

      if (!currentProfile.trustLevel.canProgressTo(
        newLevel,
        accountAge: accountAge,
        communityScore: currentProfile.communityScore,
        reportCount: currentProfile.reportCount,
        isEmailVerified: currentProfile.isEmailVerified,
        hasCompletedProfile: currentProfile.hasCompletedProfile,
      )) {
        print('ChatTrustService: Trust level upgrade not allowed');
        return false;
      }

      await _userChatProfiles.doc(userId).update({
        'trustLevel': newLevel.value,
        'lastTrustLevelUpdate': Timestamp.now(),
      });

      print(
        'ChatTrustService: Updated trust level for $userId to ${newLevel.value}',
      );
      return true;
    } catch (e) {
      print('ChatTrustService: Error updating trust level: $e');
      return false;
    }
  }

  // Auto-upgrade eligible users
  static Future<bool> checkAndUpgradeTrustLevel(String userId) async {
    try {
      final profile = await getUserChatProfile(userId);
      if (profile == null) return false;

      final eligibleUpgrade = profile.getEligibleUpgrade();
      if (eligibleUpgrade != null) {
        return await updateTrustLevel(userId, eligibleUpgrade);
      }

      return false;
    } catch (e) {
      print('ChatTrustService: Error checking trust level upgrade: $e');
      return false;
    }
  }

  // Update community score (called when user posts, comments, helps others)
  static Future<void> updateCommunityScore(String userId, int points) async {
    try {
      await _userChatProfiles.doc(userId).update({
        'communityScore': FieldValue.increment(points),
      });

      // Check for trust level upgrade after community score update
      await checkAndUpgradeTrustLevel(userId);
    } catch (e) {
      print('ChatTrustService: Error updating community score: $e');
    }
  }

  // Add safety flag
  static Future<void> addSafetyFlag(String userId, String flag) async {
    try {
      await _userChatProfiles.doc(userId).update({
        'safetyFlags': FieldValue.arrayUnion([flag]),
      });
      print('ChatTrustService: Added safety flag to user $userId: $flag');
    } catch (e) {
      print('ChatTrustService: Error adding safety flag: $e');
    }
  }

  // Block user
  static Future<void> blockUser(String blockerId, String blockedUserId) async {
    try {
      await _userChatProfiles.doc(blockerId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
      print('ChatTrustService: User $blockerId blocked $blockedUserId');
    } catch (e) {
      print('ChatTrustService: Error blocking user: $e');
    }
  }

  // Unblock user
  static Future<void> unblockUser(
    String blockerId,
    String blockedUserId,
  ) async {
    try {
      await _userChatProfiles.doc(blockerId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
      print('ChatTrustService: User $blockerId unblocked $blockedUserId');
    } catch (e) {
      print('ChatTrustService: Error unblocking user: $e');
    }
  }

  // Update daily chat time
  static Future<void> updateChatTime(String userId, int minutesUsed) async {
    try {
      final profile = await getUserChatProfile(userId);
      if (profile == null) return;

      final now = DateTime.now();
      final shouldReset = now.difference(profile.lastChatReset).inDays >= 1;

      if (shouldReset) {
        // Reset daily counter
        await _userChatProfiles.doc(userId).update({
          'dailyChatTimeUsed': minutesUsed,
          'lastChatReset': Timestamp.now(),
        });
      } else {
        // Increment existing time
        await _userChatProfiles.doc(userId).update({
          'dailyChatTimeUsed': FieldValue.increment(minutesUsed),
        });
      }
    } catch (e) {
      print('ChatTrustService: Error updating chat time: $e');
    }
  }

  // Update vulnerability indicators (usually called from mood tracking)
  static Future<void> updateVulnerabilityIndicators(
    String userId,
    VulnerabilityIndicators indicators,
  ) async {
    try {
      await _userChatProfiles.doc(userId).update({
        'vulnerabilityIndicators': indicators.toMap(),
      });
      print('ChatTrustService: Updated vulnerability indicators for $userId');
    } catch (e) {
      print('ChatTrustService: Error updating vulnerability indicators: $e');
    }
  }

  // Check if two users can chat with each other
  static Future<bool> canUsersChat(String userId1, String userId2) async {
    try {
      final profile1 = await getUserChatProfile(userId1);
      final profile2 = await getUserChatProfile(userId2);

      if (profile1 == null || profile2 == null) return false;

      return profile1.canChatWith(profile2) && profile2.canChatWith(profile1);
    } catch (e) {
      print('ChatTrustService: Error checking if users can chat: $e');
      return false;
    }
  }

  // Get users eligible for mentorship
  static Future<List<UserChatProfile>> getMentors() async {
    try {
      final querySnapshot = await _userChatProfiles
          .where('trustLevel', isEqualTo: 'mentor')
          .get();

      return querySnapshot.docs
          .map((doc) => UserChatProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ChatTrustService: Error getting mentors: $e');
      return [];
    }
  }

  // (Removed) Profile completeness check is deferred to user/profile flows.

  // Batch update for profile verification
  static Future<void> updateProfileVerification(
    String userId, {
    required bool isEmailVerified,
    required bool hasCompletedProfile,
  }) async {
    try {
      await _userChatProfiles.doc(userId).update({
        'isEmailVerified': isEmailVerified,
        'hasCompletedProfile': hasCompletedProfile,
      });

      // Check for trust level upgrade
      await checkAndUpgradeTrustLevel(userId);
    } catch (e) {
      print('ChatTrustService: Error updating profile verification: $e');
    }
  }

  // Get user's remaining chat time for the day
  static Future<Duration?> getRemainingChatTime(String userId) async {
    try {
      final profile = await getUserChatProfile(userId);
      if (profile == null) return null;

      final permissions = profile.trustLevel.chatPermissions;
      if (permissions.dailyTimeLimit == null) return null; // No limit

      final now = DateTime.now();
      final shouldReset = now.difference(profile.lastChatReset).inDays >= 1;

      if (shouldReset) {
        return permissions.dailyTimeLimit; // Full time available
      }

      final usedMinutes = profile.dailyChatTimeUsed;
      final limitMinutes = permissions.dailyTimeLimit!.inMinutes;
      final remainingMinutes = limitMinutes - usedMinutes;

      return Duration(minutes: remainingMinutes.clamp(0, limitMinutes));
    } catch (e) {
      print('ChatTrustService: Error getting remaining chat time: $e');
      return Duration.zero;
    }
  }

  // Intentionally a different name than any similarly shaped classes in other
  // libraries to avoid type name collisions when importing.
  // PrivateChatService only relies on the presence of `.allowed` and `.reason`.
  static const String _genericDeniedReason =
      'Chat not permitted based on current safety and trust settings';

  // Like canUsersChat but returns a human-readable reason when denied.
  static Future<TrustPermissionResult> canUsersChatWithReason(
    String userId1,
    String userId2,
  ) async {
    try {
      final profile1 = await getUserChatProfile(userId1);
      final profile2 = await getUserChatProfile(userId2);

      if (profile1 == null || profile2 == null) {
        return const TrustPermissionResult(false, 'User profile not found');
      }

      // Mutual block check (defensive; DM service also checks user_blocks)
      if (profile1.blockedUsers.contains(userId2)) {
        return const TrustPermissionResult(false, "You've blocked this user");
      }
      if (profile2.blockedUsers.contains(userId1)) {
        return const TrustPermissionResult(false, 'This user has blocked you');
      }

      // Daily limits
      if (profile1.hasExceededDailyLimit()) {
        return const TrustPermissionResult(
          false,
          'You have reached your daily chat limit',
        );
      }
      if (profile2.hasExceededDailyLimit()) {
        return const TrustPermissionResult(
          false,
          'The other user has reached their daily chat limit',
        );
      }

      // Vulnerability protection and supervision constraints
      if (profile1.vulnerabilityIndicators.needsSupervision &&
          profile2.trustLevel.level < UserTrustLevel.trusted.level) {
        return const TrustPermissionResult(
          false,
          'For safety, you can only chat with trusted members or mentors right now',
        );
      }
      if (profile2.vulnerabilityIndicators.needsSupervision &&
          profile1.trustLevel.level < UserTrustLevel.trusted.level) {
        return const TrustPermissionResult(
          false,
          'This user currently requires supervision and cannot chat right now',
        );
      }

      if (profile1.vulnerabilityIndicators.currentMoodLevel <= 3 &&
          profile2.trustLevel == UserTrustLevel.newUser) {
        return const TrustPermissionResult(
          false,
          "For your safety, you can't chat with new users right now",
        );
      }
      if (profile2.vulnerabilityIndicators.currentMoodLevel <= 3 &&
          profile1.trustLevel == UserTrustLevel.newUser) {
        return const TrustPermissionResult(
          false,
          'For safety, new users cannot chat with this user right now',
        );
      }

      // Fallback to the existing symmetric check
      final allowed =
          profile1.canChatWith(profile2) && profile2.canChatWith(profile1);
      return allowed
          ? const TrustPermissionResult(true)
          : const TrustPermissionResult(false, _genericDeniedReason);
    } catch (e) {
      print('ChatTrustService: Error checking chat with reason: $e');
      return const TrustPermissionResult(false, _genericDeniedReason);
    }
  }
}
