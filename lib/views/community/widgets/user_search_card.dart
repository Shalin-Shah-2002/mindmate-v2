import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/user_model.dart';
import '../../../services/private_chat_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../chat/private_chat_room_view.dart';

class UserSearchCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final bool showMessageButton;

  const UserSearchCard({
    super.key,
    required this.user,
    this.onTap,
    this.showMessageButton = true,
  });

  Future<void> _startDirectMessage(BuildContext context) async {
    try {
      final authController = Get.find<AuthViewModel>();
      if (authController.userModel == null) return;

      // Check if users can chat
      final permissionResult = await PrivateChatService.canUsersChatWithReason(
        authController.userModel!.id,
        user.id,
      );

      if (!permissionResult.allowed) {
        Get.snackbar(
          'Cannot Message',
          permissionResult.reason ?? 'Direct messaging is not available',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Get or create conversation
      final conversation = await PrivateChatService.createOrGetConversation(
        user.id,
      );

      if (conversation != null) {
        // Navigate to private chat room
        Get.to(
          () => PrivateChatRoomView(
            conversationId: conversation.id,
            otherUserId: user.id,
            otherUser: user,
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to start conversation',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error starting DM: $e');
      Get.snackbar(
        'Error',
        'Failed to start direct message',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl.isNotEmpty
              ? NetworkImage(user.photoUrl)
              : null,
          child: user.photoUrl.isEmpty
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                )
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: user.bio.isNotEmpty
            ? Text(
                user.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              )
            : user.isPrivate
            ? Text(
                'Private Account',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            : null,
        trailing: showMessageButton
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _startDirectMessage(context),
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Message ${user.name}',
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
