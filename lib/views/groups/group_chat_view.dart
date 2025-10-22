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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSafetyBanner(),
          if (_currentViolationWarning != null)
            SafetyWarningBanner(
              message: _currentViolationWarning!,
              onDismiss: () => setState(() => _currentViolationWarning = null),
            ),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: _buildEmergencyFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.group.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '24/7 Professional Support',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showGroupInfo,
          icon: const Icon(Icons.healing),
          tooltip: 'Support Resources',
        ),
        IconButton(
          onPressed: _showSafetyMenu,
          icon: const Icon(Icons.shield),
          tooltip: 'Safety Tools',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
            ),
          ),
        ),
      ),
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

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.blue.shade100],
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Safe Space: All messages are monitored by AI for safety. Professional help is available 24/7.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyFAB() {
    return FloatingActionButton.extended(
      onPressed: _triggerEmergencyMode,
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency),
      label: const Text('Emergency'),
    );
  }

  void _triggerEmergencyMode() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Immediate Help Available'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'re here to help you through this crisis. You have several options for immediate support:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '• Call Tele-MANAS: 14416 or 1-800-891-4416 (24/7)\n'
              '• Call 112 if you\'re in immediate danger\n'
              '• Continue chatting here with AI support',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _callEmergencyNumber('14416'),
            child: Text(
              'Call Tele-MANAS 14416',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continue Chat'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _callEmergencyNumber(String number) {
    Get.snackbar(
      'Emergency Call',
      'Calling $number...',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSafetyMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Safety & Support Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSafetyMenuItem(
              'Emergency Hotlines',
              'Quick access to crisis support',
              Icons.phone,
              _showGroupInfo,
            ),
            _buildSafetyMenuItem(
              'Coping Strategies',
              'Immediate relief techniques',
              Icons.self_improvement,
              _showCopingStrategies,
            ),
            _buildSafetyMenuItem(
              'Safety Plan',
              'Create your personal safety plan',
              Icons.assignment,
              _showSafetyPlan,
            ),
            _buildSafetyMenuItem(
              'Report Concern',
              'Report inappropriate content',
              Icons.report,
              _showReportDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyMenuItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showCopingStrategies() {
    Get.back(); // Close bottom sheet
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Immediate Coping Strategies'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Try these techniques right now:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Take 5 deep breaths (in for 4, hold for 4, out for 6)'),
              Text(
                '• Name 5 things you can see, 4 you can touch, 3 you can hear',
              ),
              Text('• Hold an ice cube or splash cold water on your face'),
              Text('• Listen to calming music or nature sounds'),
              Text('• Call a trusted friend or family member'),
              Text('• Write down your feelings in a journal'),
              Text('• Go for a walk or do gentle stretching'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showSafetyPlan() {
    Get.back(); // Close bottom sheet
    Get.snackbar(
      'Safety Plan',
      'Safety plan feature coming soon. For now, please save important numbers in your phone.',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void _showReportDialog() {
    Get.back(); // Close bottom sheet
    Get.snackbar(
      'Report Feature',
      'Report functionality will be available soon. For immediate help, use emergency options.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
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
