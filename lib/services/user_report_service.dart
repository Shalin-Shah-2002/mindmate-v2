import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_report.dart';

class UserReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _reports =>
      _firestore.collection('user_reports');

  /// Submit a report about a user
  static Future<bool> reportUser({
    required String reportedUserId,
    required ReportCategory category,
    required String description,
    ReportType type = ReportType.user,
    String? contentId, // For message/post reports
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('UserReportService: No authenticated user');
        return false;
      }

      final reporterId = currentUser.uid;

      // Prevent self-reporting
      if (reporterId == reportedUserId) {
        print('UserReportService: Cannot report yourself');
        return false;
      }

      // Check if user has already reported this user/content recently
      if (await _hasRecentReport(reporterId, reportedUserId, contentId)) {
        print('UserReportService: Recent report already exists');
        return false;
      }

      // Create report
      final report = UserReport(
        id: '', // Will be set by Firestore
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        type: type,
        category: category,
        description: description,
        contentId: contentId,
        createdAt: DateTime.now(),
        status: ReportStatus.pending,
        metadata: metadata,
      );

      // Save report to Firestore
      final docRef = await _reports.add(report.toFirestore());
      print('UserReportService: Report submitted with ID: ${docRef.id}');

      // Update reported user's report count (for tracking purposes)
      await _incrementUserReportCount(reportedUserId);

      return true;
    } catch (e) {
      print('UserReportService: Error submitting report: $e');
      return false;
    }
  }

  /// Report a private message
  static Future<bool> reportMessage({
    required String messageId,
    required String reportedUserId,
    required ReportCategory category,
    required String description,
    String? conversationId,
  }) async {
    return await reportUser(
      reportedUserId: reportedUserId,
      category: category,
      description: description,
      type: ReportType.message,
      contentId: messageId,
      metadata: conversationId != null
          ? {'conversationId': conversationId}
          : null,
    );
  }

  /// Report a conversation (entire private chat)
  static Future<bool> reportConversation({
    required String conversationId,
    required String reportedUserId,
    required ReportCategory category,
    required String description,
  }) async {
    return await reportUser(
      reportedUserId: reportedUserId,
      category: category,
      description: description,
      type: ReportType.conversation,
      contentId: conversationId,
    );
  }

  /// Get reports submitted by current user
  static Stream<List<UserReport>> getUserReportsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _reports
        .where('reporterId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserReport.fromFirestore(doc))
              .toList();
        });
  }

  /// Get reports about current user (for user awareness)
  static Stream<List<UserReport>> getReportsAboutUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _reports
        .where('reportedUserId', isEqualTo: currentUser.uid)
        .where(
          'status',
          whereIn: [ReportStatus.pending.value, ReportStatus.underReview.value],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserReport.fromFirestore(doc))
              .toList();
        });
  }

  /// Check if user has reported another user recently (prevent spam reporting)
  static Future<bool> _hasRecentReport(
    String reporterId,
    String reportedUserId,
    String? contentId,
  ) async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

      Query query = _reports
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime));

      // If specific content, check for duplicate content reports
      if (contentId != null) {
        query = query.where('contentId', isEqualTo: contentId);
      }

      final snapshot = await query.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('UserReportService: Error checking recent reports: $e');
      return false;
    }
  }

  /// Increment the report count for a user
  static Future<void> _incrementUserReportCount(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentCount = userDoc.data()?['reportCount'] ?? 0;
          transaction.update(userRef, {
            'reportCount': currentCount + 1,
            'lastReportedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
    } catch (e) {
      print('UserReportService: Error updating user report count: $e');
    }
  }

  /// Get report statistics for a user (admin/moderation use)
  static Future<Map<String, int>> getUserReportStats(String userId) async {
    try {
      final snapshot = await _reports
          .where('reportedUserId', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'underReview': 0,
        'resolved': 0,
        'dismissed': 0,
      };

      for (final doc in snapshot.docs) {
        final report = UserReport.fromFirestore(doc);
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[report.status.value] = (stats[report.status.value] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('UserReportService: Error getting user report stats: $e');
      return {};
    }
  }

  /// Check if current user can report another user
  static Future<bool> canReportUser(String reportedUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Cannot report yourself
      if (currentUser.uid == reportedUserId) return false;

      // Check for recent reports
      return !await _hasRecentReport(currentUser.uid, reportedUserId, null);
    } catch (e) {
      print('UserReportService: Error checking if can report user: $e');
      return false;
    }
  }

  /// Get count of pending reports (for admin/moderation)
  static Stream<int> getPendingReportsCount() {
    return _reports
        .where('status', isEqualTo: ReportStatus.pending.value)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Update report status (admin/moderation function)
  static Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? reviewedBy,
    String? reviewNotes,
    String? actionTaken,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (reviewedBy != null) updateData['reviewedBy'] = reviewedBy;
      if (reviewNotes != null) updateData['reviewNotes'] = reviewNotes;
      if (actionTaken != null) updateData['actionTaken'] = actionTaken;

      await _reports.doc(reportId).update(updateData);
      return true;
    } catch (e) {
      print('UserReportService: Error updating report status: $e');
      return false;
    }
  }

  /// Delete a report (admin function)
  static Future<bool> deleteReport(String reportId) async {
    try {
      await _reports.doc(reportId).delete();
      return true;
    } catch (e) {
      print('UserReportService: Error deleting report: $e');
      return false;
    }
  }

  /// Get all reports for moderation (admin function)
  static Stream<List<UserReport>> getAllReportsStream({
    ReportStatus? status,
    ReportCategory? category,
    int limit = 50,
  }) {
    Query query = _reports.orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category.value);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserReport.fromFirestore(doc)).toList();
    });
  }
}
