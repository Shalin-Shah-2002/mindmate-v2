import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'crisis_support_chat_view.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chat Rooms',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Support Groups'),
            Tab(text: 'General Chat'),
            Tab(text: 'My Rooms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupportGroupsTab(),
          _buildGeneralChatTab(),
          _buildMyRoomsTab(),
        ],
      ),
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
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading chat rooms',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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

        if (generalRooms.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat,
            title: 'No General Chat Rooms',
            subtitle: 'General chat rooms will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: generalRooms.length,
          itemBuilder: (context, index) {
            final room = generalRooms[index];
            return _buildRoomCard(room);
          },
        );
      },
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRoomDetails(room),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTopicColor(room.topic).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      room.topic.emoji,
                      style: const TextStyle(fontSize: 24),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.participantCount}/${room.maxParticipants}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (room.safetyLevel == ChatRoomSafetyLevel.high)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
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
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showLeaveOption)
                    IconButton(
                      onPressed: () => _leaveRoom(room),
                      icon: const Icon(Icons.exit_to_app),
                      color: Colors.grey[600],
                    ),
                ],
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
              if (room.isFull)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Room is full',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
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
                  color: _getTopicColor(room.topic).withOpacity(0.1),
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
              fontWeight: FontWeight.w600,
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

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: room.isFull && !alreadyMember
                          ? null
                          : () => alreadyMember
                                ? _openRoom(room)
                                : _joinRoom(room),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        room.isFull && !alreadyMember
                            ? 'Room Full'
                            : alreadyMember
                            ? 'Open Room'
                            : 'Join Room',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
    final chipColor = color ?? Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
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
                style: TextStyle(fontWeight: FontWeight.w600, color: chipColor),
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
          // TODO: Navigate to regular chat room interface for other room types
          _showComingSoonDialog('Chat Interface');
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

  void _showComingSoonDialog(String feature) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.rocket_launch,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Coming Soon!'),
          ],
        ),
        content: Text(
          '$feature is being developed with advanced safety features and will be available soon.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Got it!')),
        ],
      ),
    );
  }

  void _openRoom(ChatRoom room) {
    // Navigate to the appropriate chat interface depending on topic/type
    if (room.topic == ChatRoomTopic.crisisSupport) {
      Get.back(); // Close bottom sheet if open
      Get.to(() => CrisisSupportChatView(room: room));
    } else {
      Get.back();
      _showComingSoonDialog('Chat Interface');
    }
  }
}
