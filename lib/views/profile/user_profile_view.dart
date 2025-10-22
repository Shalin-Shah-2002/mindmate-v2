import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../services/user_service.dart';
import '../../services/post_service.dart';
import '../../services/private_chat_service.dart';
import '../community/widgets/post_card.dart';
import '../chat/private_chat_room_view.dart';

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
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      if (isFollowing.value) {
        await _userService.unfollowUser(widget.user.id);
        isFollowing.value = false;
        Get.snackbar(
          'Unfollowed',
          'You are no longer following ${widget.user.name}',
          backgroundColor: Theme.of(Get.context!).colorScheme.surface,
          colorText: Theme.of(Get.context!).colorScheme.onSurface,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _userService.followUser(widget.user.id);
        isFollowing.value = true;
        Get.snackbar(
          'Following',
          'You are now following ${widget.user.name}',
          backgroundColor: Theme.of(Get.context!).colorScheme.surface,
          colorText: Theme.of(Get.context!).colorScheme.onSurface,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error toggling follow: $e');
      Get.snackbar(
        'Error',
        'Failed to update follow status',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _startDirectMessage() async {
    if (_authController.userModel == null) return;

    try {
      // Check if users can chat
      final permissionResult = await PrivateChatService.canUsersChatWithReason(
        _authController.userModel!.id,
        widget.user.id,
      );

      if (!permissionResult.allowed) {
        Get.snackbar(
          'Cannot Message',
          permissionResult.reason ?? 'Direct messaging is not available',
          backgroundColor: Theme.of(Get.context!).colorScheme.error,
          colorText: Theme.of(Get.context!).colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Get or create conversation
      final conversation = await PrivateChatService.createOrGetConversation(
        widget.user.id,
      );

      if (conversation != null) {
        // Navigate to private chat room
        Get.to(
          () => PrivateChatRoomView(
            conversationId: conversation.id,
            otherUserId: widget.user.id,
            otherUser: widget.user,
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to start conversation',
          backgroundColor: Theme.of(Get.context!).colorScheme.error,
          colorText: Theme.of(Get.context!).colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error starting DM: $e');
      Get.snackbar(
        'Error',
        'Failed to start direct message',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = _authController.userModel?.id == widget.user.id;

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
            await _initializeProfile();
          },
          child: CustomScrollView(
            slivers: [
              // Profile Header
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(context, isCurrentUser),
                ),
                leading: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
              ),

              // Action Buttons Section (Follow & Message)
              if (!isCurrentUser)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Obx(
                      () => Column(
                        children: [
                          // Follow Button
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: isFollowing.value
                                  ? null
                                  : const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6D83F2),
                                          Color(0xFF00C6FF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
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
                                onPressed: isLoading.value
                                    ? null
                                    : _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing.value
                                      ? Colors.white
                                      : Colors.transparent,
                                  foregroundColor: isFollowing.value
                                      ? const Color(0xFF6D83F2)
                                      : Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isFollowing.value
                                        ? const BorderSide(
                                            color: Color(0xFF6D83F2),
                                            width: 1.5,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                icon: isLoading.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Icon(
                                        isFollowing.value
                                            ? Icons.person_remove
                                            : Icons.person_add,
                                        size: 20,
                                      ),
                                label: Text(
                                  isLoading.value
                                      ? 'Loading...'
                                      : isFollowing.value
                                      ? 'Unfollow'
                                      : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Message Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _startDirectMessage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6D83F2),
                                side: const BorderSide(
                                  color: Color(0xFF6D83F2),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                              ),
                              label: const Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Posts Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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
                      const Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D23),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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
          ), // CustomScrollView
        ), // RefreshIndicator
      ), // Container
    ); // Scaffold
  }

  Widget _buildProfileHeader(BuildContext context, bool isCurrentUser) {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.user.photoUrl.isNotEmpty
                      ? NetworkImage(widget.user.photoUrl)
                      : null,
                  backgroundColor: Colors.white,
                  child: widget.user.photoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF6D83F2),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Bio
              if (widget.user.bio.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.user.bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
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
                      context,
                      displayedUser.value.following.length.toString(),
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
    );
  }

  Widget _buildEmptyPostsState(BuildContext context, bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              size: 56,
              color: Color(0xFF6D83F2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isCurrentUser
                ? 'No posts yet'
                : '${widget.user.name} hasn\'t posted yet',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D23),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isCurrentUser
                ? 'Share your mental wellness journey with the community'
                : 'Check back later to see their posts',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
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
                              ).colorScheme.surfaceContainerHighest,
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
                                              '${StringUtils.formatUserDisplayName(c.userId)} ',
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
