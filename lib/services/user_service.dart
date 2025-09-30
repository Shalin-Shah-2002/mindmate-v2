import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Search users by name
  /// Returns a list of users whose names contain the search query (case-insensitive)
  Future<List<UserModel>> searchUsersByName(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final String searchQuery = query.trim().toLowerCase();

      // Get all users and filter by name on client side
      // This is needed because Firestore doesn't support case-insensitive partial text search
      final QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .limit(50) // Limit results to prevent excessive data loading
          .get();

      final List<UserModel> searchResults = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data, doc.id);

          // Check if user name contains the search query (case-insensitive)
          if (user.name.toLowerCase().contains(searchQuery)) {
            // For private users, create a limited version that doesn't expose sensitive info
            if (user.isPrivate) {
              final limitedUser = UserModel(
                id: user.id,
                name: user.name,
                email: '', // Don't expose email for private users
                photoUrl:
                    user.photoUrl, // Profile photo is usually okay to show
                bio: '', // Don't expose bio for private users
                dob: DateTime.now(), // Don't expose real DOB
                moodPreferences: [], // Don't expose mood preferences
                createdAt: user.createdAt,
                followers: [], // Don't expose follower lists
                following: [], // Don't expose following lists
                isPrivate: user.isPrivate,
                sosContacts: [], // Don't expose SOS contacts
                settings: UserSettings(
                  darkMode: false,
                  fontSize: 'medium',
                  ttsEnabled: false,
                ), // Don't expose real settings
              );
              searchResults.add(limitedUser);
            } else {
              // For public users, show full profile data
              searchResults.add(user);
            }
          }
        } catch (e) {
          // Skip invalid user documents
          print('UserService: Error parsing user document ${doc.id}: $e');
          continue;
        }
      }

      // Sort results by name similarity (exact matches first)
      searchResults.sort((a, b) {
        final aLower = a.name.toLowerCase();
        final bLower = b.name.toLowerCase();

        // Exact matches first
        if (aLower == searchQuery && bLower != searchQuery) return -1;
        if (bLower == searchQuery && aLower != searchQuery) return 1;

        // Names starting with query next
        final aStarts = aLower.startsWith(searchQuery);
        final bStarts = bLower.startsWith(searchQuery);
        if (aStarts && !bStarts) return -1;
        if (bStarts && !aStarts) return 1;

        // Alphabetical order for remaining
        return aLower.compareTo(bLower);
      });

      return searchResults;
    } catch (e) {
      print('UserService: Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      print('UserService: Error getting user by ID: $e');
      return null;
    }
  }

  /// Get multiple users by their IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final List<UserModel> users = [];

      // Firestore 'in' queries are limited to 10 items, so we batch them
      const int batchSize = 10;

      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final QuerySnapshot snapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(data, doc.id);
            users.add(user);
          } catch (e) {
            print('UserService: Error parsing user document ${doc.id}: $e');
            continue;
          }
        }
      }

      return users;
    } catch (e) {
      print('UserService: Error getting users by IDs: $e');
      return [];
    }
  }

  /// Search users with pagination support
  Future<List<UserModel>> searchUsersWithPagination(
    String query, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      Query queryRef = _firestore.collection(_usersCollection).limit(limit);

      if (lastDocument != null) {
        queryRef = queryRef.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await queryRef.get();
      final String searchQuery = query.trim().toLowerCase();
      final List<UserModel> searchResults = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data, doc.id);

          // Check if user name contains the search query (case-insensitive)
          if (user.name.toLowerCase().contains(searchQuery)) {
            // For private users, create a limited version that doesn't expose sensitive info
            if (user.isPrivate) {
              final limitedUser = UserModel(
                id: user.id,
                name: user.name,
                email: '', // Don't expose email for private users
                photoUrl:
                    user.photoUrl, // Profile photo is usually okay to show
                bio: '', // Don't expose bio for private users
                dob: DateTime.now(), // Don't expose real DOB
                moodPreferences: [], // Don't expose mood preferences
                createdAt: user.createdAt,
                followers: [], // Don't expose follower lists
                following: [], // Don't expose following lists
                isPrivate: user.isPrivate,
                sosContacts: [], // Don't expose SOS contacts
                settings: UserSettings(
                  darkMode: false,
                  fontSize: 'medium',
                  ttsEnabled: false,
                ), // Don't expose real settings
              );
              searchResults.add(limitedUser);
            } else {
              // For public users, show full profile data
              searchResults.add(user);
            }
          }
        } catch (e) {
          print('UserService: Error parsing user document ${doc.id}: $e');
          continue;
        }
      }

      return searchResults;
    } catch (e) {
      print('UserService: Error searching users with pagination: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Follow a user
  Future<bool> followUser(String userIdToFollow) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final currentUserId = currentUser.uid;
      if (currentUserId == userIdToFollow) {
        return false; // Can't follow yourself
      }

      final batch = _firestore.batch();

      // Add to current user's following list
      final currentUserRef = _firestore
          .collection(_usersCollection)
          .doc(currentUserId);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([userIdToFollow]),
      });

      // Add to target user's followers list
      final targetUserRef = _firestore
          .collection(_usersCollection)
          .doc(userIdToFollow);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('UserService: Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String userIdToUnfollow) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final currentUserId = currentUser.uid;
      if (currentUserId == userIdToUnfollow) {
        return false; // Can't unfollow yourself
      }

      final batch = _firestore.batch();

      // Remove from current user's following list
      final currentUserRef = _firestore
          .collection(_usersCollection)
          .doc(currentUserId);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([userIdToUnfollow]),
      });

      // Remove from target user's followers list
      final targetUserRef = _firestore
          .collection(_usersCollection)
          .doc(userIdToUnfollow);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('UserService: Error unfollowing user: $e');
      return false;
    }
  }
}
