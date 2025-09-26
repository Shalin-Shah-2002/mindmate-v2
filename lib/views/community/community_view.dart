import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../models/post_model.dart';
import 'widgets/group_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/post_card.dart';
import '../search/search_results_view.dart';

class CommunityView extends StatelessWidget {
  const CommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityViewModel controller = Get.put(CommunityViewModel());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.refreshPosts();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Share, support, and grow together',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(controller),

                const SizedBox(height: 16),

                // Main content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support Groups',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          GroupCard(
                            title: 'Anxiety Support',
                            icon: Icons.psychology_outlined,
                            color: Color(0xFF6366F1),
                            memberCount: '2.3k members',
                          ),
                          GroupCard(
                            title: 'Depression Help',
                            icon: Icons.favorite_outline,
                            color: Color(0xFFEC4899),
                            memberCount: '1.8k members',
                          ),
                          GroupCard(
                            title: 'Exam Stress',
                            icon: Icons.school_outlined,
                            color: Color(0xFFF59E0B),
                            memberCount: '1.2k members',
                          ),
                          GroupCard(
                            title: 'General Chat',
                            icon: Icons.chat_outlined,
                            color: Color(0xFF10B981),
                            memberCount: '3.1k members',
                          ),
                          GroupCard(
                            title: 'Self Care',
                            icon: Icons.spa_outlined,
                            color: Color(0xFF8B5CF6),
                            memberCount: '956 members',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Posts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (controller.posts.isEmpty) {
                        return EmptyState(
                          onCreate: () => _showCreatePostDialog(controller),
                        );
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

  void _showCreatePostDialog(CommunityViewModel controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(Get.context!).primaryColor,
                      Theme.of(Get.context!).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.create, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content input
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Share your thoughts, feelings, or experiences...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) => controller.updateContent(value),
                ),
              ),
              const SizedBox(height: 20),

              // Mood selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.availableMoods.take(6).map((mood) {
                        final isSelected =
                            controller.selectedMood.value == mood;
                        return GestureDetector(
                          onTap: () =>
                              controller.selectMood(isSelected ? '' : mood),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(Get.context!).primaryColor
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(Get.context!).primaryColor
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              mood,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Anonymous toggle
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isAnonymous.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(Get.context!).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Post Anonymously',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              controller.isAnonymous.value
                                  ? 'Your identity will be hidden'
                                  : 'Others will see your profile',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.isAnonymous.value,
                        onChanged: (value) => controller.toggleAnonymous(),
                        activeThumbColor: Theme.of(Get.context!).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        controller.clearPostForm();
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isCreatingPost.value
                            ? null
                            : () => controller.createPost(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(Get.context!).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: controller.isCreatingPost.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Share Post',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                                              'User ${c.userId.substring(0, 8)}  ',
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: Theme.of(Get.context!).primaryColor),
              const SizedBox(width: 12),
              Text(
                'Search users by name...',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
