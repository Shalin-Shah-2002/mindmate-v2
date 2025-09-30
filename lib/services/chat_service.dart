import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/user_trust_level.dart';
import '../services/chat_trust_service.dart';
import '../services/chat_safety_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _chatRooms =>
      _firestore.collection('chat_rooms');
  static CollectionReference get _chatParticipants =>
      _firestore.collection('chat_room_participants');

  /// Get all available chat rooms
  static Stream<List<ChatRoom>> getAllChatRooms() {
    return _chatRooms
        .where('isActive', isEqualTo: true)
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList(),
        );
  }

  /// Get chat rooms by topic
  static Stream<List<ChatRoom>> getChatRoomsByTopic(ChatRoomTopic topic) {
    return _chatRooms
        .where('isActive', isEqualTo: true)
        .where('topic', isEqualTo: topic.value)
        .orderBy('participantCount', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList(),
        );
  }

  /// Get messages for a chat room
  static Stream<List<ChatMessage>> getChatMessages(
    String roomId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('chat_messages')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              // Do not filter here; allow UI to decide visibility
              .toList()
              .reversed
              .toList(),
        );
  }

  /// Join a chat room
  static Future<bool> joinChatRoom(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if user can participate in chat
      final canParticipate = await ChatSafetyService.canUserParticipateInChat(
        currentUser.uid,
        roomId,
      );
      if (!canParticipate) {
        print('ChatService: User cannot participate in this chat room');
        return false;
      }

      bool newlyJoined = false;

      await _firestore.runTransaction((txn) async {
        final roomRef = _chatRooms.doc(roomId);
        final participantRef = _chatParticipants
            .doc(roomId)
            .collection('participants')
            .doc(currentUser.uid);

        final roomSnap = await txn.get(roomRef);
        if (!roomSnap.exists) {
          throw Exception('Room not found');
        }
        final room = ChatRoom.fromFirestore(roomSnap);

        final participantSnap = await txn.get(participantRef);
        if (participantSnap.exists) {
          // Already a participant: just refresh lastSeen. No count changes.
          txn.update(participantRef, {'lastSeen': Timestamp.now()});
          newlyJoined = false;
          return;
        }

        // Capacity check at transaction-time to avoid races
        if (room.participantCount >= room.maxParticipants) {
          throw Exception('Room is at maximum capacity');
        }

        // Create participant and increment count atomically
        txn.set(participantRef, {
          'userId': currentUser.uid,
          'roomId': roomId,
          'joinedAt': Timestamp.now(),
          'lastSeen': Timestamp.now(),
          'isMuted': false,
          'isAnonymous': false,
        });

        txn.update(roomRef, {
          'participantCount': FieldValue.increment(1),
          'lastActivity': Timestamp.now(),
        });

        newlyJoined = true;
      });

      if (newlyJoined) {
        // Send system message only when someone actually joined
        await _sendSystemMessage(
          roomId,
          'A new member joined the conversation',
        );
        print('ChatService: User ${currentUser.uid} joined room $roomId');
      } else {
        print(
          'ChatService: User ${currentUser.uid} is already a member of $roomId',
        );
      }

      return true;
    } catch (e) {
      print('ChatService: Error joining chat room: $e');
      return false;
    }
  }

  /// Leave a chat room
  static Future<bool> leaveChatRoom(String roomId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      bool left = false;

      await _firestore.runTransaction((txn) async {
        final roomRef = _chatRooms.doc(roomId);
        final participantRef = _chatParticipants
            .doc(roomId)
            .collection('participants')
            .doc(currentUser.uid);

        final participantSnap = await txn.get(participantRef);
        if (!participantSnap.exists) {
          // Not a participant; nothing to do
          left = false;
          return;
        }

        txn.delete(participantRef);
        txn.update(roomRef, {
          'participantCount': FieldValue.increment(-1),
          'lastActivity': Timestamp.now(),
        });
        left = true;
      });

      if (left) {
        print('ChatService: User ${currentUser.uid} left room $roomId');
      } else {
        print(
          'ChatService: User ${currentUser.uid} was not a member of $roomId',
        );
      }

      return left;
    } catch (e) {
      print('ChatService: Error leaving chat room: $e');
      return false;
    }
  }

  /// Send a message to a chat room
  static Future<bool> sendMessage({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? attachments,
  }) async {
    final result = await sendMessageWithFeedback(
      roomId: roomId,
      content: content,
      type: type,
      attachments: attachments,
    );
    return result.sent;
  }

  /// Rich send API that returns violation warnings and kick status
  static Future<SendMessageResult> sendMessageWithFeedback({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? attachments,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return SendMessageResult.fail();

      // Get user's recent messages for context
      final recentMessages = await _getUserRecentMessages(
        currentUser.uid,
        limit: 5,
      );
      final userProfile = await ChatTrustService.getUserChatProfile(
        currentUser.uid,
      );

      // Check message safety
      final safetyResult = await ChatSafetyService.checkMessageSafety(
        content,
        currentUser.uid,
        roomId,
        userMoodLevel: userProfile?.vulnerabilityIndicators.currentMoodLevel,
        recentMessages: recentMessages,
      );

      // Handle crisis situations
      if (safetyResult.isCrisis) {
        await _handleCrisisMessage(
          currentUser.uid,
          content,
          roomId,
          safetyResult,
        );
        return SendMessageResult(
          sent: false,
          violationMessage:
              'We detected a crisis situation and provided support resources instead of sending your message.',
        );
      }

      // Block inappropriate content
      if (!safetyResult.isAllowed) {
        print('ChatService: Message blocked - ${safetyResult.reason}');

        // Track a violation and return message to show in UI
        final violation = await ChatSafetyService.trackViolation(
          userId: currentUser.uid,
          roomId: roomId,
          violationType: safetyResult.reason.isNotEmpty
              ? safetyResult.reason
              : 'policy_violation',
          content: content,
        );

        // If kicked, also ensure user is removed locally (leave room)
        if (violation.action == ViolationAction.kick) {
          try {
            await leaveChatRoom(roomId);
          } catch (_) {}
        }

        return SendMessageResult(
          sent: false,
          violationMessage: violation.message,
          kicked: violation.action == ViolationAction.kick,
        );
      }

      // Create message
      final message = ChatMessage(
        id: '', // Will be set by Firestore
        roomId: roomId,
        senderId: currentUser.uid,
        content: content,
        timestamp: DateTime.now(),
        type: type,
        isFiltered: safetyResult.requiresModeration,
        safetyScore: safetyResult.safetyScore,
        reportCount: 0,
        metadata: MessageMetadata(
          edited: false,
          isSystemMessage: false,
          crisisFlags: safetyResult.crisisFlags,
          moderatorNote: '',
          moderatorApproved: !safetyResult.requiresModeration,
        ),
        attachments: attachments ?? [],
      );

      // Send message to Firestore
      await _firestore
          .collection('chat_messages')
          .doc(roomId)
          .collection('messages')
          .add(message.toFirestore());

      // Update room last activity
      await _chatRooms.doc(roomId).update({'lastActivity': Timestamp.now()});

      // Update user's chat time
      await ChatTrustService.updateChatTime(
        currentUser.uid,
        1,
      ); // 1 minute per message

      // Update participant last seen
      await _chatParticipants
          .doc(roomId)
          .collection('participants')
          .doc(currentUser.uid)
          .update({'lastSeen': Timestamp.now()});

      print('ChatService: Message sent successfully');
      return SendMessageResult(sent: true);
    } catch (e) {
      print('ChatService: Error sending message: $e');
      return SendMessageResult.fail();
    }
  }

  /// Create a new chat room (for trusted users+)
  static Future<String?> createChatRoom({
    required String name,
    required String description,
    required ChatRoomTopic topic,
    ChatRoomType type = ChatRoomType.support,
    int maxParticipants = 50,
    ChatRoomSafetyLevel safetyLevel = ChatRoomSafetyLevel.medium,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Check if user can create rooms
      final userProfile = await ChatTrustService.getUserChatProfile(
        currentUser.uid,
      );
      if (userProfile == null ||
          userProfile.trustLevel.level < UserTrustLevel.trusted.level) {
        print('ChatService: User not authorized to create rooms');
        return null;
      }

      final room = ChatRoom(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        type: type,
        topic: topic,
        participantCount: 0,
        maxParticipants: maxParticipants,
        moderatorIds: [currentUser.uid], // Creator becomes moderator
        createdBy: currentUser.uid,
        isActive: true,
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        safetyLevel: safetyLevel,
        settings: ChatRoomSettings.defaultForSafetyLevel(safetyLevel),
      );

      final docRef = await _chatRooms.add(room.toFirestore());

      // Auto-join the creator
      await joinChatRoom(docRef.id);

      print('ChatService: Chat room created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('ChatService: Error creating chat room: $e');
      return null;
    }
  }

  /// Get user's joined chat rooms
  static Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    // Listen to all participant records for this user across rooms, then
    // fetch corresponding room docs and return them sorted by lastActivity.
    final participantsQuery = _firestore
        .collectionGroup('participants')
        .where('userId', isEqualTo: userId);

    return participantsQuery.snapshots().asyncMap((participantSnap) async {
      try {
        // Derive roomIds from participant docs; prefer stored field, fallback to parent id
        final roomIds = participantSnap.docs
            .map(
              (d) =>
                  (d.data()['roomId'] as String?) ??
                  d.reference.parent.parent?.id,
            )
            .whereType<String>()
            .toSet()
            .toList();

        if (roomIds.isEmpty) return <ChatRoom>[];

        final List<ChatRoom> rooms = [];

        // Firestore whereIn supports up to 10 values -> chunk if needed
        const int chunkSize = 10;
        for (int i = 0; i < roomIds.length; i += chunkSize) {
          final end = (i + chunkSize) > roomIds.length
              ? roomIds.length
              : (i + chunkSize);
          final chunk = roomIds.sublist(i, end);

          final chunkSnap = await _chatRooms
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (final doc in chunkSnap.docs) {
            try {
              final room = ChatRoom.fromFirestore(doc);
              if (room.isActive) {
                rooms.add(room);
              }
            } catch (e) {
              print('ChatService: Error parsing room ${doc.id}: $e');
            }
          }
        }

        // Sort by last activity desc
        rooms.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        return rooms;
      } catch (e) {
        print('ChatService: Error building My Rooms stream: $e');
        return <ChatRoom>[];
      }
    });
  }

  /// Initialize default chat rooms
  static Future<void> initializeDefaultChatRooms() async {
    try {
      // Check if rooms already exist
      final existingRooms = await _chatRooms.limit(1).get();
      if (existingRooms.docs.isNotEmpty) {
        print('ChatService: Default rooms already exist');
        return;
      }

      final defaultRooms = [
        {
          'name': 'Depression Support',
          'description':
              'A safe space for those dealing with depression to share experiences and support each other',
          'topic': ChatRoomTopic.depression,
          'safetyLevel': ChatRoomSafetyLevel.high,
        },
        {
          'name': 'Anxiety Relief',
          'description':
              'Connect with others who understand anxiety and learn coping strategies together',
          'topic': ChatRoomTopic.anxiety,
          'safetyLevel': ChatRoomSafetyLevel.high,
        },
        {
          'name': 'Recovery Circle',
          'description':
              'Share your recovery journey and celebrate milestones with supportive peers',
          'topic': ChatRoomTopic.recovery,
          'safetyLevel': ChatRoomSafetyLevel.medium,
        },
        {
          'name': 'Daily Motivation',
          'description':
              'Start your day with positive energy and motivational support from the community',
          'topic': ChatRoomTopic.motivation,
          'safetyLevel': ChatRoomSafetyLevel.medium,
        },
        {
          'name': 'Crisis Support',
          'description':
              'Immediate support for those in crisis - professionally moderated 24/7',
          'topic': ChatRoomTopic.crisisSupport,
          'safetyLevel': ChatRoomSafetyLevel.high,
        },
      ];

      for (final roomData in defaultRooms) {
        final room = ChatRoom(
          id: '',
          name: roomData['name'] as String,
          description: roomData['description'] as String,
          type: ChatRoomType.support,
          topic: roomData['topic'] as ChatRoomTopic,
          participantCount: 0,
          maxParticipants: roomData['topic'] == ChatRoomTopic.crisisSupport
              ? 10
              : 50,
          moderatorIds: [], // Will be assigned to mentors/professionals
          createdBy: 'system',
          isActive: true,
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
          safetyLevel: roomData['safetyLevel'] as ChatRoomSafetyLevel,
          settings: ChatRoomSettings.defaultForSafetyLevel(
            roomData['safetyLevel'] as ChatRoomSafetyLevel,
          ),
        );

        await _chatRooms.add(room.toFirestore());
      }

      print('ChatService: Default chat rooms initialized');
    } catch (e) {
      print('ChatService: Error initializing default rooms: $e');
    }
  }

  // Private helper methods

  static Future<void> _handleCrisisMessage(
    String userId,
    String content,
    String roomId,
    MessageSafetyResult safetyResult,
  ) async {
    try {
      // Generate crisis response
      final crisisResponse = await ChatSafetyService.generateCrisisResponse(
        content,
        safetyResult.safetyScore.round(),
        safetyResult.crisisFlags,
      );

      // Send crisis support message
      await _sendSystemMessage(roomId, crisisResponse);

      // Get coping suggestions
      final copingSuggestions = await ChatSafetyService.getCopingSuggestions(
        userId,
        content,
      );

      if (copingSuggestions.isNotEmpty) {
        final suggestionsText =
            '💡 **Immediate coping strategies:**\n${copingSuggestions.map((s) => '• $s').join('\n')}';
        await _sendSystemMessage(roomId, suggestionsText);
      }

      print('ChatService: Crisis intervention triggered for user $userId');
    } catch (e) {
      print('ChatService: Error handling crisis message: $e');
    }
  }

  static Future<void> _sendSystemMessage(String roomId, String content) async {
    try {
      final systemMessage = ChatMessage.system(
        roomId: roomId,
        content: content,
      );

      await _firestore
          .collection('chat_messages')
          .doc(roomId)
          .collection('messages')
          .add(systemMessage.toFirestore());
    } catch (e) {
      print('ChatService: Error sending system message: $e');
    }
  }

  static Future<List<String>> _getUserRecentMessages(
    String userId, {
    int limit = 5,
  }) async {
    try {
      // This would need to query across multiple rooms - simplified for now
      // In production, you'd want to maintain a user messages collection
      return [];
    } catch (e) {
      print('ChatService: Error getting user recent messages: $e');
      return [];
    }
  }

  // (Removed) chunking helper not required with individual doc fetches.

  /// Stream whether a user is already a participant of a given room
  static Stream<bool> isUserInRoom(String roomId, String userId) {
    return _chatParticipants
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists);
  }
}

class SendMessageResult {
  final bool sent;
  final String? violationMessage;
  final bool kicked;

  const SendMessageResult({
    required this.sent,
    this.violationMessage,
    this.kicked = false,
  });

  factory SendMessageResult.fail() => const SendMessageResult(
    sent: false,
    violationMessage: null,
    kicked: false,
  );
}

// Extension methods for better usability
extension ChatRoomExtension on ChatRoom {
  bool get requiresModerator => safetyLevel == ChatRoomSafetyLevel.high;
  bool get allowsAnonymous => settings.allowAnonymous;
  bool get isFull => participantCount >= maxParticipants;

  String get displayDescription {
    return '$description\n\n👥 $participantCount/$maxParticipants members';
  }
}
