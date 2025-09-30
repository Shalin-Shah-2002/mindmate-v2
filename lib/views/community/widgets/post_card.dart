import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindmate/viewmodels/community_viewmodel.dart';
import 'interaction_button.dart';

class PostCard extends StatelessWidget {
  final CommunityViewModel controller;
  final dynamic post;
  final int index;
  final void Function(CommunityViewModel controller, dynamic post, int index)?
  onShowComments;

  const PostCard({
    super.key,
    required this.controller,
    required this.post,
    required this.index,
    this.onShowComments,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(post.id),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: post.isAnonymous
                        ? Icon(
                            Icons.visibility_off,
                            size: 24,
                            color: Theme.of(context).primaryColor,
                          )
                        : (post.profilePhotoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    post.profilePhotoUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.person,
                                          size: 24,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Theme.of(context).primaryColor,
                                )),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.isAnonymous
                            ? 'Anonymous User'
                            : (post.authorName.isNotEmpty
                                  ? post.authorName
                                  : (post.userName.isNotEmpty
                                        ? post.userName
                                        : 'Community Member')),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Colors.red[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Report Post'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') {
                      controller.reportPost(post.id, 'Inappropriate content');
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                InteractionButton(
                  icon: post.isLiked == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  count: post.likesCount,
                  color: post.isLiked == true ? Colors.red : Colors.grey,
                  onTap: () => controller.toggleLike(post.id, index),
                ),
                const SizedBox(width: 24),
                InteractionButton(
                  icon: Icons.chat_bubble_outline,
                  count: post.commentsCount,
                  color: Colors.blue,
                  onTap: () => onShowComments?.call(controller, post, index),
                ),
                const SizedBox(width: 24),
                InteractionButton(
                  icon: Icons.share_outlined,
                  count: post.sharesCount,
                  color: Colors.green,
                  onTap: () {
                    Get.snackbar(
                      'Coming Soon',
                      'Share functionality will be available soon!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    '${post.likesCount + post.commentsCount} interactions',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
