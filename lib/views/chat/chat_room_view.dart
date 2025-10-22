import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../models/user_chat_profile.dart';
import '../../models/user_trust_level.dart';
import '../../services/chat_service.dart';
import '../../services/chat_safety_service.dart';
import '../../services/chat_trust_service.dart';
import '../../services/crisis_intervention_service.dart';
import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

enum MessageDisplayStatus {
  normal,
  pendingModeration,
  approved,
  blocked,
  hidden,
  system,
}

class ChatRoomView extends StatefulWidget {
  final ChatRoom room;

  const ChatRoomView({super.key, required this.room});

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  late AnimationController _panicButtonController;
  late Animation<double> _panicButtonAnimation;

  bool _isComposing = false;
  bool _showCrisisHelp = false;
  List<String> _copingSuggestions = [];

  @override
  void initState() {
    super.initState();

    // Setup panic button animation
    _panicButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _panicButtonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _panicButtonController, curve: Curves.easeInOut),
    );

    // Start subtle panic button pulse
    _startPanicButtonPulse();

    // Listen to message changes for AI suggestions
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _panicButtonController.dispose();
    super.dispose();
  }

  void _startPanicButtonPulse() {
    _panicButtonController.repeat(reverse: true);
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isComposing) {
      setState(() {
        _isComposing = hasText;
      });
    }

    // Check for crisis indicators in real-time
    _checkForCrisisIndicators(_messageController.text);
  }

  void _checkForCrisisIndicators(String text) async {
    if (text.length < 10) return; // Only check substantial text

    final authViewModel = Get.find<AuthViewModel>();
    if (authViewModel.userModel != null) {
      // Use AI to get coping suggestions if user seems distressed
      final suggestions = await ChatSafetyService.getCopingSuggestions(
        authViewModel.userModel!.id,
        text,
      );

      if (suggestions.isNotEmpty && mounted) {
        setState(() {
          _copingSuggestions = suggestions;
          _showCrisisHelp =
              text.toLowerCase().contains('hopeless') ||
              text.toLowerCase().contains('can\'t take it') ||
              text.toLowerCase().contains('want to die');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSafetyBanner(),
          if (_showCrisisHelp) _buildCrisisHelpBanner(),
          if (_copingSuggestions.isNotEmpty) _buildCopingSuggestionsBanner(),
          Expanded(child: _buildMessagesList()),
          _buildMessageComposer(),
        ],
      ),
      floatingActionButton: _buildPanicButton(),
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
            widget.room.name,
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
          onPressed: _showRoomInfo,
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

  Widget _buildCrisisHelpBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(bottom: BorderSide(color: Colors.red[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re here for you',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                Text(
                  'If you\'re in crisis, tap the panic button or call Tele-MANAS: 14416',
                  style: TextStyle(fontSize: 12, color: Colors.red[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showCrisisHelp = false),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildCopingSuggestionsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Coping suggestions for you:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _copingSuggestions.clear()),
                child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _copingSuggestions.take(3).map((suggestion) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.getChatMessages(widget.room.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          String errorMessage = 'Error loading messages';
          String actionText = 'Retry';

          if (error.contains('network')) {
            errorMessage = 'No internet connection';
            actionText = 'Check Connection';
          } else if (error.contains('permission')) {
            errorMessage = 'No permission to access this room';
            actionText = 'Go Back';
          } else if (error.contains('not-found')) {
            errorMessage = 'This chat room no longer exists';
            actionText = 'Go Back';
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.withOpacity(0.15),
                          Colors.orange.withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Color(0xFF1A1D23),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again or contact support if the problem persists.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: Text(actionText),
                      ),
                      if (error.contains('permission') ||
                          error.contains('not-found'))
                        const SizedBox(width: 16),
                      if (error.contains('permission') ||
                          error.contains('not-found'))
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text('Go Back'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return _buildEmptyMessagesState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe =
                message.senderId == Get.find<AuthViewModel>().user?.uid;
            final showAvatar =
                index == 0 || messages[index - 1].senderId != message.senderId;

            // Enhanced message visibility logic
            if (!_shouldShowMessage(message, isMe)) {
              return const SizedBox.shrink();
            }

            return _buildMessageBubble(message, isMe, showAvatar);
          },
        );
      },
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6D83F2).withOpacity(0.15),
                  const Color(0xFF00C6FF).withOpacity(0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              widget.room.topic.emoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to ${widget.room.name}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D23),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.room.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6D83F2).withOpacity(0.1),
                  const Color(0xFF00C6FF).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6D83F2).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a safe space',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D83F2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All messages are monitored for safety. Be kind and supportive.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showAvatar) {
    final status = _getMessageStatus(message, isMe);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) _buildAvatar(message.senderId),
          if (!isMe && !showAvatar) const SizedBox(width: 40),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showAvatar && !isMe) _buildSenderName(message.senderId),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(message, isMe, status),
                      borderRadius: BorderRadius.circular(16),
                      border: _getBubbleBorder(status),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status indicator for system/crisis messages
                        if (message.type == MessageType.system ||
                            message.type == MessageType.crisisAlert)
                          _buildMessageTypeHeader(message),

                        if (message.type == MessageType.system ||
                            message.type == MessageType.crisisAlert)
                          const SizedBox(height: 4),

                        Text(
                          message.content,
                          style: TextStyle(
                            color: _getTextColor(message, isMe, status),
                            fontSize: 16,
                            height: 1.3,
                            fontStyle:
                                status == MessageDisplayStatus.pendingModeration
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),

                        // Moderation status indicator
                        if (status != MessageDisplayStatus.normal &&
                            status != MessageDisplayStatus.system)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildModerationIndicator(status, isMe),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      if (!isMe && message.type != MessageType.system) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _reportMessage(message),
                          child: Icon(
                            Icons.flag_outlined,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe && showAvatar) _buildAvatar(message.senderId),
          if (isMe && !showAvatar) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageTypeHeader(ChatMessage message) {
    IconData icon;
    String label;
    Color? color;

    switch (message.type) {
      case MessageType.system:
        icon = Icons.info_outline;
        label = 'System';
        color = Colors.amber[700];
        break;
      case MessageType.crisisAlert:
        icon = Icons.warning_outlined;
        label = 'Crisis Alert';
        color = Colors.red[700];
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModerationIndicator(MessageDisplayStatus status, bool isMe) {
    IconData icon;
    String text;
    Color color;

    switch (status) {
      case MessageDisplayStatus.pendingModeration:
        icon = Icons.schedule;
        text = isMe ? 'Pending moderation' : 'Under review';
        color = Colors.orange[600]!;
        break;
      case MessageDisplayStatus.approved:
        icon = Icons.verified_user;
        text = 'Reviewed';
        color = Colors.green[600]!;
        break;
      case MessageDisplayStatus.blocked:
        icon = Icons.block;
        text = 'Blocked';
        color = Colors.red[600]!;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }

  Color _getBubbleColor(
    ChatMessage message,
    bool isMe,
    MessageDisplayStatus status,
  ) {
    switch (status) {
      case MessageDisplayStatus.system:
        return Colors.amber[100]!;
      case MessageDisplayStatus.pendingModeration:
        return isMe ? Colors.orange[50]! : Colors.white;
      case MessageDisplayStatus.blocked:
        return Colors.red[50]!;
      default:
        return isMe ? const Color(0xFF6D83F2) : Colors.white;
    }
  }

  Border? _getBubbleBorder(MessageDisplayStatus status) {
    switch (status) {
      case MessageDisplayStatus.pendingModeration:
        return Border.all(color: Colors.orange[300]!, width: 1);
      case MessageDisplayStatus.blocked:
        return Border.all(color: Colors.red[300]!, width: 1);
      default:
        return null;
    }
  }

  Color _getTextColor(
    ChatMessage message,
    bool isMe,
    MessageDisplayStatus status,
  ) {
    switch (status) {
      case MessageDisplayStatus.system:
        return Colors.amber[800]!;
      case MessageDisplayStatus.pendingModeration:
        return isMe ? Colors.orange[800]! : const Color(0xFF1A1D23);
      case MessageDisplayStatus.blocked:
        return Colors.red[800]!;
      default:
        return isMe ? Colors.white : const Color(0xFF1A1D23);
    }
  }

  Widget _buildAvatar(String userId) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 18, color: Colors.white),
    );
  }

  Widget _buildSenderName(String userId) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: FutureBuilder<UserChatProfile?>(
        future: ChatTrustService.getUserChatProfile(userId),
        builder: (context, snapshot) {
          UserTrustLevel trustLevel;

          // Safely get trust level with validation
          try {
            trustLevel = snapshot.data?.trustLevel ?? UserTrustLevel.newUser;
            // Validate that the trust level is actually valid
            if (!UserTrustLevel.values.contains(trustLevel)) {
              trustLevel = UserTrustLevel.newUser;
            }
          } catch (e) {
            print('Error getting trust level for user $userId: $e');
            trustLevel = UserTrustLevel.newUser;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                StringUtils.formatUserDisplayName(userId),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 6),
              _buildTrustLevelBadge(trustLevel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrustLevelBadge(UserTrustLevel trustLevel) {
    Color color;
    IconData icon;
    String tooltip;

    // Safely handle the trust level with explicit validation
    try {
      switch (trustLevel) {
        case UserTrustLevel.newUser:
          color = Colors.grey[400]!;
          icon = Icons.person_outline;
          tooltip = 'New User - Messages are moderated';
          break;
        case UserTrustLevel.verified:
          color = Colors.blue[500]!;
          icon = Icons.verified_user_outlined;
          tooltip = 'Verified User - Email verified';
          break;
        case UserTrustLevel.trusted:
          color = Colors.green[600]!;
          icon = Icons.shield_outlined;
          tooltip = 'Trusted User - Established community member';
          break;
        case UserTrustLevel.mentor:
          color = Colors.purple[600]!;
          icon = Icons.school_outlined;
          tooltip = 'Mentor - Trained in crisis support';
          break;
      }
    } catch (e) {
      // Fallback for any enum-related errors
      print('Error in _buildTrustLevelBadge: $e, trustLevel: $trustLevel');
      color = Colors.grey[400]!;
      icon = Icons.person_outline;
      tooltip = 'New User - Messages are moderated';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
            Text(
              trustLevel.displayName,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6D83F2).withOpacity(0.08),
                      const Color(0xFF00C6FF).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF6D83F2).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF1A1D23),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a supportive message...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: _isComposing
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                      ),
                      shape: BoxShape.circle,
                    )
                  : BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
              child: IconButton(
                onPressed: _isComposing ? _sendMessage : null,
                icon: Icon(
                  Icons.send,
                  color: _isComposing ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicButton() {
    return AnimatedBuilder(
      animation: _panicButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _panicButtonAnimation.value,
          child: FloatingActionButton(
            onPressed: _handlePanicButton,
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.sos, size: 28),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  /// Enhanced message visibility logic based on moderation state
  bool _shouldShowMessage(ChatMessage message, bool isMe) {
    // System messages are always visible
    if (message.type == MessageType.system ||
        message.metadata.isSystemMessage) {
      return true;
    }

    // Crisis alerts are always visible to provide support
    if (message.type == MessageType.crisisAlert) {
      return true;
    }

    // If message is filtered/blocked, don't show it
    if (message.isFiltered) {
      return false;
    }

    // If message needs moderation
    if (message.needsModeration) {
      // Show pending messages only to the sender
      if (!message.metadata.moderatorApproved && isMe) {
        return true;
      }
      // Show approved messages to everyone
      if (message.metadata.moderatorApproved) {
        return true;
      }
      // Hide unapproved messages from non-senders
      return false;
    }

    // Show normal messages if visible
    return message.isVisible;
  }

  /// Get message status for UI indicators
  MessageDisplayStatus _getMessageStatus(ChatMessage message, bool isMe) {
    if (message.type == MessageType.system) {
      return MessageDisplayStatus.system;
    }

    if (message.isFiltered) {
      return MessageDisplayStatus.blocked;
    }

    if (message.needsModeration) {
      if (message.metadata.moderatorApproved) {
        return MessageDisplayStatus.approved;
      } else if (isMe) {
        return MessageDisplayStatus.pendingModeration;
      } else {
        return MessageDisplayStatus.hidden;
      }
    }

    return MessageDisplayStatus.normal;
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Validate message length
    if (text.length > 1000) {
      _showErrorSnackbar(
        'Message Too Long',
        'Please keep messages under 1000 characters.',
      );
      return;
    }

    // Store original message for potential restoration
    final originalMessage = text;

    // Clear the input immediately for better UX
    _messageController.clear();
    setState(() {
      _isComposing = false;
      _copingSuggestions.clear();
      _showCrisisHelp = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // Check if user can still participate (not exceeded limits, etc.)
      final canParticipate = await ChatSafetyService.canUserParticipateInChat(
        Get.find<AuthViewModel>().user?.uid ?? '',
        widget.room.id,
      );

      if (!canParticipate) {
        _showErrorSnackbar(
          'Unable to Send Message',
          'You have reached your daily chat limit or need verification.',
        );
        _restoreMessage(originalMessage);
        return;
      }

      // Send message through our safety system
      final result = await ChatService.sendMessageWithFeedback(
        roomId: widget.room.id,
        content: text,
      );

      if (!result.sent) {
        final msg =
            result.violationMessage ??
            'Your message was blocked for safety reasons. Please review our community guidelines.';
        _showErrorSnackbar(
          'Message Not Sent',
          msg,
          duration: const Duration(seconds: 5),
        );
        _restoreMessageWithDialog(originalMessage);

        if (result.kicked) {
          // Pop back to rooms if kicked
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      _handleMessageSendError(originalMessage, e);
    }
  }

  // Removed: _handleMessageSendFailure is no longer used (handled inline)

  void _handleMessageSendError(String originalMessage, dynamic error) {
    String errorMessage = 'A network error occurred. Please try again.';

    if (error.toString().contains('network')) {
      errorMessage = 'Please check your internet connection and try again.';
    } else if (error.toString().contains('permission')) {
      errorMessage =
          'You don\'t have permission to send messages in this room.';
    } else if (error.toString().contains('quota')) {
      errorMessage =
          'You\'ve reached your message limit. Please wait before sending more.';
    }

    _showErrorSnackbar('Error Sending Message', errorMessage);
    _restoreMessage(originalMessage);
  }

  void _restoreMessage(String message) {
    _messageController.text = message;
    setState(() {
      _isComposing = true;
    });
  }

  void _restoreMessageWithDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Message Blocked'),
        content: const Text(
          'Your message was blocked by our safety filters. Would you like to edit and try again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreMessage(message);
            },
            child: const Text('Edit Message'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red[600],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _handlePanicButton() async {
    HapticFeedback.vibrate();

    // Stop the pulse animation
    if (mounted && _panicButtonController.isAnimating) {
      _panicButtonController.stop();
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.sos, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('Crisis Support'),
          ],
        ),
        content: const Text(
          'Are you in crisis or need immediate help?\n\nWe can connect you with professional crisis support right now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Get Help Now'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _triggerCrisisIntervention();
    }

    // Restart pulse animation
    if (mounted) {
      _startPanicButtonPulse();
    }
  }

  Future<void> _triggerCrisisIntervention() async {
    try {
      final authViewModel = Get.find<AuthViewModel>();
      final userProfile = authViewModel.userModel;

      if (userProfile == null) {
        _showErrorSnackbar(
          'Error',
          'Unable to access user profile. Please try again.',
        );
        _showEmergencyContacts();
        return;
      }

      // Show loading indicator for crisis intervention
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Preparing crisis support...')),
            ],
          ),
        ),
      );

      final intervention =
          await CrisisInterventionService.triggerCrisisIntervention(
            userId: userProfile.id,
            triggerMessage: 'User pressed panic button in chat',
            userMoodLevel: 1, // Assume crisis level
            crisisFlags: ['panic_button'],
          );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show crisis support dialog
      if (mounted) _showCrisisInterventionDialog(intervention);
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error triggering crisis intervention: $e');

      if (mounted) {
        _showErrorSnackbar(
          'Crisis Support Error',
          'Unable to connect to crisis services. Showing emergency contacts.',
          duration: const Duration(seconds: 5),
        );
        _showEmergencyContacts();
      }
    }
  }

  void _showCrisisInterventionDialog(CrisisInterventionResult intervention) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Crisis Support Available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intervention.aiResponse),
              const SizedBox(height: 16),
              const Text(
                'Immediate Actions:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...intervention.immediateActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(action)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I\'m Safe Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEmergencyContacts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Call for Help'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Emergency Contacts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmergencyContactTile(
                'Tele-MANAS Crisis Support',
                '14416',
                'Call anytime - 24/7 support',
                Icons.phone,
                () => CrisisInterventionService.connectToProfessionalHelp(
                  userId: Get.find<AuthViewModel>().user?.uid ?? '',
                  crisisLevel: CrisisLevel.severe,
                  preferredContact: '14416',
                ),
              ),
              _buildEmergencyContactTile(
                'Tele-MANAS Helpline',
                '1-800-891-4416',
                'Alternative helpline - 24/7',
                Icons.message,
                () => CrisisInterventionService.connectToProfessionalHelp(
                  userId: Get.find<AuthViewModel>().user?.uid ?? '',
                  crisisLevel: CrisisLevel.moderate,
                ),
              ),
              _buildEmergencyContactTile(
                'Emergency Services (India)',
                '112',
                'Immediate danger',
                Icons.local_hospital,
                () => CrisisInterventionService.connectToProfessionalHelp(
                  userId: Get.find<AuthViewModel>().user?.uid ?? '',
                  crisisLevel: CrisisLevel.imminent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactTile(
    String title,
    String number,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.red[600]),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(description, style: const TextStyle(fontSize: 12)),
        ],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _reportMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report Message'),
        content: const Text('Why are you reporting this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitReport(message, 'inappropriate_content');
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _submitReport(ChatMessage message, String reason) async {
    final authViewModel = Get.find<AuthViewModel>();
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      _showErrorSnackbar(
        'Unable to Report',
        'Please sign in to report content.',
      );
      return;
    }

    try {
      final success = await ChatSafetyService.reportContent(
        reporterId: currentUser.uid,
        reportedUserId: message.senderId,
        chatRoomId: widget.room.id,
        messageId: message.id,
        reason: reason,
        description: 'Reported from chat interface',
      );

      if (success) {
        Get.snackbar(
          'Report Submitted',
          'Thank you for helping keep our community safe.',
          backgroundColor: Colors.green[600],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        );
      } else {
        _showErrorSnackbar(
          'Report Failed',
          'Unable to submit report. Please try again later.',
        );
      }
    } catch (e) {
      print('Error submitting report: $e');
      _showErrorSnackbar(
        'Report Error',
        'An error occurred while submitting your report.',
      );
    }
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
              _showRoomInfo,
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

  void _showRoomInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.room.topic.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.room.topic.displayName,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.room.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${widget.room.participantCount} members',
                ),
                const SizedBox(width: 16),
                if (widget.room.safetyLevel == ChatRoomSafetyLevel.high)
                  _buildInfoChip(
                    icon: Icons.shield,
                    label: 'Moderated',
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
