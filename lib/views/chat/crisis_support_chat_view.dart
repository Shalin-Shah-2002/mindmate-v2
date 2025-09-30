import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/chat_safety_service.dart';

import '../../viewmodels/auth_viewmodel.dart';

class CrisisSupportChatView extends StatefulWidget {
  final ChatRoom room;

  const CrisisSupportChatView({super.key, required this.room});

  @override
  State<CrisisSupportChatView> createState() => _CrisisSupportChatViewState();
}

class _CrisisSupportChatViewState extends State<CrisisSupportChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEmergencyMode = false;
  bool _showCrisisResources = false;

  @override
  void initState() {
    super.initState();
    _checkUserSafetyStatus();
  }

  void _checkUserSafetyStatus() async {
    final authViewModel = Get.find<AuthViewModel>();
    if (authViewModel.user != null) {
      final canParticipate = await ChatSafetyService.canUserParticipateInChat(
        authViewModel.user!.uid,
        widget.room.id,
      );

      if (!canParticipate) {
        _showSafetyRestrictionsDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildCrisisAppBar(),
      body: Column(
        children: [
          _buildSafetyBanner(),
          if (_showCrisisResources) _buildCrisisResourcesPanel(),
          Expanded(child: _buildChatContent()),
          _buildCrisisInputSection(),
        ],
      ),
      floatingActionButton: _buildEmergencyFAB(),
    );
  }

  PreferredSizeWidget _buildCrisisAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crisis Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          onPressed: () => setState(() {
            _showCrisisResources = !_showCrisisResources;
          }),
          icon: const Icon(Icons.healing),
          tooltip: 'Crisis Resources',
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

  Widget _buildCrisisResourcesPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Immediate Help Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEmergencyButton(
            'Call Tele-MANAS (India)',
            '14416',
            Icons.phone,
            Colors.red,
            () => _callEmergencyNumber('14416'),
          ),
          const SizedBox(height: 8),
          _buildEmergencyButton(
            'Alternate Helpline',
            '1-800-891-4416',
            Icons.support_agent,
            Colors.orange,
            () => _callEmergencyNumber('18008914416'),
          ),
          const SizedBox(height: 8),
          _buildEmergencyButton(
            'Emergency Services',
            'Call 112',
            Icons.local_hospital,
            Colors.red.shade700,
            () => _callEmergencyNumber('112'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent() {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.getChatMessages(widget.room.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Unable to load messages',
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

        final authViewModel = Get.find<AuthViewModel>();
        final currentUserId = authViewModel.user?.uid;
        // UI-level visibility: show approved messages to everyone;
        // show sender their own unapproved messages so they appear in real-time
        final messages = snapshot.data!
            .where(
              (m) =>
                  m.isVisible ||
                  m.senderId == currentUserId ||
                  m.type == MessageType.system,
            )
            .toList();

        if (messages.isEmpty) {
          return _buildWelcomeMessage();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.favorite,
                size: 48,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Crisis Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re not alone. Our trained professionals and AI-powered safety systems are here to help you through this difficult time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Your Safety is Our Priority',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Messages are monitored for safety\n'
                    '• Immediate help is available if needed\n'
                    '• Professional counselors are standing by\n'
                    '• Your privacy is protected',
                    style: TextStyle(color: Colors.green.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final authViewModel = Get.find<AuthViewModel>();
    final isCurrentUser = message.senderId == authViewModel.user?.uid;
    final isSystemMessage = message.type == MessageType.system;
    final isPendingModeration = !message.isVisible && isCurrentUser;

    if (isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                message.senderId.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue.shade500 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white70
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (message.safetyScore < 0.8) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 12,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Content reviewed for safety',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isPendingModeration) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_top,
                            size: 12,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pending moderation – only you can see this',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCrisisInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isEmergencyMode) _buildEmergencyModeBar(),
          _buildSafetyPrompts(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmergencyModeBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade600),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Emergency Mode Active - Professional help is being contacted',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _isEmergencyMode = false),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyPrompts() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickPrompt(
              'I need someone to talk to',
              Icons.chat_bubble_outline,
            ),
            const SizedBox(width: 8),
            _buildQuickPrompt('I\'m feeling overwhelmed', Icons.psychology),
            const SizedBox(width: 8),
            _buildQuickPrompt(
              'I need coping strategies',
              Icons.self_improvement,
            ),
            const SizedBox(width: 8),
            _buildQuickPrompt(
              'I\'m having a crisis',
              Icons.emergency,
              isEmergency: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompt(
    String text,
    IconData icon, {
    bool isEmergency = false,
  }) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        if (isEmergency) {
          _handleEmergencyPrompt();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEmergency ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmergency ? Colors.red.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isEmergency ? Colors.red.shade600 : Colors.blue.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isEmergency ? Colors.red.shade700 : Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Share what\'s on your mind safely...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                maxLines: null,
                onChanged: _onMessageChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade500,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              padding: const EdgeInsets.all(12),
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

  void _onMessageChanged(String text) {
    // Auto-detect crisis language and offer immediate help
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'end it all',
      'can\'t go on',
      'want to die',
    ];

    if (crisisKeywords.any((keyword) => text.toLowerCase().contains(keyword))) {
      if (!_isEmergencyMode) {
        _handleEmergencyPrompt();
      }
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      final result = await ChatService.sendMessageWithFeedback(
        roomId: widget.room.id,
        content: content,
        type: MessageType.text,
      );

      if (result.sent) {
        _scrollToBottom();
      } else {
        final msg =
            result.violationMessage ?? 'Message blocked for safety reasons.';
        Get.snackbar(
          'Message Not Sent',
          msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        if (result.kicked && mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleEmergencyPrompt() {
    setState(() => _isEmergencyMode = true);
    _showCrisisInterventionDialog();
  }

  void _triggerEmergencyMode() {
    setState(() {
      _isEmergencyMode = true;
      _showCrisisResources = true;
    });
    _showCrisisInterventionDialog();
  }

  void _showCrisisInterventionDialog() {
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

  void _showSafetyRestrictionsDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shield, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Safety Check'),
          ],
        ),
        content: const Text(
          'For your safety, some chat features may be limited. Our AI monitoring system will provide additional support during your session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('I Understand'),
          ),
        ],
      ),
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
              () =>
                  setState(() => _showCrisisResources = !_showCrisisResources),
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

  void _callEmergencyNumber(String number) {
    // In a real app, you would use url_launcher to make phone calls
    Get.snackbar(
      'Emergency Call',
      'Calling $number...',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Removed text support method; we use Tele-MANAS numbers directly.

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

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
