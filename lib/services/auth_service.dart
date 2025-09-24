import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Direct initialization since Firebase is now properly configured
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      // If Firebase is not initialized, return a stream with null
      return Stream.value(null);
    }
  }

  // Sign in with Google - Updated approach for type casting issue
  Future<User?> signInWithGoogle() async {
    User? authenticatedUser;

    // Set up auth state listener to catch successful authentication
    late final StreamSubscription<User?> authStateSubscription;
    authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null && authenticatedUser == null) {
        authenticatedUser = user;
        print('Auth state detected successful authentication: ${user.uid}');
      }
    });

    try {
      print('Starting Google Sign-In process...');

      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      print('Cleared previous Google Sign-In state');

      // Trigger the authentication flow
      print('Triggering Google Sign-In dialog...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User canceled Google sign-in');
        authStateSubscription.cancel();
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Get authentication details
      print('Getting Google authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Failed to get Google auth tokens');
        authStateSubscription.cancel();
        return null;
      }

      print('Google auth tokens obtained successfully');

      // Create Firebase credential
      print('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Attempt Firebase sign-in
      print('Signing in to Firebase with Google credential...');
      try {
        final UserCredential result = await _auth.signInWithCredential(
          credential,
        );
        authStateSubscription.cancel();
        print('Firebase sign-in successful: ${result.user?.uid}');
        return result.user;
      } catch (credentialError) {
        print('signInWithCredential failed: $credentialError');

        // If this is the type casting error, wait and check if authentication actually succeeded
        if (credentialError.toString().contains('List<Object?>') ||
            credentialError.toString().contains('PigeonUserDetails')) {
          print(
            'Type casting error detected, checking if authentication succeeded...',
          );

          // Wait for auth state to potentially update
          await Future.delayed(const Duration(seconds: 2));

          authStateSubscription.cancel();

          // Check if we caught a successful authentication via the listener
          if (authenticatedUser != null) {
            print(
              'Authentication succeeded despite error: ${authenticatedUser!.uid}',
            );
            return authenticatedUser;
          }

          // Also check current user
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Found authenticated user: ${currentUser.uid}');
            return currentUser;
          }

          print('Authentication did not succeed');
        }

        rethrow;
      }
    } catch (e, stackTrace) {
      print('Google Sign-In failed: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');

      authStateSubscription.cancel();

      // Try cleanup
      try {
        await _googleSignIn.signOut();
        print('Cleanup sign out completed');
      } catch (signOutError) {
        print('Error during cleanup sign out: $signOutError');
      }

      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      await _googleSignIn.signOut();
      print('Google Sign-In signed out');
      await _auth.signOut();
      print('Firebase Auth signed out');
    } catch (e) {
      print('Error signing out: $e');
      rethrow; // Re-throw to let the calling code handle it
    }
  }

  // Check if user profile exists in Firestore
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }

  // Save user profile to Firestore
  Future<bool> saveUserProfile(UserModel user) async {
    try {
      final data = user.toMap();
      // Add normalized fields to support efficient search
      data['nameLower'] = (user.name).toLowerCase();
      data['emailLower'] = (user.email).toLowerCase();
      // Also store displayNameLower for compatibility with older docs
      data['displayNameLower'] =
          (data['displayName'] is String &&
              (data['displayName'] as String).isNotEmpty)
          ? (data['displayName'] as String).toLowerCase()
          : (user.name).toLowerCase();
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Follow a user
  Future<bool> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Add targetUserId to current user's following list
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([targetUserId]),
      });

      // Add currentUserId to target user's followers list
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Remove targetUserId from current user's following list
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      // Remove currentUserId from target user's followers list
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists && doc.data() != null) {
        final following = List<String>.from(doc.data()!['following'] ?? []);
        return following.contains(targetUserId);
      }
      return false;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Get followers list for a user
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final followerIds = List<String>.from(doc.data()!['followers'] ?? []);

        if (followerIds.isEmpty) return [];

        final followers = <UserModel>[];
        for (final followerId in followerIds) {
          final follower = await getUserProfile(followerId);
          if (follower != null) {
            followers.add(follower);
          }
        }
        return followers;
      }
      return [];
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following list for a user
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final followingIds = List<String>.from(doc.data()!['following'] ?? []);

        if (followingIds.isEmpty) return [];

        final following = <UserModel>[];
        for (final followingId in followingIds) {
          final user = await getUserProfile(followingId);
          if (user != null) {
            following.add(user);
          }
        }
        return following;
      }
      return [];
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Update user's social data (for testing/development)
  Future<bool> updateUserSocialData(
    String userId, {
    List<String>? followers,
    List<String>? following,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (followers != null) {
        updateData['followers'] = followers;
      }

      if (following != null) {
        updateData['following'] = following;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }

      return true;
    } catch (e) {
      print('Error updating user social data: $e');
      return false;
    }
  }
}
