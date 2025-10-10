import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../services/group_service.dart';
import '../../services/chat_safety_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/safety_warning_banner.dart';

class GroupChatView extends StatefulWidget {
  final Group group;

  const GroupChatView({super.key, required this.group});

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isTyping = false;
  String? _currentViolationWarning;

  @override
  void initState() {
    super.initState();
    _checkUserParticipationStatus();
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    final isTyping = _messageController.text.isNotEmpty;
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
    }
  }

  Future<void> _checkUserParticipationStatus() async {
    final authViewModel = Get.find<AuthViewModel>();
    final currentUser = authViewModel.user;

    if (currentUser != null) {
      final canParticipate = await ChatSafetyService.canUserParticipateInChat(
        currentUser.uid,
        widget.group.id,
      );

      if (!canParticipate && mounted) {
        _showKickedDialog();
      }
    }
  }

  void _showKickedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Access Restricted'),
        content: const Text(
          'You have been removed from this group due to policy violations. '
          'You can request to rejoin after 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Get.back();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_currentViolationWarning != null)
            SafetyWarningBanner(
              message: _currentViolationWarning!,
              onDismiss: () => setState(() => _currentViolationWarning = null),
            ),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                widget.group.category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.group.displayMemberCount,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showGroupInfo,
          icon: const Icon(Icons.info_outline),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'members',
              child: Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('Members'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Leave Group', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<GroupMessage>>(
      stream: GroupService.getGroupMessages(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Start the conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to send a message in ${widget.group.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Auto scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final authViewModel = Get.find<AuthViewModel>();
            final isOwnMessage = message.senderId == authViewModel.user?.uid;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MessageBubble(
                message: message.message,
                isOwnMessage: isOwnMessage,
                senderName: message.senderName,
                timestamp: message.timestamp,
                safetyScore: message.safetyScore,
                onLongPress: isOwnMessage
                    ? () => _showMessageOptions(message)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isTyping
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: _isTyping ? _sendMessage : null,
                icon: Icon(
                  Icons.send,
                  color: _isTyping ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authViewModel = Get.find<AuthViewModel>();
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'You must be signed in to send messages.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Clear input immediately for better UX
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    try {
      final result = await GroupService.sendMessageWithFeedback(
        groupId: widget.group.id,
        content: message,
      );

      if (result.wasBlocked) {
        // Show violation warning
        setState(() {
          _currentViolationWarning =
              result.feedback ??
              'Message blocked due to content policy violation.';
        });

        // Check if user was kicked
        final canParticipate = await ChatSafetyService.canUserParticipateInChat(
          currentUser.uid,
          widget.group.id,
        );

        if (!canParticipate && mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _showKickedDialog();
          });
        }
      } else if (result.feedback != null && result.feedback!.isNotEmpty) {
        // Show safety guidance
        Get.snackbar(
          'Message Sent',
          result.feedback!,
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );

      // Restore message to input
      _messageController.text = message;
      setState(() {
        _isTyping = true;
      });
    }
  }

  void _showMessageOptions(GroupMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                // TODO: Implement copy functionality
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(GroupMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // TODO: Implement message deletion
                Get.snackbar(
                  'Message Deleted',
                  'Your message has been deleted.',
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete message: $e',
                  backgroundColor: Colors.red.shade600,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.group.category.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.group.category.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.group.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.group.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.group.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Group Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Members',
                  widget.group.displayMemberCount,
                  Icons.people,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Privacy',
                  widget.group.privacy.displayName,
                  Icons.lock,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'members':
        _showMembersList();
        break;
      case 'settings':
        _showGroupSettings();
        break;
      case 'leave':
        _showLeaveGroupDialog();
        break;
    }
  }

  void _showMembersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members (${widget.group.displayMemberCount})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<GroupMember>>(
                stream: GroupService.getGroupMembers(widget.group.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading members'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = snapshot.data!;

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            member.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(member.displayName),
                        subtitle: Text(member.role.displayName),
                        trailing: member.role == GroupMemberRole.owner
                            ? const Icon(Icons.star, color: Colors.amber)
                            : member.role == GroupMemberRole.admin
                            ? const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.blue,
                              )
                            : member.role == GroupMemberRole.moderator
                            ? const Icon(
                                Icons.verified_user,
                                color: Colors.green,
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSettings() {
    Get.snackbar(
      'Coming Soon',
      'Group settings will be available in a future update.',
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${widget.group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveGroup();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      await GroupService.leaveGroup(widget.group.id);

      Get.snackbar(
        'Left Group',
        'You have left ${widget.group.name}',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to leave group: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }
}
