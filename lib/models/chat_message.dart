import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text('text'),
  image('image'),
  supportResource('support_resource'),
  system('system'),
  crisisAlert('crisis_alert');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class ChatMessage {
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
  final String roomId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isFiltered;
  final double safetyScore; // 0.0 to 1.0, higher is safer
  final int reportCount;
  final MessageMetadata metadata;
  final List<String> attachments; // URLs for images, resources

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.isFiltered,
    required this.safetyScore,
    required this.reportCount,
    required this.metadata,
    required this.attachments,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: _parseDate(data['timestamp']),
      type: MessageType.fromString(data['type'] ?? 'text'),
      isFiltered: data['isFiltered'] ?? false,
      safetyScore: (data['safetyScore'] ?? 1.0).toDouble(),
      reportCount: data['reportCount'] ?? 0,
      metadata: MessageMetadata.fromMap(data['metadata'] ?? {}),
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.value,
      'isFiltered': isFiltered,
      'safetyScore': safetyScore,
      'reportCount': reportCount,
      'metadata': metadata.toMap(),
      'attachments': attachments,
    };
  }

  // Create a system message
  factory ChatMessage.system({
    required String roomId,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: '', // Will be set by Firestore
      roomId: roomId,
      senderId: 'system',
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.system,
      isFiltered: false,
      safetyScore: 1.0,
      reportCount: 0,
      metadata: MessageMetadata(
        edited: false,
        isSystemMessage: true,
        crisisFlags: [],
        moderatorNote: '',
      ),
      attachments: [],
    );
  }

  // Create a crisis alert message
  factory ChatMessage.crisisAlert({
    required String roomId,
    required String senderId,
    required String content,
  }) {
    return ChatMessage(
      id: '',
      roomId: roomId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.crisisAlert,
      isFiltered: false,
      safetyScore: 0.0, // Crisis messages need immediate attention
      reportCount: 0,
      metadata: MessageMetadata(
        edited: false,
        isSystemMessage: false,
        crisisFlags: ['automatic_detection'],
        moderatorNote: 'Auto-flagged for crisis content',
        requiresProfessionalReview: true,
      ),
      attachments: [],
    );
  }

  ChatMessage copyWith({
    String? content,
    bool? isFiltered,
    double? safetyScore,
    int? reportCount,
    MessageMetadata? metadata,
    List<String>? attachments,
  }) {
    return ChatMessage(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: content ?? this.content,
      timestamp: timestamp,
      type: type,
      isFiltered: isFiltered ?? this.isFiltered,
      safetyScore: safetyScore ?? this.safetyScore,
      reportCount: reportCount ?? this.reportCount,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  // Check if message needs moderation
  bool get needsModeration {
    return safetyScore < 0.7 ||
        reportCount > 0 ||
        metadata.crisisFlags.isNotEmpty;
  }

  // Check if message should be visible to users
  bool get isVisible {
    return !isFiltered && (!needsModeration || metadata.moderatorApproved);
  }
}

class MessageMetadata {
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

  final bool edited;
  final DateTime? editedAt;
  final bool isSystemMessage;
  final List<String> crisisFlags; // Types of crisis content detected
  final String moderatorNote;
  final bool moderatorApproved;
  final bool requiresProfessionalReview;
  final String? originalContent; // Before filtering/editing

  const MessageMetadata({
    required this.edited,
    this.editedAt,
    required this.isSystemMessage,
    required this.crisisFlags,
    required this.moderatorNote,
    this.moderatorApproved = false,
    this.requiresProfessionalReview = false,
    this.originalContent,
  });

  factory MessageMetadata.fromMap(Map<String, dynamic> map) {
    return MessageMetadata(
      edited: map['edited'] ?? false,
      editedAt: map['editedAt'] != null ? _parseDate(map['editedAt']) : null,
      isSystemMessage: map['isSystemMessage'] ?? false,
      crisisFlags: List<String>.from(map['crisisFlags'] ?? []),
      moderatorNote: map['moderatorNote'] ?? '',
      moderatorApproved: map['moderatorApproved'] ?? false,
      requiresProfessionalReview: map['requiresProfessionalReview'] ?? false,
      originalContent: map['originalContent'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'edited': edited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isSystemMessage': isSystemMessage,
      'crisisFlags': crisisFlags,
      'moderatorNote': moderatorNote,
      'moderatorApproved': moderatorApproved,
      'requiresProfessionalReview': requiresProfessionalReview,
      'originalContent': originalContent,
    };
  }

  MessageMetadata copyWith({
    bool? edited,
    DateTime? editedAt,
    bool? isSystemMessage,
    List<String>? crisisFlags,
    String? moderatorNote,
    bool? moderatorApproved,
    bool? requiresProfessionalReview,
    String? originalContent,
  }) {
    return MessageMetadata(
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      crisisFlags: crisisFlags ?? this.crisisFlags,
      moderatorNote: moderatorNote ?? this.moderatorNote,
      moderatorApproved: moderatorApproved ?? this.moderatorApproved,
      requiresProfessionalReview:
          requiresProfessionalReview ?? this.requiresProfessionalReview,
      originalContent: originalContent ?? this.originalContent,
    );
  }
}

// Chat report model for safety
class ChatReport {
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
  final String reporterId;
  final String reportedUserId;
  final String chatRoomId;
  final String? messageId;
  final String reason;
  final String description;
  final ReportStatus status;
  final ReportPriority priority;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? resolution;

  const ChatReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.chatRoomId,
    this.messageId,
    required this.reason,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.resolution,
  });

  factory ChatReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      messageId: data['messageId'],
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      status: ReportStatus.fromString(data['status'] ?? 'pending'),
      priority: ReportPriority.fromString(data['priority'] ?? 'medium'),
      createdAt: _parseDate(data['createdAt']),
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null
          ? _parseDate(data['reviewedAt'])
          : null,
      resolution: data['resolution'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'chatRoomId': chatRoomId,
      'messageId': messageId,
      'reason': reason,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'resolution': resolution,
    };
  }
}

enum ReportStatus {
  pending('pending'),
  reviewed('reviewed'),
  resolved('resolved'),
  dismissed('dismissed');

  const ReportStatus(this.value);
  final String value;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

enum ReportPriority {
  low('low'),
  medium('medium'),
  high('high'),
  crisis('crisis');

  const ReportPriority(this.value);
  final String value;

  static ReportPriority fromString(String value) {
    return ReportPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => ReportPriority.medium,
    );
  }

  // Auto-determine priority based on content
  static ReportPriority fromContent(String content, List<String> crisisFlags) {
    if (crisisFlags.isNotEmpty) return ReportPriority.crisis;

    final lowerContent = content.toLowerCase();

    // High priority indicators
    if (lowerContent.contains('suicide') ||
        lowerContent.contains('kill myself') ||
        lowerContent.contains('end it all') ||
        lowerContent.contains('harassment')) {
      return ReportPriority.high;
    }

    // Medium priority indicators
    if (lowerContent.contains('inappropriate') ||
        lowerContent.contains('bullying') ||
        lowerContent.contains('spam')) {
      return ReportPriority.medium;
    }

    return ReportPriority.low;
  }
}
