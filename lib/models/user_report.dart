import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportCategory {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  inappropriateContent('inappropriate_content', 'Inappropriate Content'),
  selfHarm('self_harm', 'Self Harm or Suicide'),
  hate('hate', 'Hate Speech'),
  violence('violence', 'Violence or Threats'),
  impersonation('impersonation', 'Impersonation'),
  privacy('privacy', 'Privacy Violation'),
  other('other', 'Other');

  const ReportCategory(this.value, this.displayName);
  final String value;
  final String displayName;

  static ReportCategory fromString(String value) {
    return ReportCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ReportCategory.other,
    );
  }
}

enum ReportStatus {
  pending('pending', 'Pending Review'),
  underReview('under_review', 'Under Review'),
  resolved('resolved', 'Resolved'),
  dismissed('dismissed', 'Dismissed');

  const ReportStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

enum ReportType {
  user('user'),
  message('message'),
  post('post'),
  conversation('conversation');

  const ReportType(this.value);
  final String value;

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReportType.user,
    );
  }
}

class UserReport {
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
  final ReportType type;
  final ReportCategory category;
  final String description;
  final String? contentId; // Message ID, Post ID, or Conversation ID
  final DateTime createdAt;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? actionTaken;
  final Map<String, dynamic>? metadata;

  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.type,
    required this.category,
    required this.description,
    this.contentId,
    required this.createdAt,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.actionTaken,
    this.metadata,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      type: ReportType.fromString(data['type'] ?? 'user'),
      category: ReportCategory.fromString(data['category'] ?? 'other'),
      description: data['description'] ?? '',
      contentId: data['contentId'],
      createdAt: _parseDate(data['createdAt']),
      status: ReportStatus.fromString(data['status'] ?? 'pending'),
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null
          ? _parseDate(data['reviewedAt'])
          : null,
      reviewNotes: data['reviewNotes'],
      actionTaken: data['actionTaken'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'type': type.value,
      'category': category.value,
      'description': description,
      'contentId': contentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.value,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNotes': reviewNotes,
      'actionTaken': actionTaken,
      'metadata': metadata,
    };
  }

  UserReport copyWith({
    ReportStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? actionTaken,
    Map<String, dynamic>? metadata,
  }) {
    return UserReport(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      type: type,
      category: category,
      description: description,
      contentId: contentId,
      createdAt: createdAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      actionTaken: actionTaken ?? this.actionTaken,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Model for tracking user block relationships
class UserBlock {
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
  final String blockerId; // User who initiated the block
  final String blockedUserId; // User who was blocked
  final DateTime createdAt;
  final String? reason;
  final bool isActive;

  const UserBlock({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
    this.reason,
    required this.isActive,
  });

  factory UserBlock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserBlock(
      id: doc.id,
      blockerId: data['blockerId'] ?? '',
      blockedUserId: data['blockedUserId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      reason: data['reason'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'reason': reason,
      'isActive': isActive,
    };
  }

  // Generate block ID from two user IDs (consistent with blocker first)
  static String generateBlockId(String blockerId, String blockedUserId) {
    return '${blockerId}_blocks_$blockedUserId';
  }

  UserBlock copyWith({String? reason, bool? isActive}) {
    return UserBlock(
      id: id,
      blockerId: blockerId,
      blockedUserId: blockedUserId,
      createdAt: createdAt,
      reason: reason ?? this.reason,
      isActive: isActive ?? this.isActive,
    );
  }
}
