import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateConversation {
  // Helper function to parse dates safely
  static DateTime _parseDate(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.parse(value);
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  final String id;
  final List<String> participantIds; // Always 2 participants for private chat
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessage;
  final String lastMessageSenderId;
  final Map<String, int> unreadCounts; // userId -> unread count
  final Map<String, bool> blockedStatus; // userId -> has blocked conversation
  final bool isActive;

  const PrivateConversation({
    required this.id,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessageAt,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.unreadCounts,
    required this.blockedStatus,
    required this.isActive,
  });

  factory PrivateConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PrivateConversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      createdAt: _parseDate(data['createdAt']),
      lastMessageAt: _parseDate(data['lastMessageAt']),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      blockedStatus: Map<String, bool>.from(data['blockedStatus'] ?? {}),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
      'blockedStatus': blockedStatus,
      'isActive': isActive,
    };
  }

  // Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Check if user has blocked the conversation
  bool isBlockedByUser(String userId) {
    return blockedStatus[userId] ?? false;
  }

  // Check if conversation is blocked by either participant
  bool get isBlocked {
    return blockedStatus.values.any((blocked) => blocked);
  }

  // Get unread count for specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  // Generate conversation ID from two user IDs (consistent ordering)
  static String generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  PrivateConversation copyWith({
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    Map<String, bool>? blockedStatus,
    bool? isActive,
  }) {
    return PrivateConversation(
      id: id,
      participantIds: participantIds,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      blockedStatus: blockedStatus ?? this.blockedStatus,
      isActive: isActive ?? this.isActive,
    );
  }
}

class DirectMessage {
  // Helper function to parse dates safely
  static DateTime _parseDate(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) return DateTime.parse(value);
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final DirectMessageType type;
  final bool isRead;
  final DateTime? readAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata; // For future extensions

  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.isEdited,
    this.editedAt,
    required this.isDeleted,
    this.deletedAt,
    this.replyToMessageId,
    this.metadata,
  });

  factory DirectMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DirectMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: _parseDate(data['timestamp']),
      type: DirectMessageType.fromString(data['type'] ?? 'text'),
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null ? _parseDate(data['readAt']) : null,
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null ? _parseDate(data['editedAt']) : null,
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? _parseDate(data['deletedAt'])
          : null,
      replyToMessageId: data['replyToMessageId'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.value,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  DirectMessage copyWith({
    String? content,
    bool? isRead,
    DateTime? readAt,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DirectMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content ?? this.content,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      replyToMessageId: replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum DirectMessageType {
  text('text'),
  image('image'),
  system('system'); // For system messages like "User joined", "User left"

  const DirectMessageType(this.value);
  final String value;

  static DirectMessageType fromString(String value) {
    return DirectMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DirectMessageType.text,
    );
  }
}
