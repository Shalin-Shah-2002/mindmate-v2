import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/private_conversation.dart';
import '../../models/user_model.dart';
import '../../services/private_chat_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'private_chat_room_view.dart';

class PrivateChatListView extends StatefulWidget {
  const PrivateChatListView({super.key});

  @override
  State<PrivateChatListView> createState() => _PrivateChatListViewState();
}

class _PrivateChatListViewState extends State<PrivateChatListView> {
  late final AuthViewModel _authController;

  @override
  void initState() {
    super.initState();

    // Initialize AuthViewModel if not already available
    try {
      _authController = Get.find<AuthViewModel>();
    } catch (e) {
      _authController = Get.put(AuthViewModel());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Unread count badge
          StreamBuilder<int>(
            stream: PrivateChatService.getTotalUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<PrivateConversation>>(
        stream: PrivateChatService.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading conversations',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by rebuilding the stream
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  currentUserId: _authController.userModel?.id ?? '',
                  onTap: () => _openConversation(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation by visiting a user\'s profile and tapping the Message button.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.people),
              label: const Text(
                'Explore Community',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(PrivateConversation conversation) {
    // Navigate to private chat room
    final otherUserId = conversation.getOtherParticipantId(
      _authController.userModel?.id ?? '',
    );

    Get.to(
      () => PrivateChatRoomView(
        conversationId: conversation.id,
        otherUserId: otherUserId,
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final PrivateConversation conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    return FutureBuilder<UserModel?>(
      future: _getOtherUser(otherUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return _buildLoadingTile(context);
        }

        final otherUser = userSnapshot.data!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: hasUnread ? 4 : 1,
          shadowColor: hasUnread
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasUnread
                ? BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  )
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: otherUser.photoUrl.isNotEmpty
                      ? NetworkImage(otherUser.photoUrl)
                      : null,
                  child: otherUser.photoUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        )
                      : null,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              otherUser.name,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: conversation.lastMessage.isNotEmpty
                ? Text(
                    conversation.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: hasUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  )
                : Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }

  Widget _buildLoadingTile(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            size: 24,
          ),
        ),
        title: Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        subtitle: Container(
          height: 12,
          width: 200,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        trailing: Container(
          height: 12,
          width: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Future<UserModel?> _getOtherUser(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!, userDoc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // This week - show day name
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
