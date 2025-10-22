import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../widgets/loading_animation.dart';
import '../settings_view.dart';
import '../../services/sos_service.dart';
import '../community/widgets/post_card.dart';

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

    final communityController = Get.put(CommunityViewModel());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF9FBFF), // very light indigo tint
              Color(0xFFF7FFFB), // very light mint tint
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await authController.refreshUserProfile();
            await communityController.loadUserPosts();
          },
          child: CustomScrollView(
            slivers: [
              // App Bar with Profile Header
              SliverAppBar(
                expandedHeight: 440,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Obx(() {
                    if (authController.isLoading.value) {
                      return _buildLoadingHeader();
                    }

                    if (authController.userModel != null) {
                      return _buildProfileHeader(authController, context);
                    } else if (authController.errorMessage.value.isNotEmpty) {
                      return _buildErrorHeader(authController);
                    } else {
                      return _buildNoUserHeader();
                    }
                  }),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Get.to(() => const SettingsView()),
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
              ),

              // Posts Section
              Obx(() {
                if (authController.userModel == null &&
                    !authController.isLoading.value) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return _buildPostsSection(communityController, authController);
              }),

              // Quick SOS from profile header
              if (authController.userModel != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final user = authController.userModel!;
                        if (user.sosContacts.isEmpty) {
                          Get.snackbar(
                            'No SOS Contacts',
                            'Add SOS contacts in your profile settings first.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        final phones = user.sosContacts
                            .map((c) => c.phone)
                            .toList();
                        final sent = await SosService.sendGroupSms(
                          phoneNumbers: phones,
                          userName: user.name,
                        );
                        if (!sent) {
                          Get.snackbar(
                            'Unable to open SMS',
                            'Please check your messaging app permissions.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      icon: const Icon(Icons.sos),
                      label: const Text('Send SOS to my contacts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ), // CustomScrollView
        ), // RefreshIndicator
      ), // Container
    ); // Scaffold
  }

  // New Header Widgets for SliverAppBar
  Widget _buildLoadingHeader() {
    return Builder(
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6D83F2),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Center(
          child: LoadingAnimation(
            size: 120,
            color: Colors.white,
            message: 'Loading profile...',
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    AuthViewModel authController,
    BuildContext context,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6D83F2),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            children: [
              const SizedBox(height: 52), // Space for app bar & notch
              // Profile Picture
              LayoutBuilder(
                builder: (context, constraints) {
                  // Ensure avatar never clips; wrap with sized box
                  return SizedBox(
                    height: 110,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage:
                                  authController.userModel!.photoUrl.isNotEmpty
                                  ? NetworkImage(
                                      authController.userModel!.photoUrl,
                                    )
                                  : null,
                              backgroundColor: Colors.white,
                              child: authController.userModel!.photoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 46,
                                      color: Color(0xFF6D83F2),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          right: MediaQuery.of(context).size.width * 0.34,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Name
              Text(
                authController.userModel!.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Bio
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  authController.userModel!.bio.isNotEmpty
                      ? authController.userModel!.bio
                      : 'Your mental wellness journey starts here ✨',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 14),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn(
                    authController.userModel!.followers.length.toString(),
                    'Followers',
                  ),
                  Container(
                    height: 32,
                    width: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                  _buildStatColumn(
                    authController.userModel!.following.length.toString(),
                    'Following',
                  ),
                  Container(
                    height: 32,
                    width: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                  Obx(() {
                    final communityController = Get.find<CommunityViewModel>();
                    return _buildStatColumn(
                      communityController.userPosts.length.toString(),
                      'Posts',
                    );
                  }),
                ],
              ),

              const SizedBox(height: 12),

              // Manage SOS contacts - Modern Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // Try to open the platform contact picker via url scheme
                      // Fallback to instructions if not supported.
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Add SOS Contacts'),
                          content: const Text(
                            'To add SOS contacts, pick numbers from your phone contacts '
                            'and they will be saved to your profile. Coming soon: native contact picker.\n\n'
                            'For now, please add them from settings or paste the numbers '
                            'when prompted in the next screen.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                // Navigate to settings (or a dedicated SOS manager when available)
                                Get.to(() => const SettingsView());
                              },
                              child: const Text('Open Settings'),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Add SOS Contacts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorHeader(AuthViewModel authController) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.8),
              Colors.orange.withOpacity(0.6),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to load profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  authController.errorMessage.value,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      authController.clearError();
                      authController.refreshUserProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.red,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoUserHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[400]!, Colors.grey[600]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No user signed in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please sign in to view your profile',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D83F2).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Get.find<AuthViewModel>().signInWithGoogle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Builder(
      builder: (context) => Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Posts Section for SliverList
  Widget _buildPostsSection(
    CommunityViewModel communityController,
    AuthViewModel authController,
  ) {
    return Obx(() {
      // Load user posts when this section is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!communityController.hasTriedLoadingUserPosts.value &&
            !communityController.isLoadingUserPosts.value) {
          if (authController.userModel != null) {
            communityController.loadUserPosts();
          }
        }
      });

      if (communityController.isLoadingUserPosts.value) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      if (communityController.userPosts.isEmpty) {
        return SliverToBoxAdapter(
          child: _buildEmptyPostsState(communityController),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              // Header section
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                margin: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.grid_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Posts (${communityController.userPosts.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6D83F2).withOpacity(0.15),
                            const Color(0xFF00C6FF).withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6D83F2).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'All Posts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6D83F2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final postIndex = index - 1;
            final post = communityController.userPosts[postIndex];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PostCard(
                controller: communityController,
                post: post,
                index: postIndex,
                onShowComments: (controller, post, index) {
                  // Handle comments
                  Get.snackbar(
                    'Comments',
                    'Comments functionality coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            );
          },
          childCount: communityController.userPosts.length + 1, // +1 for header
        ),
      );
    });
  }

  Widget _buildEmptyPostsState(CommunityViewModel communityController) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6D83F2).withOpacity(0.15),
                    const Color(0xFF00C6FF).withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 64,
                color: Color(0xFF6D83F2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D23),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your mental wellness journey with the community.\nYour story could inspire and help others.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6D83F2),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                        spreadRadius: -3,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.find<NavigationViewModel>().changeTab(
                        1,
                      ); // Community tab
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    final authController = Get.find<AuthViewModel>();
                    if (authController.userModel != null) {
                      communityController.retryLoadUserPosts();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D83F2),
                    side: const BorderSide(
                      color: Color(0xFF6D83F2),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
