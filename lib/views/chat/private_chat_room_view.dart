import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/private_conversation.dart';
import '../../models/user_model.dart';
import '../../models/user_report.dart';
import '../../services/private_chat_service.dart';
import '../../services/user_report_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../profile/user_profile_view.dart';

class PrivateChatRoomView extends StatefulWidget {
  final String conversationId;
  final String? otherUserId;
  final UserModel? otherUser;

  const PrivateChatRoomView({
    super.key,
    required this.conversationId,
    this.otherUserId,
    this.otherUser,
  });

  @override
  State<PrivateChatRoomView> createState() => _PrivateChatRoomViewState();
}

class _PrivateChatRoomViewState extends State<PrivateChatRoomView> {
  late final AuthViewModel _authController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  StreamSubscription<List<DirectMessage>>? _messagesSubscription;
  final RxList<DirectMessage> messages = <DirectMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  UserModel? otherUser;
  PrivateConversation? conversation;

  @override
  void initState() {
    super.initState();

    // Initialize AuthViewModel
    try {
      _authController = Get.find<AuthViewModel>();
    } catch (e) {
      _authController = Get.put(AuthViewModel());
    }

    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    isLoading.value = true;

    try {
      // Load other user info if not provided
      if (widget.otherUser != null) {
        otherUser = widget.otherUser;
      } else if (widget.otherUserId != null) {
        await _loadOtherUser(widget.otherUserId!);
      }

      // Load conversation info
      await _loadConversation();

      // Start listening to messages
      _listenToMessages();

      // Mark messages as read
      await PrivateChatService.markMessagesAsRead(widget.conversationId);
    } catch (e) {
      print('Error initializing chat: $e');
      Get.snackbar(
        'Error',
        'Failed to load conversation',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadOtherUser(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        otherUser = UserModel.fromMap(userDoc.data()!, userDoc.id);
      }
    } catch (e) {
      print('Error loading other user: $e');
    }
  }

  Future<void> _loadConversation() async {
    try {
      final conversationDoc = await FirebaseFirestore.instance
          .collection('private_conversations')
          .doc(widget.conversationId)
          .get();

      if (conversationDoc.exists) {
        conversation = PrivateConversation.fromFirestore(conversationDoc);
      }
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  void _listenToMessages() {
    _messagesSubscription =
        PrivateChatService.getMessagesStream(widget.conversationId).listen((
          messageList,
        ) {
          messages.value = messageList;

          // Scroll to bottom when new messages arrive
          if (_scrollController.hasClients && messageList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || isSending.value) return;

    try {
      isSending.value = true;
      _messageController.clear();

      final result = await PrivateChatService.sendMessageWithResult(
        conversationId: widget.conversationId,
        content: content,
      );

      if (!result.success) {
        Get.snackbar(
          'Message Failed',
          result.reason ?? 'Unable to send message. Please try again.',
          backgroundColor: Theme.of(Get.context!).colorScheme.error,
          colorText: Theme.of(Get.context!).colorScheme.onError,
        );

        // Restore message to text field
        _messageController.text = content;
      }
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar(
        'Error',
        'Failed to send message',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
      );

      // Restore message to text field
      _messageController.text = content;
    } finally {
      isSending.value = false;
    }

    // Mark messages as read after sending
    await PrivateChatService.markMessagesAsRead(widget.conversationId);

    // Keep keyboard open by re-requesting focus on the input field
    _requestInputFocus();
  }

  void _requestInputFocus() {
    if (mounted) {
      FocusScope.of(context).requestFocus(_inputFocusNode);
    }
  }

  void _showUserProfile() {
    if (otherUser != null) {
      Get.to(() => UserProfileView(user: otherUser!));
    }
  }

  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    Get.context!,
                  ).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Options
              _buildBottomSheetOption(
                icon: Icons.person,
                title: 'View Profile',
                onTap: () {
                  Get.back();
                  _showUserProfile();
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.report,
                title: 'Report User',
                isDestructive: true,
                onTap: () {
                  Get.back();
                  _showReportDialog();
                },
              ),

              _buildBottomSheetOption(
                icon: Icons.block,
                title: 'Block User',
                isDestructive: true,
                onTap: () {
                  Get.back();
                  _showBlockConfirmation();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Theme.of(Get.context!).colorScheme.error
            : Theme.of(Get.context!).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Theme.of(Get.context!).colorScheme.error
              : Theme.of(Get.context!).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showReportDialog() {
    Get.dialog(
      _ReportUserDialog(
        reportedUser: otherUser!,
        onReport: (category, description) async {
          final success = await UserReportService.reportUser(
            reportedUserId: otherUser!.id,
            category: category,
            description: description,
          );

          if (success) {
            Get.back();
            Get.snackbar(
              'Report Submitted',
              'Thank you for your report. Our team will review it shortly.',
              backgroundColor: Theme.of(Get.context!).colorScheme.primary,
              colorText: Theme.of(Get.context!).colorScheme.onPrimary,
            );
          } else {
            Get.snackbar(
              'Error',
              'Failed to submit report. Please try again.',
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
              colorText: Theme.of(Get.context!).colorScheme.onError,
            );
          }
        },
      ),
    );
  }

  void _showBlockConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Block ${otherUser?.name ?? 'User'}?',
          style: TextStyle(
            color: Theme.of(Get.context!).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You will no longer receive messages from this user, and they will not be able to send you messages.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _blockUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
              foregroundColor: Theme.of(Get.context!).colorScheme.onError,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    if (otherUser == null) return;

    try {
      final success = await PrivateChatService.blockUser(otherUser!.id, null);

      if (success) {
        Get.back(); // Return to chat list
        Get.snackbar(
          'User Blocked',
          '${otherUser!.name} has been blocked',
          backgroundColor: Theme.of(Get.context!).colorScheme.primary,
          colorText: Theme.of(Get.context!).colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to block user. Please try again.',
          backgroundColor: Theme.of(Get.context!).colorScheme.error,
          colorText: Theme.of(Get.context!).colorScheme.onError,
        );
      }
    } catch (e) {
      print('Error blocking user: $e');
      Get.snackbar(
        'Error',
        'Failed to block user',
        backgroundColor: Theme.of(Get.context!).colorScheme.error,
        colorText: Theme.of(Get.context!).colorScheme.onError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showUserProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'avatar_${otherUser?.id ?? 'unknown'}',
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: otherUser?.photoUrl.isNotEmpty == true
                          ? NetworkImage(otherUser!.photoUrl)
                          : null,
                      child: otherUser?.photoUrl.isEmpty == true
                          ? Text(
                              otherUser?.name.isNotEmpty == true
                                  ? otherUser!.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // Online indicator (placeholder)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
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
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otherUser?.name ?? 'Loading...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Online', // Placeholder for online status
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement voice call
              Get.snackbar(
                'Coming Soon',
                'Voice call feature will be available soon',
                backgroundColor: Theme.of(context).colorScheme.primary,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.phone),
            tooltip: 'Voice call',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement video call
              Get.snackbar(
                'Coming Soon',
                'Video call feature will be available soon',
                backgroundColor: Theme.of(context).colorScheme.primary,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.videocam),
            tooltip: 'Video call',
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        if (isLoading.value) {
          return _buildLoadingState(context);
        }

        return Column(
          children: [
            // Messages list
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyMessages(context)
                  : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.3),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe =
                              message.senderId == _authController.userModel?.id;
                          final showDateHeader = _shouldShowDateHeader(index);
                          final showAvatar = _shouldShowAvatar(index);

                          return AnimatedContainer(
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            curve: Curves.easeOutCubic,
                            child: Column(
                              children: [
                                if (showDateHeader)
                                  _buildDateHeader(message.timestamp),
                                _buildMessageBubble(message, isMe, showAvatar),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Typing indicator placeholder
            _buildTypingIndicator(),

            // Message input
            _buildMessageInput(context),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyMessages(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Send a message to ${otherUser?.name ?? 'this user'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading conversation...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    // Placeholder for typing indicator
    return Container(
      height: 0, // Hide for now, will implement later
      child: const SizedBox.shrink(),
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == messages.length - 1) {
      return true; // Always show for oldest message
    }

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    final nextDate = DateTime(
      nextMessage.timestamp.year,
      nextMessage.timestamp.month,
      nextMessage.timestamp.day,
    );

    return currentDate != nextDate;
  }

  bool _shouldShowAvatar(int index) {
    if (index == 0) return true; // Always show for most recent message

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    // Show avatar if sender changed or if there's a time gap
    if (currentMessage.senderId != previousMessage.senderId) return true;

    final timeDiff = previousMessage.timestamp.difference(
      currentMessage.timestamp,
    );
    return timeDiff.inMinutes >
        5; // Show avatar if messages are more than 5 minutes apart
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    DirectMessage message,
    bool isMe,
    bool showAvatar,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isMe ? 48 : 16,
        2,
        isMe ? 16 : 48,
        showAvatar ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(
                Get.context!,
              ).colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: otherUser?.photoUrl.isNotEmpty == true
                  ? NetworkImage(otherUser!.photoUrl)
                  : null,
              child: otherUser?.photoUrl.isEmpty == true
                  ? Text(
                      otherUser?.name.isNotEmpty == true
                          ? otherUser!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(Get.context!).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40), // Space for avatar
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                          colors: [
                            Theme.of(Get.context!).colorScheme.primary,
                            Theme.of(
                              Get.context!,
                            ).colorScheme.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe
                      ? null
                      : Theme.of(
                          Get.context!,
                        ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : (showAvatar
                              ? const Radius.circular(4)
                              : const Radius.circular(20)),
                    bottomRight: isMe
                        ? (showAvatar
                              ? const Radius.circular(4)
                              : const Radius.circular(20))
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : Theme.of(
                                Get.context!,
                              ).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.8)
                                : Theme.of(Get.context!)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              key: ValueKey(message.isRead),
                              size: 16,
                              color: message.isRead
                                  ? Colors.blue.shade200
                                  : Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(DirectMessage message) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    Get.context!,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Message'),
                onTap: () {
                  Get.back();
                  // TODO: Implement copy functionality
                  Get.snackbar(
                    'Copied',
                    'Message copied to clipboard',
                    backgroundColor: Theme.of(Get.context!).colorScheme.primary,
                    colorText: Colors.white,
                  );
                },
              ),

              if (message.senderId == _authController.userModel?.id) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Get.back();
                    // TODO: Implement edit functionality
                    Get.snackbar(
                      'Coming Soon',
                      'Edit message functionality will be available soon',
                      backgroundColor: Theme.of(
                        Get.context!,
                      ).colorScheme.primary,
                      colorText: Colors.white,
                    );
                  },
                ),

                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Theme.of(Get.context!).colorScheme.error,
                  ),
                  title: Text(
                    'Delete Message',
                    style: TextStyle(
                      color: Theme.of(Get.context!).colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    _confirmDeleteMessage(message);
                  },
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(DirectMessage message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implement delete message functionality
              Get.snackbar(
                'Coming Soon',
                'Delete message functionality will be available soon',
                backgroundColor: Theme.of(Get.context!).colorScheme.primary,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Implement attachment functionality
                  Get.snackbar(
                    'Coming Soon',
                    'Attachment feature will be available soon',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    colorText: Colors.white,
                  );
                },
                icon: Icon(
                  Icons.attach_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Attach file',
              ),
            ),

            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    _sendMessage();
                    _requestInputFocus();
                  },
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        // TODO: Implement emoji picker
                        Get.snackbar(
                          'Coming Soon',
                          'Emoji picker will be available soon',
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          colorText: Colors.white,
                        );
                      },
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      tooltip: 'Add emoji',
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: isSending.value ? null : _sendMessage,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSending.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            key: ValueKey('send'),
                          ),
                  ),
                  tooltip: 'Send message',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}

// Report dialog (reusing the same one from user profile)
class _ReportUserDialog extends StatefulWidget {
  final UserModel reportedUser;
  final Function(ReportCategory, String) onReport;

  const _ReportUserDialog({required this.reportedUser, required this.onReport});

  @override
  State<_ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<_ReportUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ReportCategory _selectedCategory = ReportCategory.spam;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Report ${widget.reportedUser.name}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this user?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Category Selection
              DropdownButtonFormField<ReportCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Report Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: ReportCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Please provide more details about the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 4,
                maxLength: 500,
              ),

              const SizedBox(height: 8),

              // Warning text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'False reports may result in restrictions on your account.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
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
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onReport(
        _selectedCategory,
        _descriptionController.text.trim(),
      );
    } catch (e) {
      print('Error submitting report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
