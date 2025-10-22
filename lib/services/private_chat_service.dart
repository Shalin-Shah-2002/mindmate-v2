import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/debug_flags.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/private_conversation.dart';
import '../models/user_report.dart';
import '../services/chat_trust_service.dart';
import '../services/chat_safety_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class ChatPermissionResult {
  final bool allowed;
  final String? reason;
  const ChatPermissionResult(this.allowed, [this.reason]);
}

class ChatSendResult {
  final bool success;
  final String? reason;
  const ChatSendResult(this.success, [this.reason]);
}

class PrivateChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _conversations =>
      _firestore.collection('private_conversations');
  static CollectionReference get _userBlocks =>
      _firestore.collection('user_blocks');

  /// Check if two users can chat with each other
  static Future<bool> canUsersChat(String userId1, String userId2) async {
    final result = await canUsersChatWithReason(userId1, userId2);
    return result.allowed;
  }

  /// Like canUsersChat, but also returns a human-readable reason if denied.
  static Future<ChatPermissionResult> canUsersChatWithReason(
    String userId1,
    String userId2,
  ) async {
    try {
      // Check if users are blocked, and determine direction if possible
      final currentUser = _auth.currentUser;
      QuerySnapshot? blockerSide;
      QuerySnapshot? blockedSide;
      if (currentUser != null) {
        final otherId = currentUser.uid == userId1 ? userId2 : userId1;
        blockerSide = await _userBlocks
            .where('blockerId', isEqualTo: currentUser.uid)
            .where('blockedUserId', isEqualTo: otherId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        blockedSide = await _userBlocks
            .where('blockedUserId', isEqualTo: currentUser.uid)
            .where('blockerId', isEqualTo: otherId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
      }

      final hasBlockEither =
          (blockerSide?.docs.isNotEmpty ?? false) ||
          (blockedSide?.docs.isNotEmpty ?? false);
      if (hasBlockEither) {
        final reason = (blockerSide?.docs.isNotEmpty ?? false)
            ? "You've blocked this user"
            : 'This user has blocked you';
        if (kDebugMode) {
          print(
            'PrivateChatService.canUsersChatWithReason: blocked => $reason (user1=$userId1 user2=$userId2)',
          );
        }
        return ChatPermissionResult(false, reason);
      }

      // In debug builds, allow override to bypass trust gating while keeping block checks
      if (kDebugMode && AppDebugFlags.allowDMOverride) {
        return const ChatPermissionResult(true);
      }

      // Use trust service with reason
      final trustResult = await ChatTrustService.canUsersChatWithReason(
        userId1,
        userId2,
      );
      if (!trustResult.allowed) {
        if (kDebugMode) {
          print(
            'PrivateChatService.canUsersChatWithReason: trust denied => ${trustResult.reason}',
          );
        }
        return ChatPermissionResult(false, trustResult.reason);
      }

      if (kDebugMode) {
        print(
          'PrivateChatService.canUsersChatWithReason: allowed (user1=$userId1 user2=$userId2)',
        );
      }
      return const ChatPermissionResult(true);
    } catch (e) {
      if (kDebugMode) {
        print('PrivateChatService: Error checking chat permission: $e');
      }
      return const ChatPermissionResult(
        false,
        'An unexpected error occurred while checking permissions',
      );
    }
  }

  /// Create or get existing private conversation between two users
  static Future<PrivateConversation?> createOrGetConversation(
    String otherUserId,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final currentUserId = currentUser.uid;

      // Check if users can chat
      if (!await canUsersChat(currentUserId, otherUserId)) {
        print('PrivateChatService: Users cannot chat');
        return null;
      }

      final conversationId = PrivateConversation.generateConversationId(
        currentUserId,
        otherUserId,
      );

      // Check if conversation already exists
      final existingDoc = await _conversations.doc(conversationId).get();
      if (existingDoc.exists) {
        return PrivateConversation.fromFirestore(existingDoc);
      }

      // Create new conversation
      final conversation = PrivateConversation(
        id: conversationId,
        participantIds: [currentUserId, otherUserId],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        lastMessage: '',
        lastMessageSenderId: '',
        unreadCounts: {currentUserId: 0, otherUserId: 0},
        blockedStatus: {currentUserId: false, otherUserId: false},
        isActive: true,
      );

      await _conversations.doc(conversationId).set(conversation.toFirestore());
      return conversation;
    } catch (e) {
      print('PrivateChatService: Error creating conversation: $e');
      return null;
    }
  }

  /// Send a message in a private conversation
  static Future<bool> sendMessage({
    required String conversationId,
    required String content,
    DirectMessageType type = DirectMessageType.text,
    String? replyToMessageId,
  }) async {
    final result = await sendMessageWithResult(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToMessageId: replyToMessageId,
    );
    return result.success;
  }

  static Future<ChatSendResult> sendMessageWithResult({
    required String conversationId,
    required String content,
    DirectMessageType type = DirectMessageType.text,
    String? replyToMessageId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return const ChatSendResult(false, 'Not authenticated');
      }

      final currentUserId = currentUser.uid;

      // Get conversation to validate
      final conversationDoc = await _conversations.doc(conversationId).get();
      if (!conversationDoc.exists) {
        return const ChatSendResult(false, 'Conversation not found');
      }

      final conversation = PrivateConversation.fromFirestore(conversationDoc);

      // Check if user is part of conversation
      if (!conversation.participantIds.contains(currentUserId)) {
        return const ChatSendResult(false, 'Not a participant in this chat');
      }

      // Check if conversation is blocked
      if (conversation.isBlocked) {
        return const ChatSendResult(false, 'Conversation is blocked');
      }

      // Perform safety check using existing service
      final safetyResult = await ChatSafetyService.checkMessageSafety(
        content,
        currentUserId,
        conversationId, // Using conversation ID as room ID for safety checks
      );

      if (!safetyResult.isAllowed) {
        return ChatSendResult(
          false,
          safetyResult.reason.isNotEmpty
              ? safetyResult.reason
              : 'Message blocked by safety filters',
        );
      }

      // Create message
      final message = DirectMessage(
        id: '', // Will be set by Firestore
        conversationId: conversationId,
        senderId: currentUserId,
        content: content,
        timestamp: DateTime.now(),
        type: type,
        isRead: false,
        isEdited: false,
        isDeleted: false,
        replyToMessageId: replyToMessageId,
      );

      // Add message to conversation messages subcollection
      await _conversations
          .doc(conversationId)
          .collection('messages')
          .add(message.toFirestore());

      // Update conversation with last message info
      final otherUserId = conversation.getOtherParticipantId(currentUserId);
      final updatedUnreadCounts = Map<String, int>.from(
        conversation.unreadCounts,
      );
      updatedUnreadCounts[otherUserId] =
          (updatedUnreadCounts[otherUserId] ?? 0) + 1;

      await _conversations.doc(conversationId).update({
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastMessage': content,
        'lastMessageSenderId': currentUserId,
        'unreadCounts': updatedUnreadCounts,
      });

      // Send notification to the recipient
      try {
        final authService = AuthService();
        final senderProfile = await authService.getUserProfile(currentUserId);
        if (senderProfile != null) {
          await NotificationService.sendMessageNotification(
            recipientId: otherUserId,
            senderName: senderProfile.name,
            senderId: currentUserId,
            conversationId: conversationId,
            messagePreview: content,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('PrivateChatService: Error sending notification: $e');
        }
        // Don't fail message send if notification fails
      }

      return const ChatSendResult(true);
    } catch (e) {
      if (kDebugMode) {
        print('PrivateChatService: Error sending message: $e');
      }
      return const ChatSendResult(false, 'Unexpected error while sending');
    }
  }

  /// Get messages stream for a conversation
  static Stream<List<DirectMessage>> getMessagesStream(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DirectMessage.fromFirestore(doc))
              .toList();
        });
  }

  /// Get conversations stream for current user
  static Stream<List<PrivateConversation>> getConversationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _conversations
        .where('participantIds', arrayContains: currentUser.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PrivateConversation.fromFirestore(doc))
              .where(
                (conversation) =>
                    !conversation.isBlockedByUser(currentUser.uid),
              )
              .toList();
        });
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final currentUserId = currentUser.uid;

      // Get conversation
      final conversationDoc = await _conversations.doc(conversationId).get();
      if (!conversationDoc.exists) return;

      final conversation = PrivateConversation.fromFirestore(conversationDoc);

      // Reset unread count for current user
      final updatedUnreadCounts = Map<String, int>.from(
        conversation.unreadCounts,
      );
      updatedUnreadCounts[currentUserId] = 0;

      await _conversations.doc(conversationId).update({
        'unreadCounts': updatedUnreadCounts,
      });

      // Mark unread messages as read
      final unreadMessages = await _conversations
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      print('PrivateChatService: Error marking messages as read: $e');
    }
  }

  /// Block a user
  static Future<bool> blockUser(String blockedUserId, String? reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final currentUserId = currentUser.uid;
      final blockId = UserBlock.generateBlockId(currentUserId, blockedUserId);

      // Create block record
      final userBlock = UserBlock(
        id: blockId,
        blockerId: currentUserId,
        blockedUserId: blockedUserId,
        createdAt: DateTime.now(),
        reason: reason,
        isActive: true,
      );

      await _userBlocks.doc(blockId).set(userBlock.toFirestore());

      // Update existing conversation to mark as blocked by current user
      final conversationId = PrivateConversation.generateConversationId(
        currentUserId,
        blockedUserId,
      );

      final conversationDoc = await _conversations.doc(conversationId).get();
      if (conversationDoc.exists) {
        final conversation = PrivateConversation.fromFirestore(conversationDoc);
        final updatedBlockedStatus = Map<String, bool>.from(
          conversation.blockedStatus,
        );
        updatedBlockedStatus[currentUserId] = true;

        await _conversations.doc(conversationId).update({
          'blockedStatus': updatedBlockedStatus,
        });
      }

      // Also update user's chat profile using existing method
      await ChatTrustService.blockUser(currentUserId, blockedUserId);

      return true;
    } catch (e) {
      print('PrivateChatService: Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  static Future<bool> unblockUser(String blockedUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final currentUserId = currentUser.uid;
      final blockId = UserBlock.generateBlockId(currentUserId, blockedUserId);

      // Deactivate block record
      await _userBlocks.doc(blockId).update({'isActive': false});

      // Update conversation to unblock
      final conversationId = PrivateConversation.generateConversationId(
        currentUserId,
        blockedUserId,
      );

      final conversationDoc = await _conversations.doc(conversationId).get();
      if (conversationDoc.exists) {
        final conversation = PrivateConversation.fromFirestore(conversationDoc);
        final updatedBlockedStatus = Map<String, bool>.from(
          conversation.blockedStatus,
        );
        updatedBlockedStatus[currentUserId] = false;

        await _conversations.doc(conversationId).update({
          'blockedStatus': updatedBlockedStatus,
        });
      }

      // Update user's chat profile using existing method
      await ChatTrustService.unblockUser(currentUserId, blockedUserId);

      return true;
    } catch (e) {
      print('PrivateChatService: Error unblocking user: $e');
      return false;
    }
  }

  /// Check if current user has blocked another user
  static Future<bool> hasBlockedUser(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Query for an active block where current user is the blocker
      final snapshot = await _userBlocks
          .where('blockerId', isEqualTo: currentUser.uid)
          .where('blockedUserId', isEqualTo: otherUserId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('PrivateChatService: Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Delete a conversation (archive it)
  static Future<bool> deleteConversation(String conversationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Instead of actually deleting, we'll mark it as inactive for the current user
      // This preserves the conversation for the other user
      await _conversations.doc(conversationId).update({'isActive': false});

      return true;
    } catch (e) {
      print('PrivateChatService: Error deleting conversation: $e');
      return false;
    }
  }

  /// Get total unread message count for current user
  static Stream<int> getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _conversations
        .where('participantIds', arrayContains: currentUser.uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (final doc in snapshot.docs) {
            final conversation = PrivateConversation.fromFirestore(doc);
            if (!conversation.isBlockedByUser(currentUser.uid)) {
              totalUnread += conversation.getUnreadCount(currentUser.uid);
            }
          }
          return totalUnread;
        });
  }
}
