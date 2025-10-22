import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/constants.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../models/post_model.dart';
import 'widgets/group_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/post_card.dart';
import '../search/search_results_view.dart';
import '../chat/chat_rooms_view.dart';
import 'create_post_view.dart';
import '../../widgets/brand_ui.dart';

class CommunityView extends StatelessWidget {
  const CommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityViewModel controller = Get.put(CommunityViewModel());

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
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.refreshPosts();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with shimmer effect
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6D83F2).withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Community',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Share, support, and grow together',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Chat Icon Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigateToChat(context),
                                customBorder: const CircleBorder(),
                                child: Ink(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Shimmer overlay
                      _shimmerOverlay(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  _buildSearchBar(controller),

                  const SizedBox(height: 16),

                  // Main content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show support groups if user has joined any
                      if (_getJoinedGroups().isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BrandGradientText(
                              'My Groups',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.to(() => const ChatRoomsView());
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Color(0xFF6D83F2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _getJoinedGroups().length,
                            itemBuilder: (context, index) {
                              final group = _getJoinedGroups()[index];
                              return GroupCard(
                                title: group['title']!,
                                icon: group['icon'] as IconData,
                                color: group['color'] as Color,
                                memberCount: group['memberCount']!,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      BrandGradientText(
                        'Recent Posts',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (controller.posts.isEmpty) {
                          return const EmptyState();
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.posts.length,
                          itemBuilder: (context, index) {
                            final post = controller.posts[index];
                            return PostCard(
                              controller: controller,
                              post: post,
                              index: index,
                              onShowComments: _showCommentsDialog,
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: BrandUI.brandAccent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D83F2).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.to(
                  () => const CreatePostView(),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Create Post',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  // Group card rendering moved to `widgets/group_card.dart` as `GroupCard`.

  // Empty state, post card and interaction button are implemented as
  // separate widgets under `lib/views/community/widgets/`.

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
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 24,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Comments list (real-time)
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: controller.commentsStream(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data ?? const <CommentModel>[];
                    if (comments.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar (Instagram-style)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Name + comment text stacked
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF111827),
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              '${StringUtils.formatUserDisplayName(c.userId)}  ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(text: c.content),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _formatTime(c.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Reply',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Like icon placeholder for comments
                            Icon(
                              Icons.favorite_border,
                              size: 16,
                              color: Colors.grey[600],
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
                  border: Border.all(color: Colors.grey[300]!),
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
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
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

  // Time formatting moved to PostCard widget if needed.

  // Navigate to chat rooms
  void _navigateToChat(BuildContext context) {
    Get.to(
      () => const ChatRoomsView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  // Shimmer overlay for header
  Widget _shimmerOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Shimmer(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.00),
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.00),
              ],
              stops: const [0.35, 0.50, 0.65],
            ),
            period: const Duration(seconds: 4),
            direction: ShimmerDirection.ltr,
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(CommunityViewModel controller) {
    return GestureDetector(
      onTap: () {
        // Navigate to search results page with smooth transition
        Get.to(
          () => const SearchResultsView(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6D83F2).withOpacity(0.08),
              const Color(0xFF00C6FF).withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6D83F2).withOpacity(0.2),
            width: 1,
          ),
        ),
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
                Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search users, posts...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⌘K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get user's joined groups
  // TODO: Replace with actual data from user's joined groups
  List<Map<String, dynamic>> _getJoinedGroups() {
    // Return example joined groups - replace with actual user data
    return [
      {
        'title': 'Anxiety Support',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFF6366F1),
        'memberCount': '2.3k members',
      },
      {
        'title': 'General Chat',
        'icon': Icons.chat_outlined,
        'color': const Color(0xFF10B981),
        'memberCount': '3.1k members',
      },
    ];
  }
}
