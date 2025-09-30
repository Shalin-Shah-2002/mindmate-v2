import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_chat_profile.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/gemini_ai_service.dart';
import '../models/user_trust_level.dart';
import '../services/content_filtering_service.dart';
import '../services/chat_trust_service.dart';

class ChatSafetyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _chatReports =>
      _firestore.collection('chat_reports');
  static CollectionReference get _moderationLog =>
      _firestore.collection('moderation_log');
  static CollectionReference get _crisisInterventions =>
      _firestore.collection('crisis_interventions');

  /// Enhanced message safety check using both basic filtering and Gemini AI
  static Future<MessageSafetyResult> checkMessageSafety(
    String content,
    String senderId,
    String roomId, {
    int? userMoodLevel,
    List<String>? recentMessages,
  }) async {
    try {
      // Get user's chat profile for personalized filtering
      final userProfile = await ChatTrustService.getUserChatProfile(senderId);
      if (userProfile == null) {
        return MessageSafetyResult(
          isAllowed: false,
          reason: 'User profile not found',
          requiresModeration: true,
        );
      }

      // Room-aware + user-aware basic filtering
      final room = await _getChatRoom(roomId);
      ContentFilterResult basicFilter;
      if (room?.safetyLevel == ChatRoomSafetyLevel.high) {
        basicFilter = SpecializedFilters.filterForCrisisRoom(content);
      } else if (userProfile.trustLevel.level == UserTrustLevel.newUser.level) {
        basicFilter = SpecializedFilters.filterForNewUser(content);
      } else if (room?.safetyLevel == ChatRoomSafetyLevel.low) {
        basicFilter = SpecializedFilters.filterForGeneralChat(content);
      } else {
        basicFilter = ContentFilteringService.filterMessage(content);
      }

      // Enhanced AI analysis using Gemini
      final aiAnalysis = await GeminiAIService.analyzeMessageContent(
        content,
        userMoodLevel:
            userMoodLevel ??
            userProfile.vulnerabilityIndicators.currentMoodLevel,
        recentMessages: recentMessages,
        userAge: 'adult', // Could be enhanced with actual age data
      );

      // Combine results for final decision
      final result = _combineAnalysisResults(
        basicFilter,
        aiAnalysis,
        userProfile,
      );

      // Handle crisis situations immediately
      if (result.isCrisis) {
        await _handleCrisisIntervention(senderId, content, roomId, aiAnalysis);
      }

      // Log moderation decisions
      await _logModerationDecision(senderId, content, roomId, result);

      return result;
    } catch (e) {
      print('ChatSafetyService: Error checking message safety: $e');
      // Fail safe - require moderation if error occurs
      return MessageSafetyResult(
        isAllowed: false,
        reason: 'Safety check failed',
        requiresModeration: true,
      );
    }
  }

  /// Report a message or user for inappropriate behavior
  static Future<bool> reportContent({
    required String reporterId,
    required String reportedUserId,
    required String chatRoomId,
    String? messageId,
    required String reason,
    required String description,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != reporterId) {
        return false;
      }

      // Auto-determine priority based on content
      final priority = ReportPriority.fromContent(description, []);

      final report = ChatReport(
        id: '', // Will be set by Firestore
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        chatRoomId: chatRoomId,
        messageId: messageId,
        reason: reason,
        description: description,
        status: ReportStatus.pending,
        priority: priority,
        createdAt: DateTime.now(),
      );

      await _chatReports.add(report.toFirestore());

      // Add safety flag to reported user
      await ChatTrustService.addSafetyFlag(reportedUserId, 'reported_$reason');

      // If high priority, trigger immediate review
      if (priority == ReportPriority.crisis ||
          priority == ReportPriority.high) {
        await _triggerUrgentReview(report);
      }

      print('ChatSafetyService: Report created successfully');
      return true;
    } catch (e) {
      print('ChatSafetyService: Error creating report: $e');
      return false;
    }
  }

  /// Block user from chat interactions
  static Future<bool> blockUserFromChat(
    String blockerId,
    String blockedUserId,
  ) async {
    try {
      await ChatTrustService.blockUser(blockerId, blockedUserId);

      // Log the blocking action
      await _logModerationAction(
        moderatorId: blockerId,
        action: 'user_blocked',
        targetUserId: blockedUserId,
        reason: 'User-initiated block',
      );

      return true;
    } catch (e) {
      print('ChatSafetyService: Error blocking user: $e');
      return false;
    }
  }

  /// Handle vulnerability-based restrictions
  static Future<bool> canUserParticipateInChat(
    String userId,
    String roomId,
  ) async {
    try {
      // If the user was kicked from this room recently, block participation
      final wasKicked = await isUserKickedFromRoom(userId, roomId);
      if (wasKicked) {
        return false;
      }

      final userProfile = await ChatTrustService.getUserChatProfile(userId);
      if (userProfile == null) return false;

      // Check daily chat limits
      if (userProfile.hasExceededDailyLimit()) {
        return false;
      }

      // Check vulnerability restrictions
      if (userProfile.vulnerabilityIndicators.needsSupervision) {
        // Only allow supervised rooms or mentor interactions
        final room = await _getChatRoom(roomId);
        if (room?.safetyLevel != ChatRoomSafetyLevel.high) {
          return false;
        }
      }

      // Check mood-based restrictions
      if (userProfile.vulnerabilityIndicators.currentMoodLevel <= 2) {
        // Severe depression - limit to crisis support rooms
        final room = await _getChatRoom(roomId);
        if (room?.topic != ChatRoomTopic.crisisSupport &&
            room?.safetyLevel != ChatRoomSafetyLevel.high) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('ChatSafetyService: Error checking user participation: $e');
      return false;
    }
  }

  /// Generate AI-powered crisis intervention response
  static Future<String> generateCrisisResponse(
    String userMessage,
    int moodLevel,
    List<String> crisisFlags,
  ) async {
    try {
      final aiResponse = await GeminiAIService.generateCrisisSupport(
        userMessage,
        moodLevel: moodLevel,
        crisisFlags: crisisFlags,
      );

      return aiResponse;
    } catch (e) {
      print('ChatSafetyService: Error generating crisis response: $e');
      return ContentFilteringService.generateCrisisResponse(crisisFlags);
    }
  }

  /// Get personalized coping suggestions
  static Future<List<String>> getCopingSuggestions(
    String userId,
    String currentMessage,
  ) async {
    try {
      final userProfile = await ChatTrustService.getUserChatProfile(userId);
      if (userProfile == null) return [];

      // TODO: Get user interests from profile
      final userInterests = ['music', 'reading', 'nature']; // Placeholder

      final suggestions = await GeminiAIService.generateCopingSuggestions(
        currentMessage,
        userProfile.vulnerabilityIndicators.currentMoodLevel,
        userInterests,
      );

      return suggestions;
    } catch (e) {
      print('ChatSafetyService: Error getting coping suggestions: $e');
      return [
        'Take a few deep breaths',
        'Step outside for fresh air',
        'Listen to calming music',
        'Reach out to a friend',
        'Practice a grounding exercise',
      ];
    }
  }

  /// Analyze conversation patterns for early intervention
  static Future<void> analyzeUserConversationPattern(
    String userId,
    List<String> recentMessages,
  ) async {
    try {
      final analysis = await GeminiAIService.analyzeConversationPattern(
        recentMessages,
        userId,
      );

      // Take action based on analysis
      if (analysis.riskLevel == 'high' || analysis.riskLevel == 'crisis') {
        await _triggerEarlyIntervention(userId, analysis);
      }

      // Update user's vulnerability indicators
      if (analysis.urgency == 'immediate') {
        final currentProfile = await ChatTrustService.getUserChatProfile(
          userId,
        );
        if (currentProfile != null) {
          final updatedIndicators = currentProfile.vulnerabilityIndicators
              .copyWith(
                needsSupervision: true,
                recentCrisisFlags:
                    currentProfile.vulnerabilityIndicators.recentCrisisFlags +
                    1,
              );

          await ChatTrustService.updateVulnerabilityIndicators(
            userId,
            updatedIndicators,
          );
        }
      }
    } catch (e) {
      print('ChatSafetyService: Error analyzing conversation pattern: $e');
    }
  }

  // Private helper methods

  static MessageSafetyResult _combineAnalysisResults(
    ContentFilterResult basicFilter,
    AIAnalysisResult aiAnalysis,
    UserChatProfile userProfile,
  ) {
    final isCrisis =
        aiAnalysis.crisisLevel >= 7 ||
        aiAnalysis.selfHarmLevel >= 7 ||
        basicFilter.requiresImmediateIntervention;

    final isPredatory = aiAnalysis.predatoryLevel >= 6;
    final isThreat = basicFilter.crisisFlags.contains('threat');
    final isHarassment = basicFilter.crisisFlags.contains(
      'harassment_profanity',
    );
    // Consider content "clearly safe" when both basic filter and AI agree
    final contentClearlySafe =
        basicFilter.isClean &&
        aiAnalysis.safetyScore >= 0.8 &&
        !aiAnalysis.requiresIntervention &&
        !isCrisis &&
        !isPredatory;

    // For new users with pre-moderation, don't flag "clearly safe" messages
    final preModerationPolicy =
        userProfile.trustLevel.chatPermissions.requiresPreModeration;

    final needsModeration =
        basicFilter.requiresModeration ||
        aiAnalysis.safetyScore < 0.6 ||
        (preModerationPolicy && !contentClearlySafe);

    // Block criteria: explicit threats/harassment, predatory, crisis, or very low AI safety
    final shouldBlock =
        isPredatory ||
        isThreat ||
        isHarassment ||
        basicFilter.shouldBlock ||
        aiAnalysis.safetyScore < 0.5 ||
        isCrisis;

    return MessageSafetyResult(
      isAllowed: !shouldBlock,
      isCrisis: isCrisis,
      isPredatory: isPredatory,
      requiresModeration: needsModeration,
      safetyScore: (basicFilter.safetyScore + aiAnalysis.safetyScore) / 2,
      reason: _buildReasonString(basicFilter, aiAnalysis),
      recommendedAction: aiAnalysis.recommendedAction,
      crisisFlags: basicFilter.crisisFlags,
    );
  }

  static String _buildReasonString(
    ContentFilterResult basic,
    AIAnalysisResult ai,
  ) {
    final reasons = <String>[];

    if (ai.crisisLevel >= 7) reasons.add('Crisis content detected');
    if (ai.predatoryLevel >= 6) reasons.add('Predatory behavior');
    if (basic.crisisFlags.isNotEmpty) {
      reasons.add('Safety flags: ${basic.crisisFlags.join(', ')}');
    }

    return reasons.isEmpty ? 'Content approved' : reasons.join('; ');
  }

  static Future<void> _handleCrisisIntervention(
    String userId,
    String content,
    String roomId,
    AIAnalysisResult analysis,
  ) async {
    try {
      // Log crisis intervention
      await _crisisInterventions.add({
        'userId': userId,
        'content': content.length > 100
            ? '${content.substring(0, 100)}...'
            : content, // Truncate long content
        'roomId': roomId,
        'crisisLevel': analysis.crisisLevel,
        'timestamp': Timestamp.now(),
        'interventionType': 'automatic',
        'status': 'triggered',
      });

      // Update user vulnerability indicators
      final currentProfile = await ChatTrustService.getUserChatProfile(userId);
      if (currentProfile != null) {
        final updatedIndicators = VulnerabilityIndicators(
          currentMoodLevel: 1, // Set to lowest
          recentCrisisFlags:
              currentProfile.vulnerabilityIndicators.recentCrisisFlags + 1,
          needsSupervision: true,
          lastCrisisEvent: DateTime.now(),
          triggerWords: currentProfile.vulnerabilityIndicators.triggerWords,
        );

        await ChatTrustService.updateVulnerabilityIndicators(
          userId,
          updatedIndicators,
        );
      }

      print(
        'ChatSafetyService: Crisis intervention triggered for user $userId',
      );
    } catch (e) {
      print('ChatSafetyService: Error handling crisis intervention: $e');

      // If we can't log to Firestore, at least try to update the user profile
      // This ensures crisis detection still has some effect even if logging fails
      if (e.toString().contains('permission-denied')) {
        print(
          'ChatSafetyService: Firestore permission denied, attempting local user profile update only',
        );
        try {
          final currentProfile = await ChatTrustService.getUserChatProfile(
            userId,
          );
          if (currentProfile != null) {
            final updatedIndicators = VulnerabilityIndicators(
              currentMoodLevel: 1,
              recentCrisisFlags:
                  currentProfile.vulnerabilityIndicators.recentCrisisFlags + 1,
              needsSupervision: true,
              lastCrisisEvent: DateTime.now(),
              triggerWords: currentProfile.vulnerabilityIndicators.triggerWords,
            );

            await ChatTrustService.updateVulnerabilityIndicators(
              userId,
              updatedIndicators,
            );
          }
        } catch (profileError) {
          print(
            'ChatSafetyService: Error updating user profile: $profileError',
          );
        }
      }
    }
  }

  static Future<void> _logModerationDecision(
    String userId,
    String content,
    String roomId,
    MessageSafetyResult result,
  ) async {
    try {
      await _moderationLog.add({
        'userId': userId,
        'content': content.length > 100
            ? '${content.substring(0, 100)}...'
            : content,
        'roomId': roomId,
        'decision': result.isAllowed ? 'approved' : 'blocked',
        'reason': result.reason,
        'safetyScore': result.safetyScore,
        'isCrisis': result.isCrisis,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('ChatSafetyService: Error logging moderation decision: $e');
    }
  }

  static Future<void> _triggerUrgentReview(ChatReport report) async {
    // TODO: Implement urgent review system
    // This could send notifications to moderators, create tickets, etc.
    print('ChatSafetyService: Urgent review triggered for report ${report.id}');
  }

  static Future<void> _triggerEarlyIntervention(
    String userId,
    ConversationAnalysis analysis,
  ) async {
    try {
      // Log early intervention
      await _firestore.collection('early_interventions').add({
        'userId': userId,
        'riskLevel': analysis.riskLevel,
        'concernAreas': analysis.concernAreas,
        'recommendedActions': analysis.recommendedActions,
        'urgency': analysis.urgency,
        'timestamp': Timestamp.now(),
        'status': 'triggered',
      });

      print('ChatSafetyService: Early intervention triggered for user $userId');
    } catch (e) {
      print('ChatSafetyService: Error triggering early intervention: $e');

      // Continue with user profile updates even if logging fails
      if (e.toString().contains('permission-denied')) {
        print(
          'ChatSafetyService: Firestore permission denied for early intervention logging',
        );
      }
    }
  }

  static Future<void> _logModerationAction({
    required String moderatorId,
    required String action,
    String? targetUserId,
    String? reason,
  }) async {
    try {
      await _moderationLog.add({
        'moderatorId': moderatorId,
        'action': action,
        'targetUserId': targetUserId,
        'reason': reason,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('ChatSafetyService: Error logging moderation action: $e');
    }
  }

  static Future<ChatRoom?> _getChatRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
    } catch (e) {
      print('ChatSafetyService: Error getting chat room: $e');
    }
    return null;
  }

  /// Track safety violations and handle warnings/kicks
  static Future<ViolationResult> trackViolation({
    required String userId,
    required String roomId,
    required String violationType,
    required String content,
  }) async {
    try {
      // Check current violation count for this user in this room
      final violationQuery = await _firestore
          .collection('safety_violations')
          .where('userId', isEqualTo: userId)
          .where('roomId', isEqualTo: roomId)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 24)),
            ),
          )
          .get();

      final currentViolations =
          violationQuery.docs.length + 1; // +1 for current violation

      // Log the new violation
      await _firestore.collection('safety_violations').add({
        'userId': userId,
        'roomId': roomId,
        'violationType': violationType,
        'content': content.length > 100
            ? '${content.substring(0, 100)}...'
            : content,
        'timestamp': Timestamp.now(),
        'violationNumber': currentViolations,
      });

      // Determine action based on violation count
      if (currentViolations >= 3) {
        // Kick user from room
        await _kickUserFromRoom(userId, roomId, 'Multiple safety violations');

        // Add safety flag to user profile
        await ChatTrustService.addSafetyFlag(userId, 'kicked_for_violations');

        return ViolationResult(
          violationCount: currentViolations,
          action: ViolationAction.kick,
          message:
              'You have been removed from this room due to repeated safety violations.',
        );
      } else if (currentViolations == 2) {
        // Final warning
        return ViolationResult(
          violationCount: currentViolations,
          action: ViolationAction.finalWarning,
          message:
              'Final Warning: Your message was blocked. One more violation will result in removal from this room.',
        );
      } else {
        // First warning
        return ViolationResult(
          violationCount: currentViolations,
          action: ViolationAction.warning,
          message:
              'Warning: Your message was blocked for safety reasons. Please follow community guidelines.',
        );
      }
    } catch (e) {
      print('ChatSafetyService: Error tracking violation: $e');
      return ViolationResult(
        violationCount: 1,
        action: ViolationAction.warning,
        message: 'Your message was blocked for safety reasons.',
      );
    }
  }

  /// Remove user from chat room
  static Future<bool> _kickUserFromRoom(
    String userId,
    String roomId,
    String reason,
  ) async {
    try {
      // Remove from participants
      await _firestore
          .collection('chat_room_participants')
          .doc(roomId)
          .collection('participants')
          .doc(userId)
          .delete();

      // Update room participant count
      final roomRef = _firestore.collection('chat_rooms').doc(roomId);
      await roomRef.update({'participantCount': FieldValue.increment(-1)});

      // Add system message about user being removed
      await _firestore
          .collection('chat_messages')
          .doc(roomId)
          .collection('messages')
          .add({
            'senderId': 'system',
            'content':
                'A user was removed from the room for violating community guidelines.',
            'timestamp': Timestamp.now(),
            'type': 'system',
            'isFiltered': false,
            'safetyScore': 1.0,
            'reportCount': 0,
            'metadata': {
              'isSystemMessage': true,
              'moderatorNote': reason,
              'edited': false,
              'crisisFlags': [],
              'moderatorApproved': true,
            },
            'attachments': [],
          });

      // Log the kick action
      await _logModerationAction(
        moderatorId: 'system',
        action: 'user_kicked',
        targetUserId: userId,
        reason: reason,
      );

      print('ChatSafetyService: User $userId kicked from room $roomId');
      return true;
    } catch (e) {
      print('ChatSafetyService: Error kicking user from room: $e');
      return false;
    }
  }

  /// Check if user has been kicked from a room
  static Future<bool> isUserKickedFromRoom(String userId, String roomId) async {
    try {
      // Check for recent kick actions
      final kickQuery = await _moderationLog
          .where('action', isEqualTo: 'user_kicked')
          .where('targetUserId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 24)),
            ),
          )
          .limit(1)
          .get();

      return kickQuery.docs.isNotEmpty;
    } catch (e) {
      print('ChatSafetyService: Error checking kick status: $e');
      return false;
    }
  }
}

class MessageSafetyResult {
  final bool isAllowed;
  final bool isCrisis;
  final bool isPredatory;
  final bool requiresModeration;
  final double safetyScore;
  final String reason;
  final String recommendedAction;
  final List<String> crisisFlags;

  MessageSafetyResult({
    required this.isAllowed,
    this.isCrisis = false,
    this.isPredatory = false,
    this.requiresModeration = false,
    this.safetyScore = 1.0,
    this.reason = '',
    this.recommendedAction = '',
    this.crisisFlags = const [],
  });
}

/// Enum for violation actions
enum ViolationAction { warning, finalWarning, kick }

/// Result of violation tracking
class ViolationResult {
  final int violationCount;
  final ViolationAction action;
  final String message;

  ViolationResult({
    required this.violationCount,
    required this.action,
    required this.message,
  });
}

// Extension methods for vulnerability indicators
extension VulnerabilityIndicatorsExtension on VulnerabilityIndicators {
  VulnerabilityIndicators copyWith({
    int? currentMoodLevel,
    int? recentCrisisFlags,
    bool? needsSupervision,
    DateTime? lastCrisisEvent,
    List<String>? triggerWords,
  }) {
    return VulnerabilityIndicators(
      currentMoodLevel: currentMoodLevel ?? this.currentMoodLevel,
      recentCrisisFlags: recentCrisisFlags ?? this.recentCrisisFlags,
      needsSupervision: needsSupervision ?? this.needsSupervision,
      lastCrisisEvent: lastCrisisEvent ?? this.lastCrisisEvent,
      triggerWords: triggerWords ?? this.triggerWords,
    );
  }
}
