import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../chat/private_chat_list_view.dart';
import '../../services/private_chat_service.dart';
import 'crisis_support_chat_view.dart';
import 'chat_room_view.dart';
import '../../widgets/brand_ui.dart';

class ChatRoomsView extends StatefulWidget {
  const ChatRoomsView({super.key});

  @override
  State<ChatRoomsView> createState() => _ChatRoomsViewState();
}

class _ChatRoomsViewState extends State<ChatRoomsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize default rooms if needed
    ChatService.initializeDefaultChatRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF9FBFF), // very light indigo tint
                Color(0xFFF7FFFB), // very light mint tint
              ],
            ),
          ),
          child: Column(
            children: [
              // Custom Header with gradient extending to status bar
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6D83F2),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).padding.top + 16,
                        16,
                        0,
                      ),
                      child: Row(
                        children: [
                          _gradientText(
                            'Chat Rooms',
                            const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(text: 'Support Groups'),
                        Tab(text: 'General Chat'),
                        Tab(text: 'My Rooms'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSupportGroupsTab(),
                      _buildGeneralChatTab(),
                      _buildMyRoomsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientText(String text, TextStyle style) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Colors.white],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }

  Widget _buildSupportGroupsTab() {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatService.getAllChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
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
                    size: 56,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading chat rooms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }

        final supportRooms =
            snapshot.data
                ?.where((room) => room.type == ChatRoomType.support)
                .toList() ??
            [];

        if (supportRooms.isEmpty) {
          return _buildEmptyState(
            icon: Icons.support_agent,
            title: 'No Support Groups Yet',
            subtitle: 'Support groups will appear here when available',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: supportRooms.length,
          itemBuilder: (context, index) {
            final room = supportRooms[index];
            return _buildRoomCard(room);
          },
        );
      },
    );
  }

  Widget _buildGeneralChatTab() {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatService.getAllChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final generalRooms =
            snapshot.data
                ?.where((room) => room.type == ChatRoomType.group)
                .toList() ??
            [];

        // Always show the DMs quick access at the top, then the existing room list
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDMsQuickAccess(context),
            const SizedBox(height: 12),
            if (generalRooms.isEmpty)
              _buildEmptyState(
                icon: Icons.chat,
                title: 'No General Chat Rooms',
                subtitle: 'General chat rooms will appear here',
              )
            else
              ...generalRooms.map((room) => _buildRoomCard(room)),
          ],
        );
      },
    );
  }

  Widget _buildDMsQuickAccess(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D83F2).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => const PrivateChatListView()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Messages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chat privately with anyone — just like Instagram DMs',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<int>(
                  stream: PrivateChatService.getTotalUnreadCount(),
                  builder: (context, snapshot) {
                    final unread = snapshot.data ?? 0;
                    if (unread <= 0) {
                      return const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: const TextStyle(
                          color: Color(0xFF6D83F2),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRoomsTab() {
    return FutureBuilder<String?>(
      future: _getCurrentUserId(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<ChatRoom>>(
          stream: ChatService.getUserChatRooms(userSnapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final myRooms = snapshot.data ?? [];

            if (myRooms.isEmpty) {
              return _buildEmptyState(
                icon: Icons.person_outline,
                title: 'No Joined Rooms',
                subtitle: 'Join support groups to see them here',
                action: ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Browse Support Groups'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myRooms.length,
              itemBuilder: (context, index) {
                final room = myRooms[index];
                return _buildRoomCard(room, showLeaveOption: true);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRoomCard(ChatRoom room, {bool showLeaveOption = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1565C0).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRoomDetails(room),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Blue header bar similar to crisis support
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        room.topic.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                    ),
                    if (showLeaveOption)
                      IconButton(
                        onPressed: () => _leaveRoom(room),
                        icon: const Icon(
                          Icons.exit_to_app,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              // White content area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Safety banner strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade100, Colors.blue.shade100],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.green.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Safe, monitored environment with professional support',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      room.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${room.participantCount}/${room.maxParticipants} members',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (room.safetyLevel == ChatRoomSafetyLevel.high)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield,
                                  size: 12,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Moderated',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (room.isFull)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Room Full',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
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
                    const Color(0xFF6D83F2).withOpacity(0.15),
                    const Color(0xFF00C6FF).withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: const Color(0xFF6D83F2)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(ChatRoom room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRoomDetailsSheet(room),
    );
  }

  Widget _buildRoomDetailsSheet(ChatRoom room) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getTopicColor(room.topic).withOpacity(0.15),
                      _getTopicColor(room.topic).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  room.topic.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.topic.displayName,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'About this room',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            room.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Room stats
          Row(
            children: [
              _buildStatChip(
                icon: Icons.people,
                label: '${room.participantCount}/${room.maxParticipants}',
                subtitle: 'Members',
              ),
              const SizedBox(width: 16),
              if (room.safetyLevel == ChatRoomSafetyLevel.high)
                _buildStatChip(
                  icon: Icons.shield,
                  label: 'Moderated',
                  subtitle: 'Safety',
                  color: Colors.green,
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Join/Open button with membership state
          FutureBuilder<String?>(
            future: _getCurrentUserId(),
            builder: (context, userSnap) {
              final uid = userSnap.data;
              if (uid == null) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    child: const Text('Sign in to join'),
                  ),
                );
              }

              return StreamBuilder<bool>(
                stream: ChatService.isUserInRoom(room.id, uid),
                builder: (context, memSnap) {
                  final alreadyMember = memSnap.data == true;

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: room.isFull && !alreadyMember
                          ? null
                          : BrandUI.brandAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: room.isFull && !alreadyMember
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF6D83F2).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Material(
                      color: room.isFull && !alreadyMember
                          ? Colors.grey[300]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: room.isFull && !alreadyMember
                            ? null
                            : () => alreadyMember
                                  ? _openRoom(room)
                                  : _joinRoom(room),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              room.isFull && !alreadyMember
                                  ? 'Room Full'
                                  : alreadyMember
                                  ? 'Open Room'
                                  : 'Join Room',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: room.isFull && !alreadyMember
                                    ? Colors.grey[600]
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String subtitle,
    Color? color,
  }) {
    final chipColor = color ?? const Color(0xFF6D83F2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [chipColor.withOpacity(0.15), chipColor.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: chipColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: chipColor),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTopicColor(ChatRoomTopic topic) {
    switch (topic) {
      case ChatRoomTopic.depression:
        return const Color(0xFF6366F1);
      case ChatRoomTopic.anxiety:
        return const Color(0xFFEC4899);
      case ChatRoomTopic.recovery:
        return const Color(0xFF10B981);
      case ChatRoomTopic.motivation:
        return const Color(0xFFF59E0B);
      case ChatRoomTopic.crisisSupport:
        return const Color(0xFFEF4444);
      case ChatRoomTopic.selfCare:
        return const Color(0xFF8B5CF6);
      case ChatRoomTopic.general:
        return const Color(0xFF6B7280);
    }
  }

  Future<String?> _getCurrentUserId() async {
    // Get current user ID from AuthViewModel
    final authViewModel = Get.find<AuthViewModel>();
    return authViewModel.user?.uid;
  }

  void _joinRoom(ChatRoom room) async {
    try {
      Get.back(); // Close bottom sheet

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final success = await ChatService.joinChatRoom(room.id);

      Get.back(); // Close loading dialog

      if (success) {
        Get.snackbar(
          'Success',
          'Joined ${room.name}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to appropriate chat interface
        if (room.topic == ChatRoomTopic.crisisSupport) {
          Get.to(() => CrisisSupportChatView(room: room));
        } else {
          // Navigate to regular chat room interface for other room types
          Get.to(() => ChatRoomView(room: room));
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to join room. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _leaveRoom(ChatRoom room) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Leave Room'),
        content: Text('Are you sure you want to leave ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ChatService.leaveChatRoom(room.id);

      if (success) {
        Get.snackbar(
          'Left Room',
          'You left ${room.name}',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _openRoom(ChatRoom room) {
    // Navigate to the appropriate chat interface depending on topic/type
    if (room.topic == ChatRoomTopic.crisisSupport) {
      Get.back(); // Close bottom sheet if open
      Get.to(() => CrisisSupportChatView(room: room));
    } else {
      Get.back();
      Get.to(() => ChatRoomView(room: room));
    }
  }
}
