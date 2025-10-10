import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/user_trust_level.dart';
import '../services/chat_safety_service.dart';
import '../services/chat_trust_service.dart';

class GroupSendMessageResult {
  final bool sent;
  final String? violationMessage;
  final bool kicked;

  const GroupSendMessageResult({
    required this.sent,
    this.violationMessage,
    this.kicked = false,
  });

  factory GroupSendMessageResult.fail() =>
      const GroupSendMessageResult(sent: false);

  // Getters for compatibility with UI expectations
  bool get wasBlocked => !sent;
  String? get feedback => violationMessage;
}

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static CollectionReference get _groups => _firestore.collection('groups');
  static CollectionReference get _groupMembers =>
      _firestore.collection('group_members');
  static CollectionReference get _groupMessages =>
      _firestore.collection('group_messages');

  /// Get all public groups with optional category filter
  static Stream<List<Group>> getPublicGroups({GroupCategory? category}) {
    Query query = _groups
        .where('isActive', isEqualTo: true)
        .where('privacy', isEqualTo: GroupPrivacy.public.name)
        .orderBy('memberCount', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList(),
    );
  }

  /// Search groups by name or description
  static Future<List<Group>> searchGroups(
    String searchTerm, {
    GroupCategory? category,
  }) async {
    try {
      // Basic search - in production you'd use Algolia or similar
      Query query = _groups
          .where('isActive', isEqualTo: true)
          .where('privacy', isEqualTo: GroupPrivacy.public.name);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final snapshot = await query.limit(50).get();
      final groups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .toList();

      // Client-side filtering by search term
      final searchLower = searchTerm.toLowerCase();
      return groups.where((group) {
        return group.name.toLowerCase().contains(searchLower) ||
            group.description.toLowerCase().contains(searchLower) ||
            group.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();
    } catch (e) {
      print('GroupService: Error searching groups: $e');
      return [];
    }
  }

  /// Get user's joined groups
  static Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collectionGroup('group_members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((memberSnapshot) async {
          try {
            final groupIds = memberSnapshot.docs
                .map((doc) => doc.data()['groupId'] as String?)
                .whereType<String>()
                .toSet()
                .toList();

            if (groupIds.isEmpty) return <Group>[];

            final List<Group> groups = [];
            const int chunkSize = 10;

            for (int i = 0; i < groupIds.length; i += chunkSize) {
              final end = (i + chunkSize) > groupIds.length
                  ? groupIds.length
                  : (i + chunkSize);
              final chunk = groupIds.sublist(i, end);

              final chunkSnapshot = await _groups
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();

              for (final doc in chunkSnapshot.docs) {
                try {
                  final group = Group.fromFirestore(doc);
                  if (group.isActive) groups.add(group);
                } catch (e) {
                  print('GroupService: Error parsing group ${doc.id}: $e');
                }
              }
            }

            groups.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
            return groups;
          } catch (e) {
            print('GroupService: Error getting user groups: $e');
            return <Group>[];
          }
        });
  }

  /// Create a new group
  static Future<String?> createGroup({
    required String name,
    required String description,
    required GroupCategory category,
    GroupPrivacy privacy = GroupPrivacy.public,
    List<String> tags = const [],
    String? avatarUrl,
    int maxMembers = 100,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Check if user can create groups
      final userProfile = await ChatTrustService.getUserChatProfile(
        currentUser.uid,
      );
      if (userProfile == null ||
          userProfile.trustLevel.level < UserTrustLevel.verified.level) {
        print('GroupService: User not authorized to create groups');
        return null;
      }

      final group = Group(
        id: '',
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        privacy: privacy,
        category: category,
        tags: tags,
        ownerId: currentUser.uid,
        adminIds: [currentUser.uid],
        moderatorIds: [],
        memberCount: 1,
        maxMembers: maxMembers,
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        settings: GroupSettings.defaultForPrivacy(privacy),
      );

      final docRef = await _groups.add(group.toFirestore());

      // Add creator as owner member
      await _addGroupMember(
        docRef.id,
        currentUser.uid,
        'Owner', // Display name - should come from user profile
        role: GroupMemberRole.owner,
      );

      print('GroupService: Group created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('GroupService: Error creating group: $e');
      return null;
    }
  }

  /// Join a group
  static Future<bool> joinGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if user can participate in groups
      final canParticipate = await ChatSafetyService.canUserParticipateInChat(
        currentUser.uid,
        groupId, // Reuse room logic for groups
      );
      if (!canParticipate) {
        print('GroupService: User cannot participate in this group');
        return false;
      }

      bool newlyJoined = false;

      await _firestore.runTransaction((txn) async {
        final groupRef = _groups.doc(groupId);
        final memberRef = _groupMembers.doc('${groupId}_${currentUser.uid}');

        final groupSnap = await txn.get(groupRef);
        if (!groupSnap.exists) {
          throw Exception('Group not found');
        }
        final group = Group.fromFirestore(groupSnap);

        final memberSnap = await txn.get(memberRef);
        if (memberSnap.exists) {
          // Already a member
          newlyJoined = false;
          return;
        }

        // Check capacity
        if (group.isFull) {
          throw Exception('Group is at maximum capacity');
        }

        // Check privacy rules
        if (group.privacy == GroupPrivacy.private ||
            group.privacy == GroupPrivacy.invitation_only) {
          // For now, reject - in full implementation you'd check invitations
          throw Exception('This group requires an invitation');
        }

        // Add member
        final member = GroupMember(
          id: '${groupId}_${currentUser.uid}',
          groupId: groupId,
          userId: currentUser.uid,
          displayName: currentUser.displayName ?? 'User',
          avatarUrl: currentUser.photoURL,
          joinedAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );

        txn.set(memberRef, member.toFirestore());
        txn.update(groupRef, {
          'memberCount': FieldValue.increment(1),
          'lastActivity': Timestamp.now(),
        });

        newlyJoined = true;
      });

      if (newlyJoined) {
        await _sendSystemMessage(groupId, 'A new member joined the group');
        print('GroupService: User ${currentUser.uid} joined group $groupId');
      }

      return true;
    } catch (e) {
      print('GroupService: Error joining group: $e');
      return false;
    }
  }

  /// Leave a group
  static Future<bool> leaveGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      bool left = false;

      await _firestore.runTransaction((txn) async {
        final groupRef = _groups.doc(groupId);
        final memberRef = _groupMembers.doc('${groupId}_${currentUser.uid}');

        final memberSnap = await txn.get(memberRef);
        if (!memberSnap.exists) {
          left = false;
          return;
        }

        final member = GroupMember.fromFirestore(memberSnap);

        // Prevent owner from leaving (they should transfer ownership first)
        if (member.isOwner) {
          throw Exception(
            'Owner cannot leave group. Transfer ownership first.',
          );
        }

        txn.delete(memberRef);
        txn.update(groupRef, {
          'memberCount': FieldValue.increment(-1),
          'lastActivity': Timestamp.now(),
        });
        left = true;
      });

      if (left) {
        print('GroupService: User ${currentUser.uid} left group $groupId');
      }

      return left;
    } catch (e) {
      print('GroupService: Error leaving group: $e');
      return false;
    }
  }

  /// Send message to group with safety checks
  static Future<GroupSendMessageResult> sendMessageWithFeedback({
    required String groupId,
    required String content,
    GroupMessageType type = GroupMessageType.text,
    List<String>? attachments,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return GroupSendMessageResult.fail();

      // Check if user is still a member and can send messages
      final member = await getGroupMember(groupId, currentUser.uid);
      if (member == null) {
        return const GroupSendMessageResult(
          sent: false,
          violationMessage: 'You are not a member of this group.',
        );
      }

      if (member.isMuted) {
        return const GroupSendMessageResult(
          sent: false,
          violationMessage: 'You have been muted in this group.',
        );
      }

      // Use the same safety system as chat rooms
      final userProfile = await ChatTrustService.getUserChatProfile(
        currentUser.uid,
      );
      final safetyResult = await ChatSafetyService.checkMessageSafety(
        content,
        currentUser.uid,
        groupId,
        userMoodLevel: userProfile?.vulnerabilityIndicators.currentMoodLevel,
      );

      // Handle crisis situations
      if (safetyResult.isCrisis) {
        await _handleCrisisMessage(
          currentUser.uid,
          content,
          groupId,
          safetyResult,
        );
        return const GroupSendMessageResult(
          sent: false,
          violationMessage:
              'We detected a crisis situation and provided support resources.',
        );
      }

      // Block inappropriate content and track violations
      if (!safetyResult.isAllowed) {
        print('GroupService: Message blocked - ${safetyResult.reason}');

        // Track violation for this group (reuse chat room violation logic)
        final violation = await ChatSafetyService.trackViolation(
          userId: currentUser.uid,
          roomId: groupId, // Use groupId as roomId for violation tracking
          violationType: safetyResult.reason.isNotEmpty
              ? safetyResult.reason
              : 'policy_violation',
          content: content,
        );

        // If kicked from group, remove member
        if (violation.action == ViolationAction.kick) {
          try {
            await leaveGroup(groupId);
          } catch (_) {}
        }

        return GroupSendMessageResult(
          sent: false,
          violationMessage: violation.message,
          kicked: violation.action == ViolationAction.kick,
        );
      }

      // Create and send message
      final message = GroupMessage(
        id: '',
        groupId: groupId,
        senderId: currentUser.uid,
        senderName: member.displayName,
        senderAvatar: member.avatarUrl,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        attachments: attachments ?? [],
        isFiltered: safetyResult.requiresModeration,
        safetyScore: safetyResult.safetyScore,
      );

      await _groupMessages.add(message.toFirestore());

      // Update group last activity
      await _groups.doc(groupId).update({'lastActivity': Timestamp.now()});

      // Update member last seen
      await _groupMembers.doc('${groupId}_${currentUser.uid}').update({
        'lastSeen': Timestamp.now(),
      });

      // Update user's chat time
      await ChatTrustService.updateChatTime(currentUser.uid, 1);

      print('GroupService: Message sent successfully to group $groupId');
      return const GroupSendMessageResult(sent: true);
    } catch (e) {
      print('GroupService: Error sending message: $e');
      return GroupSendMessageResult.fail();
    }
  }

  /// Get messages for a group
  static Stream<List<GroupMessage>> getGroupMessages(
    String groupId, {
    int limit = 50,
  }) {
    return _groupMessages
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMessage.fromFirestore(doc))
              .toList()
              .reversed
              .toList(),
        );
  }

  /// Get group members
  static Stream<List<GroupMember>> getGroupMembers(String groupId) {
    return _groupMembers
        .where('groupId', isEqualTo: groupId)
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMember.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get specific group member
  static Future<GroupMember?> getGroupMember(
    String groupId,
    String userId,
  ) async {
    try {
      final doc = await _groupMembers.doc('${groupId}_$userId').get();
      if (doc.exists) {
        return GroupMember.fromFirestore(doc);
      }
    } catch (e) {
      print('GroupService: Error getting group member: $e');
    }
    return null;
  }

  /// Check if user is member of group
  static Stream<bool> isUserInGroup(String groupId, String userId) {
    return _groupMembers
        .doc('${groupId}_$userId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Private helper methods

  static Future<void> _addGroupMember(
    String groupId,
    String userId,
    String displayName, {
    GroupMemberRole role = GroupMemberRole.member,
    String? avatarUrl,
  }) async {
    final member = GroupMember(
      id: '${groupId}_$userId',
      groupId: groupId,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
      joinedAt: DateTime.now(),
      lastSeen: DateTime.now(),
    );

    await _groupMembers.doc(member.id).set(member.toFirestore());
  }

  static Future<void> _sendSystemMessage(String groupId, String content) async {
    try {
      final systemMessage = GroupMessage.system(
        groupId: groupId,
        content: content,
      );

      await _groupMessages.add(systemMessage.toFirestore());
    } catch (e) {
      print('GroupService: Error sending system message: $e');
    }
  }

  static Future<void> _handleCrisisMessage(
    String userId,
    String content,
    String groupId,
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
      await _sendSystemMessage(groupId, crisisResponse);

      // Get coping suggestions
      final copingSuggestions = await ChatSafetyService.getCopingSuggestions(
        userId,
        content,
      );

      if (copingSuggestions.isNotEmpty) {
        final suggestionsText =
            '💡 **Immediate coping strategies:**\n${copingSuggestions.map((s) => '• $s').join('\n')}';
        await _sendSystemMessage(groupId, suggestionsText);
      }

      print(
        'GroupService: Crisis intervention triggered for user $userId in group $groupId',
      );
    } catch (e) {
      print('GroupService: Error handling crisis message: $e');
    }
  }

  /// Initialize some default public groups
  static Future<void> initializeDefaultGroups() async {
    try {
      final existingGroups = await _groups.limit(1).get();
      if (existingGroups.docs.isNotEmpty) {
        print('GroupService: Default groups already exist');
        return;
      }

      final defaultGroups = [
        {
          'name': 'Mental Health Support',
          'description':
              'A supportive community for sharing experiences and resources',
          'category': GroupCategory.support,
          'tags': ['mental health', 'support', 'community'],
        },
        {
          'name': 'Mindfulness & Meditation',
          'description':
              'Daily mindfulness practices and meditation discussions',
          'category': GroupCategory.lifestyle,
          'tags': ['mindfulness', 'meditation', 'wellness'],
        },
        {
          'name': 'Recovery Warriors',
          'description':
              'Celebrating recovery milestones and supporting each other',
          'category': GroupCategory.support,
          'tags': ['recovery', 'milestones', 'support'],
        },
        {
          'name': 'Art Therapy',
          'description': 'Express yourself through art and creative activities',
          'category': GroupCategory.hobby,
          'tags': ['art', 'creativity', 'therapy'],
        },
      ];

      for (final groupData in defaultGroups) {
        final group = Group(
          id: '',
          name: groupData['name'] as String,
          description: groupData['description'] as String,
          privacy: GroupPrivacy.public,
          category: groupData['category'] as GroupCategory,
          tags: List<String>.from(groupData['tags'] as List),
          ownerId: 'system',
          adminIds: ['system'],
          memberCount: 0,
          maxMembers: 500,
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
          settings: GroupSettings.defaultForPrivacy(GroupPrivacy.public),
        );

        await _groups.add(group.toFirestore());
      }

      print('GroupService: Default groups initialized');
    } catch (e) {
      print('GroupService: Error initializing default groups: $e');
    }
  }
}
