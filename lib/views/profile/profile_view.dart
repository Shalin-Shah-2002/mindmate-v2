import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AuthViewModel
    late AuthViewModel authController;
    try {
      authController = Get.find<AuthViewModel>();
    } catch (e) {
      authController = Get.put(AuthViewModel());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await authController.refreshUserProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              // Show loading state if actively loading
              if (authController.isLoading.value) {
                return _buildLoadingState();
              }

              // Check if we have user model
              if (authController.userModel != null) {
                return Column(
                  children: [
                    // Enhanced Profile Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                            const Color(0xFF6366F1).withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            // Profile Picture with enhanced design
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage:
                                        authController
                                            .userModel!
                                            .photoUrl
                                            .isNotEmpty
                                        ? NetworkImage(
                                            authController.userModel!.photoUrl,
                                          )
                                        : null,
                                    backgroundColor: Colors.white,
                                    child:
                                        authController
                                            .userModel!
                                            .photoUrl
                                            .isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Color(0xFF6366F1),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Name and Bio with enhanced styling
                            Text(
                              authController.userModel!.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                authController.userModel!.bio.isNotEmpty
                                    ? authController.userModel!.bio
                                    : 'Your mental wellness journey starts here ✨',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats Row
                    _buildQuickStatsRow(),
                    const SizedBox(height: 24),

                    // Focus Areas with enhanced design
                    if (authController
                        .userModel!
                        .moodPreferences
                        .isNotEmpty) ...[
                      _buildEnhancedSectionCard(
                        'Focus Areas',
                        Icons.psychology_outlined,
                        const Color(0xFF8B5CF6),
                        Column(
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: authController
                                  .userModel!
                                  .moodPreferences
                                  .map(
                                    (pref) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF8B5CF6,
                                            ).withOpacity(0.1),
                                            const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        pref,
                                        style: const TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Enhanced Progress Section
                    _buildEnhancedSectionCard(
                      'Your Wellness Journey',
                      Icons.trending_up,
                      const Color(0xFF10B981),
                      Column(
                        children: [
                          _buildProgressItem(
                            'Days Active',
                            '15',
                            Icons.calendar_today,
                            const Color(0xFF10B981),
                            0.75,
                          ),
                          const SizedBox(height: 20),
                          _buildProgressItem(
                            'AI Conversations',
                            '8',
                            Icons.chat_bubble_outline,
                            const Color(0xFF6366F1),
                            0.4,
                          ),
                          const SizedBox(height: 20),
                          _buildProgressItem(
                            'Community Posts',
                            '3',
                            Icons.group,
                            const Color(0xFFEC4899),
                            0.15,
                          ),
                          const SizedBox(height: 20),
                          _buildProgressItem(
                            'Mood Entries',
                            '12',
                            Icons.mood,
                            const Color(0xFFF59E0B),
                            0.6,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced My Posts Section
                    _buildMyPostsSection(),

                    const SizedBox(height: 20),

                    // Enhanced Settings Section
                    _buildEnhancedSectionCard(
                      'Settings & Privacy',
                      Icons.settings,
                      const Color(0xFF6B7280),
                      Column(
                        children: [
                          _buildEnhancedSettingItem(
                            'Edit Profile',
                            'Update your personal information',
                            Icons.edit_outlined,
                            const Color(0xFF6366F1),
                            () {
                              Get.snackbar(
                                'Coming Soon',
                                'Profile editing will be available soon!',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                colorText: Colors.blue[700],
                              );
                            },
                          ),
                          _buildEnhancedSettingItem(
                            'Privacy Settings',
                            'Control your data and visibility',
                            Icons.privacy_tip_outlined,
                            const Color(0xFF8B5CF6),
                            () {
                              Get.snackbar(
                                'Coming Soon',
                                'Privacy settings will be available soon!',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                colorText: Colors.purple[700],
                              );
                            },
                          ),
                          _buildEnhancedSettingItem(
                            'Notifications',
                            'Manage your notification preferences',
                            Icons.notifications_outlined,
                            const Color(0xFFF59E0B),
                            () {
                              Get.snackbar(
                                'Coming Soon',
                                'Notification settings will be available soon!',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orange.withOpacity(0.1),
                                colorText: Colors.orange[700],
                              );
                            },
                          ),
                          _buildEnhancedSettingItem(
                            'Emergency Contacts',
                            'Set up your support network',
                            Icons.emergency_outlined,
                            const Color(0xFFEF4444),
                            () {
                              Get.snackbar(
                                'Coming Soon',
                                'Emergency contacts management will be available soon!',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red.withOpacity(0.1),
                                colorText: Colors.red[700],
                              );
                            },
                          ),
                          const Divider(height: 32),
                          _buildEnhancedSettingItem(
                            'Sign Out',
                            'Sign out from your account',
                            Icons.logout,
                            const Color(0xFFEF4444),
                            () {
                              Get.dialog(
                                AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Color(0xFFEF4444),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Sign Out'),
                                    ],
                                  ),
                                  content: const Text(
                                    'Are you sure you want to sign out of your account?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Get.back();
                                        authController.signOut();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Sign Out'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App Info with enhanced styling
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.psychology,
                            size: 20,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'MindMate v1.0.0 - Your Mental Health Companion',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              } else if (authController.user != null &&
                  authController.userModel == null) {
                // We have Firebase user but no UserModel - trigger refresh once
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Only refresh if we're not already loading and haven't tried yet
                  if (!authController.isLoading.value &&
                      authController.errorMessage.value.isEmpty) {
                    authController.refreshUserProfile();
                  }
                });
                return _buildLoadingState();
              } else if (authController.errorMessage.value.isNotEmpty) {
                // Show error state with retry option
                return _buildErrorState(authController);
              } else {
                // No user logged in
                return _buildNoUserState();
              }
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Loading your profile...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AuthViewModel authController) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
          const SizedBox(height: 24),
          const Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            authController.errorMessage.value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              authController.clearError();
              authController.refreshUserProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUserState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 64, color: Color(0xFF6B7280)),
          const SizedBox(height: 24),
          const Text(
            'No user signed in',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please sign in to view your profile',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login or trigger sign in
              Get.find<AuthViewModel>().signInWithGoogle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            'Posts',
            '3',
            Icons.article,
            const Color(0xFFEC4899),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            'Likes',
            '24',
            Icons.favorite,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            'Days',
            '15',
            Icons.calendar_today,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            'Level',
            '2',
            Icons.star,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionCard(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String label,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSettingItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.grey[50],
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red : color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : const Color(0xFF374151),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMyPostsSection() {
    final communityController = Get.put(CommunityViewModel());

    return _buildEnhancedSectionCard(
      'My Posts',
      Icons.article_outlined,
      const Color(0xFFEC4899),
      Obx(() {
        // Load user posts when this section is built, but only if we haven't tried yet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!communityController.hasTriedLoadingUserPosts.value &&
              !communityController.isLoadingUserPosts.value) {
            final authController = Get.find<AuthViewModel>();
            if (authController.userModel != null) {
              communityController.loadUserPosts();
            }
          }
        });

        if (communityController.isLoadingUserPosts.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (communityController.userPosts.isEmpty) {
          return _buildEmptyPostsState(communityController);
        }

        return Column(
          children: [
            // Posts count and view all button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${communityController.userPosts.length} posts published',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (communityController.userPosts.length > 3)
                  TextButton(
                    onPressed: () {
                      Get.find<NavigationViewModel>().changeTab(1);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEC4899),
                    ),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Show up to 3 recent posts
            ...communityController.userPosts
                .take(3)
                .map((post) => _buildEnhancedPostPreview(post)),

            if (communityController.userPosts.length > 3) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'And ${communityController.userPosts.length - 3} more posts...',
                  style: const TextStyle(
                    color: Color(0xFFEC4899),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildEmptyPostsState(CommunityViewModel communityController) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEC4899).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.article_outlined,
            size: 48,
            color: Color(0xFFEC4899),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No posts yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your journey with the community!\nYour story could inspire and help others.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Get.find<NavigationViewModel>().changeTab(
                  1,
                ); // Community tab index
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create First Post',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                final authController = Get.find<AuthViewModel>();
                if (authController.userModel != null) {
                  communityController.retryLoadUserPosts();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEC4899),
                side: const BorderSide(color: Color(0xFFEC4899)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedPostPreview(dynamic post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: post.isAnonymous
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  post.isAnonymous ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: post.isAnonymous ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                post.isAnonymous ? 'Anonymous Post' : 'Public Post',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: post.isAnonymous ? Colors.orange : Colors.green,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF374151),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPostStat(Icons.favorite, post.likesCount, Colors.red),
              const SizedBox(width: 16),
              _buildPostStat(
                Icons.chat_bubble,
                post.commentsCount,
                Colors.blue,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${post.likesCount + post.commentsCount} interactions',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostStat(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
