import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Direct initialization since Firebase is now properly configured
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
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
        final UserCredential result = await _auth.signInWithCredential(credential);
        authStateSubscription.cancel();
        print('Firebase sign-in successful: ${result.user?.uid}');
        return result.user;
      } catch (credentialError) {
        print('signInWithCredential failed: $credentialError');
        
        // If this is the type casting error, wait and check if authentication actually succeeded
        if (credentialError.toString().contains('List<Object?>') || 
            credentialError.toString().contains('PigeonUserDetails')) {
          print('Type casting error detected, checking if authentication succeeded...');
          
          // Wait for auth state to potentially update
          await Future.delayed(const Duration(seconds: 2));
          
          authStateSubscription.cancel();
          
          // Check if we caught a successful authentication via the listener
          if (authenticatedUser != null) {
            print('Authentication succeeded despite error: ${authenticatedUser!.uid}');
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
        
        throw credentialError;
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
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
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
      await _firestore.collection('users').doc(user.id).set(user.toMap());
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
}
