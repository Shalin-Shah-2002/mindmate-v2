import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../services/user_service.dart';
import '../../services/post_service.dart';
import '../community/widgets/post_card.dart';

class UserProfileView extends StatefulWidget {
  final UserModel user;

  const UserProfileView({super.key, required this.user});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  late final AuthViewModel _authController;
  late final CommunityViewModel _communityController;

  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;
  StreamSubscription<DocumentSnapshot>? _currentUserStreamSubscription;

  final RxBool isLoading = false.obs;
  final RxBool isFollowing = false.obs;
  final RxBool isLoadingPosts = true.obs;
  final RxList<PostModel> userPosts = <PostModel>[].obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<UserModel> displayedUser = Rx<UserModel>(
    UserModel(
      id: '',
      name: '',
      email: '',
      photoUrl: '',
      bio: '',
      dob: DateTime.now(),
      moodPreferences: [],
      createdAt: DateTime.now(),
      followers: [],
      following: [],
      isPrivate: false,
      sosContacts: [],
      settings: UserSettings(
        darkMode: false,
        fontSize: 'medium',
        ttsEnabled: false,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();

    // Initialize AuthViewModel if not already available
    try {
      _authController = Get.find<AuthViewModel>();
    } catch (e) {
      _authController = Get.put(AuthViewModel());
    }

    // Initialize CommunityViewModel if not already available
    try {
      _communityController = Get.find<CommunityViewModel>();
    } catch (e) {
      _communityController = Get.put(CommunityViewModel());
    }

    currentUser.value = widget.user;
    displayedUser.value = widget.user;
    _initializeProfile();
    _listenToUserUpdates();
  }

  Future<void> _initializeProfile() async {
    await _checkFollowStatus();
    await _loadUserPosts();
  }

  Future<void> _checkFollowStatus() async {
    if (_authController.userModel != null) {
      isFollowing.value = _authController.userModel!.following.contains(
        widget.user.id,
      );
    }
  }

  void _listenToUserUpdates() {
    // Listen to real-time updates for the profile user
    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            try {
              final updatedUser = UserModel.fromMap(
                snapshot.data()!,
                snapshot.id,
              );
              displayedUser.value = updatedUser;
            } catch (e) {
              print('Error updating user data: $e');
            }
          }
        });

    // Also listen to current user updates to sync follow status
    if (_authController.userModel != null) {
      _currentUserStreamSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_authController.userModel!.id)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              try {
                final updatedCurrentUser = UserModel.fromMap(
                  snapshot.data()!,
                  snapshot.id,
                );
                // Update follow status based on updated current user data
                isFollowing.value = updatedCurrentUser.following.contains(
                  widget.user.id,
                );
              } catch (e) {
                print('Error updating current user data: $e');
              }
            }
          });
    }
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    _currentUserStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshUserData() async {
    try {
      final freshUserData = await _userService.getUserById(widget.user.id);
      if (freshUserData != null) {
        displayedUser.value = freshUserData;
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      isLoadingPosts.value = true;
      final posts = await _postService.getUserPosts(widget.user.id);
      userPosts.value = posts;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user posts',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
      );
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> _toggleFollow() async {
    if (_authController.userModel == null) return;

    try {
      isLoading.value = true;

      if (isFollowing.value) {
        await _userService.unfollowUser(widget.user.id);
        isFollowing.value = false;
        Get.snackbar(
          'Unfollowed',
          'You are no longer following ${widget.user.name}',
          backgroundColor: Theme.of(Get.context!).colorScheme.surface,
          colorText: Theme.of(Get.context!).colorScheme.onSurface,
        );
      } else {
        await _userService.followUser(widget.user.id);
        isFollowing.value = true;
        Get.snackbar(
          'Following',
          'You are now following ${widget.user.name}',
          backgroundColor: Theme.of(Get.context!).colorScheme.primary,
          colorText: Theme.of(Get.context!).colorScheme.onPrimary,
        );
      }

      // Update the current user's following list
      await _authController.refreshUserProfile();

      // Refresh the displayed user data to get updated follower counts
      await _refreshUserData();

      // Force refresh the follow status to ensure UI is in sync
      await _checkFollowStatus();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update follow status',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = _authController.userModel?.id == widget.user.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeProfile();
        },
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(context, isCurrentUser),
              ),
              leading: IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),

            // Follow Button Section (outside the header to avoid overflow)
            if (!isCurrentUser)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading.value ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing.value
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.secondary,
                          foregroundColor: isFollowing.value
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isFollowing.value
                                    ? Icons.person_remove
                                    : Icons.person_add,
                              ),
                        label: Text(
                          isLoading.value
                              ? 'Loading...'
                              : isFollowing.value
                              ? 'Unfollow'
                              : 'Follow',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Posts Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Posts List
            Obx(() {
              if (isLoadingPosts.value) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (userPosts.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyPostsState(context, isCurrentUser),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = userPosts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: PostCard(
                      controller: _communityController,
                      post: post,
                      index: index,
                      onShowComments: _showCommentsDialog,
                    ),
                  );
                }, childCount: userPosts.length),
              );
            }),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isCurrentUser) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.user.photoUrl.isNotEmpty
                      ? NetworkImage(widget.user.photoUrl)
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: widget.user.photoUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                widget.user.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Bio
              if (widget.user.bio.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.user.bio,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Stats Row
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      context,
                      displayedUser.value.followers.length.toString(),
                      'Followers',
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.3),
                    ),
                    _buildStatColumn(
                      context,
                      displayedUser.value.following.length.toString(),
                      'Following',
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.3),
                    ),
                    _buildStatColumn(
                      context,
                      userPosts.length.toString(),
                      'Posts',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPostsState(BuildContext context, bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isCurrentUser
                ? 'No posts yet'
                : '${widget.user.name} hasn\'t posted yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isCurrentUser
                ? 'Share your mental wellness journey with the community'
                : 'Check back later to see their posts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCommentsDialog(
    CommunityViewModel controller,
    dynamic post,
    int index,
  ) {
    final commentController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 24,
                      color: Theme.of(Get.context!).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(Get.context!).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Comments list
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: controller.commentsStream(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data ?? const <CommentModel>[];
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              'User ${c.userId.substring(0, 8)} ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: c.content),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(c.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Comment input
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(4),
                      child: ElevatedButton(
                        onPressed: () {
                          if (commentController.text.trim().isNotEmpty) {
                            controller.addComment(
                              post.id,
                              commentController.text.trim(),
                              index,
                            );
                            commentController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Post',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
