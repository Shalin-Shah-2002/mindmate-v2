import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../services/social_service.dart';
import '../settings_view.dart';

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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
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
                                                authController
                                                    .userModel!
                                                    .photoUrl,
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
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
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
                                const SizedBox(height: 20),

                                // Followers and Following counts
                                Obx(() {
                                  if (authController.userModel == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildSocialMetric(
                                          authController
                                              .userModel!
                                              .followers
                                              .length
                                              .toString(),
                                          'Followers',
                                          Icons.people_outline,
                                          onTap: () {
                                            final socialService =
                                                SocialService();
                                            socialService.showFollowersList();
                                          },
                                        ),
                                        Container(
                                          height: 40,
                                          width: 1,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        _buildSocialMetric(
                                          authController
                                              .userModel!
                                              .following
                                              .length
                                              .toString(),
                                          'Following',
                                          Icons.person_add_outlined,
                                          onTap: () {
                                            final socialService =
                                                SocialService();
                                            socialService.showFollowingList();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          // Settings icon at top-right (painted above content)
                          Positioned(
                            top: 50,
                            right: 12,
                            child: Material(
                              color: Colors.white.withOpacity(0.25),
                              shape: const CircleBorder(),
                              elevation: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Get.to(() => const SettingsView());
                                },
                                tooltip: 'Settings',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // My Posts Section
                    _buildMyPostsSection(),
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

  Widget _buildSocialMetric(
    String count,
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 6),
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}
