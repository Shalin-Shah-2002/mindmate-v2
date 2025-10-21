import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindmate/viewmodels/community_viewmodel.dart';

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient accent
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6D83F2).withOpacity(0.05),
                  const Color(0xFF00C6FF).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // Avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: post.profilePhotoUrl.isNotEmpty && !post.isAnonymous
                        ? NetworkImage(post.profilePhotoUrl)
                        : null,
                    child: (post.isAnonymous || post.profilePhotoUrl.isEmpty)
                        ? Icon(
                            post.isAnonymous ? Icons.visibility_off : Icons.person,
                            size: 20,
                            color: const Color(0xFF6D83F2),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                        ).createShader(bounds),
                        child: Text(
                          post.isAnonymous
                              ? 'Anonymous'
                              : (post.authorName.isNotEmpty
                                    ? post.authorName
                                    : (post.userName.isNotEmpty
                                          ? post.userName
                                          : 'User')),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    iconSize: 20,
                    color: const Color(0xFF6D83F2),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF9FBFF),
                                Color(0xFFF7FFFB),
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                                  ),
                                  title: const Text(
                                    'Report Post',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text('Report inappropriate content'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    controller.reportPost(post.id, 'Inappropriate content');
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Interaction buttons with gradient effects
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                _buildGradientButton(
                  icon: post.isLiked == true ? Icons.favorite : Icons.favorite_border,
                  label: post.likesCount.toString(),
                  isActive: post.isLiked == true,
                  activeColor: Colors.red,
                  onTap: () => controller.toggleLike(post.id, index),
                ),
                const SizedBox(width: 8),
                _buildGradientButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: post.commentsCount.toString(),
                  isActive: false,
                  activeColor: const Color(0xFF6D83F2),
                  onTap: () => onShowComments?.call(controller, post, index),
                ),
                const SizedBox(width: 8),
                _buildGradientButton(
                  icon: Icons.share_rounded,
                  label: post.sharesCount.toString(),
                  isActive: false,
                  activeColor: const Color(0xFF10B981),
                  onTap: () {
                    Get.snackbar(
                      'Coming Soon',
                      'Share functionality will be available soon!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                const Spacer(),
                if (post.likesCount + post.commentsCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D83F2).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${post.likesCount + post.commentsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive 
                ? activeColor.withOpacity(0.1) 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive 
                  ? activeColor.withOpacity(0.3) 
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? activeColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
