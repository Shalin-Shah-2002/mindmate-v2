import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../viewmodels/auth_viewmodel.dart';

class SocialService {
  final AuthService _authService = AuthService();

  /// Follow or unfollow a user
  /// Returns true if operation was successful
  Future<bool> toggleFollow(String targetUserId) async {
    try {
      final authController = Get.find<AuthViewModel>();
      final currentUser = authController.userModel;

      if (currentUser == null) {
        print('SocialService: No current user found');
        return false;
      }

      final currentUserId = currentUser.id;

      // Check if already following
      final isCurrentlyFollowing = await _authService.isFollowing(
        currentUserId,
        targetUserId,
      );

      bool success;
      if (isCurrentlyFollowing) {
        // Unfollow
        success = await _authService.unfollowUser(currentUserId, targetUserId);
        if (success) {
          Get.snackbar(
            'Unfollowed',
            'You are no longer following this user',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        // Follow
        success = await _authService.followUser(currentUserId, targetUserId);
        if (success) {
          Get.snackbar(
            'Following',
            'You are now following this user',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }

      // Refresh current user's profile to update counts
      if (success) {
        await authController.refreshUserProfile();
      }

      return success;
    } catch (e) {
      print('SocialService: Error toggling follow: $e');
      Get.snackbar(
        'Error',
        'Failed to update follow status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Get followers list for current user
  Future<void> showFollowersList() async {
    try {
      final authController = Get.find<AuthViewModel>();
      final currentUser = authController.userModel;

      if (currentUser == null) return;

      final followers = await _authService.getFollowers(currentUser.id);

      if (followers.isEmpty) {
        Get.snackbar(
          'No Followers',
          'You don\'t have any followers yet',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // TODO: Navigate to followers list view
      // For now, show a snackbar with count
      Get.snackbar(
        'Followers',
        '${followers.length} followers found',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('SocialService: Error getting followers: $e');
      Get.snackbar(
        'Error',
        'Failed to load followers. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get following list for current user
  Future<void> showFollowingList() async {
    try {
      final authController = Get.find<AuthViewModel>();
      final currentUser = authController.userModel;

      if (currentUser == null) return;

      final following = await _authService.getFollowing(currentUser.id);

      if (following.isEmpty) {
        Get.snackbar(
          'No Following',
          'You are not following anyone yet',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // TODO: Navigate to following list view
      // For now, show a snackbar with count
      Get.snackbar(
        'Following',
        'You are following ${following.length} users',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('SocialService: Error getting following: $e');
      Get.snackbar(
        'Error',
        'Failed to load following list. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Development helper: Add some test followers/following to current user
  /// This is just for testing - remove in production
  Future<void> addTestSocialConnections() async {
    try {
      final authController = Get.find<AuthViewModel>();
      final currentUser = authController.userModel;

      if (currentUser == null) {
        print('SocialService: No current user found');
        return;
      }

      // This would normally be real user IDs from your system
      final testUserIds = [
        'test_user_1',
        'test_user_2',
        'test_user_3',
        'test_user_4',
        'test_user_5',
      ];

      // Add some test followers and following
      await _authService.updateUserSocialData(
        currentUser.id,
        followers: testUserIds.take(3).toList(), // First 3 as followers
        following: testUserIds
            .skip(1)
            .take(4)
            .toList(), // 4 users being followed (some overlap)
      );

      // Refresh user profile to see updated counts
      await authController.refreshUserProfile();

      Get.snackbar(
        'Test Data Added',
        'Added test followers and following data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('SocialService: Error adding test data: $e');
    }
  }
}
