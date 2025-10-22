import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../views/auth/profile_form_view.dart';
import '../views/auth/login_view.dart';
import '../views/main_navigation_view.dart';

class AuthViewModel extends GetxController {
  final AuthService _authService = AuthService();

  // Observable variables
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Getters
  User? get user => _firebaseUser.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoggedIn => _firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes only if Firebase is available
    _initializeAuthListener();

    // Also check if there's already a current user
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    try {
      isLoading.value = true; // Set loading during initial check
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print(
          'AuthViewModel: Found existing user ${currentUser.uid}, loading profile...',
        );
        await _loadUserProfile(currentUser.uid);
      }
    } catch (e) {
      print('AuthViewModel: Error checking current user: $e');
      errorMessage.value = 'Error checking authentication status';
    } finally {
      isLoading.value = false;
    }
  }

  void _initializeAuthListener() {
    try {
      // Bind stream and listen to changes to load user profile
      _firebaseUser.bindStream(_authService.authStateChanges);

      // Listen to Firebase user changes and load user profile accordingly
      ever(_firebaseUser, (User? firebaseUser) async {
        if (firebaseUser != null) {
          print('AuthViewModel: Firebase user detected, loading profile...');
          // Only load profile if we don't have one yet to avoid conflicts
          if (_userModel.value == null) {
            await _loadUserProfile(firebaseUser.uid);
          }
        } else {
          print('AuthViewModel: No Firebase user, clearing profile...');
          _userModel.value = null;
          errorMessage.value = '';
        }
      });
    } catch (e) {
      print('Firebase not initialized, auth listener disabled: $e');
      // Set user as null if Firebase is not available
      _firebaseUser.value = null;
    }
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      print('AuthViewModel: Loading user profile for $userId...');
      final userProfile = await _authService.getUserProfile(userId);
      if (userProfile != null) {
        _userModel.value = userProfile;
        print('AuthViewModel: User profile loaded successfully');

        // Update FCM token when user logs in
        try {
          await NotificationService.updateFCMToken();
          print('AuthViewModel: Push identity synced (OneSignal)');
        } catch (e) {
          print('AuthViewModel: Error updating FCM token: $e');
          // Don't fail login if FCM token update fails
        }
      } else {
        print('AuthViewModel: No user profile found in Firestore');
        _userModel.value = null;
      }
    } catch (e) {
      print('AuthViewModel: Error loading user profile: $e');
      _userModel.value = null;
    }
  }

  // Public method to refresh user profile
  Future<void> refreshUserProfile() async {
    if (_firebaseUser.value?.uid == null) {
      print('AuthViewModel: Cannot refresh profile - no user logged in');
      return;
    }

    try {
      isLoading.value = true;
      print('AuthViewModel: Refreshing user profile...');
      await _loadUserProfile(_firebaseUser.value!.uid);
      print('AuthViewModel: Profile refresh completed');
    } catch (e) {
      print('AuthViewModel: Error refreshing user profile: $e');
      errorMessage.value = 'Failed to load profile. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('AuthViewModel: Starting Google Sign-In...');

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        print('AuthViewModel: Google Sign-In successful, checking profile...');
        // Check if user profile exists in Firestore
        final profileExists = await _authService.userProfileExists(user.uid);

        if (profileExists) {
          print('AuthViewModel: User profile exists, loading profile...');
          // User has completed profile, load it and go to main navigation
          final userProfile = await _authService.getUserProfile(user.uid);
          _userModel.value = userProfile;
          print('AuthViewModel: Navigating to main navigation...');
          Get.offAll(() => const MainNavigationView());
        } else {
          print(
            'AuthViewModel: User needs to complete profile, navigating to profile form...',
          );
          // User needs to complete profile
          Get.offAll(() => ProfileFormView(firebaseUser: user));
        }
      } else {
        print(
          'AuthViewModel: Google Sign-In returned null (user may have canceled)',
        );
        errorMessage.value =
            'Sign-in was canceled or failed. Please try again.';
        Get.snackbar(
          'Sign-In Canceled',
          'Please try signing in again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      print('AuthViewModel: Error during Google Sign-In: $e');
      print('AuthViewModel: Stack trace: $stackTrace');

      errorMessage.value = 'Failed to sign in with Google. Please try again.';
      Get.snackbar(
        'Sign-In Error',
        'There was a problem signing in. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Save user profile after form completion
  Future<void> saveUserProfile(UserModel userModel) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await _authService.saveUserProfile(userModel);

      if (success) {
        _userModel.value = userModel;
        Get.offAll(() => const MainNavigationView());
        Get.snackbar(
          'Success',
          'Profile created successfully!',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Failed to save profile');
      }
    } catch (e) {
      errorMessage.value = 'Failed to save profile: ${e.toString()}';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      print('AuthViewModel: Starting sign out...');

      // Delete FCM token before signing out
      try {
        await NotificationService.deleteFCMToken();
        print('AuthViewModel: Push identity cleared (OneSignal)');
      } catch (e) {
        print('AuthViewModel: Error deleting FCM token: $e');
        // Continue with sign out even if token deletion fails
      }

      await _authService.signOut();
      print('AuthViewModel: Sign out completed');

      _userModel.value = null;
      _firebaseUser.value = null;

      // Clear any error messages
      errorMessage.value = '';

      // Remove this controller from GetX
      Get.delete<AuthViewModel>();

      // Navigate to login screen
      Get.offAll(() => const LoginView());

      print('AuthViewModel: Navigated to login screen');
    } catch (e) {
      print('AuthViewModel: Sign out error: $e');
      errorMessage.value = 'Failed to sign out: ${e.toString()}';
      Get.snackbar(
        'Sign Out Error',
        'There was a problem signing out. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  // Update user model (for manual profile loading)
  void updateUserModel(UserModel userModel) {
    _userModel.value = userModel;
  }

  // Add SOS Contact
  Future<void> addSosContact(SosContact contact) async {
    if (_userModel.value == null) {
      throw Exception('No user logged in');
    }

    try {
      isLoading.value = true;

      // Create updated list of contacts
      final updatedContacts = List<SosContact>.from(
        _userModel.value!.sosContacts,
      )..add(contact);

      // Update user model
      final updatedUser = UserModel(
        id: _userModel.value!.id,
        name: _userModel.value!.name,
        email: _userModel.value!.email,
        photoUrl: _userModel.value!.photoUrl,
        bio: _userModel.value!.bio,
        dob: _userModel.value!.dob,
        moodPreferences: _userModel.value!.moodPreferences,
        createdAt: _userModel.value!.createdAt,
        sosContacts: updatedContacts,
        followers: _userModel.value!.followers,
        following: _userModel.value!.following,
        isPrivate: _userModel.value!.isPrivate,
        settings: _userModel.value!.settings,
      );

      // Save to Firebase
      final success = await _authService.saveUserProfile(updatedUser);

      if (success) {
        _userModel.value = updatedUser;
        print('AuthViewModel: SOS contact added successfully');
      } else {
        throw Exception('Failed to save SOS contact');
      }
    } catch (e) {
      print('AuthViewModel: Error adding SOS contact: $e');
      errorMessage.value = 'Failed to add SOS contact';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Update SOS Contact
  Future<void> updateSosContact(int index, SosContact contact) async {
    if (_userModel.value == null) {
      throw Exception('No user logged in');
    }

    try {
      isLoading.value = true;

      // Create updated list of contacts
      final updatedContacts = List<SosContact>.from(
        _userModel.value!.sosContacts,
      );
      updatedContacts[index] = contact;

      // Update user model
      final updatedUser = UserModel(
        id: _userModel.value!.id,
        name: _userModel.value!.name,
        email: _userModel.value!.email,
        photoUrl: _userModel.value!.photoUrl,
        bio: _userModel.value!.bio,
        dob: _userModel.value!.dob,
        moodPreferences: _userModel.value!.moodPreferences,
        createdAt: _userModel.value!.createdAt,
        sosContacts: updatedContacts,
        followers: _userModel.value!.followers,
        following: _userModel.value!.following,
        isPrivate: _userModel.value!.isPrivate,
        settings: _userModel.value!.settings,
      );

      // Save to Firebase
      final success = await _authService.saveUserProfile(updatedUser);

      if (success) {
        _userModel.value = updatedUser;
        print('AuthViewModel: SOS contact updated successfully');
      } else {
        throw Exception('Failed to update SOS contact');
      }
    } catch (e) {
      print('AuthViewModel: Error updating SOS contact: $e');
      errorMessage.value = 'Failed to update SOS contact';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Remove SOS Contact
  Future<void> removeSosContact(int index) async {
    if (_userModel.value == null) {
      throw Exception('No user logged in');
    }

    try {
      isLoading.value = true;

      // Create updated list of contacts
      final updatedContacts = List<SosContact>.from(
        _userModel.value!.sosContacts,
      )..removeAt(index);

      // Update user model
      final updatedUser = UserModel(
        id: _userModel.value!.id,
        name: _userModel.value!.name,
        email: _userModel.value!.email,
        photoUrl: _userModel.value!.photoUrl,
        bio: _userModel.value!.bio,
        dob: _userModel.value!.dob,
        moodPreferences: _userModel.value!.moodPreferences,
        createdAt: _userModel.value!.createdAt,
        sosContacts: updatedContacts,
        followers: _userModel.value!.followers,
        following: _userModel.value!.following,
        isPrivate: _userModel.value!.isPrivate,
        settings: _userModel.value!.settings,
      );

      // Save to Firebase
      final success = await _authService.saveUserProfile(updatedUser);

      if (success) {
        _userModel.value = updatedUser;
        print('AuthViewModel: SOS contact removed successfully');
      } else {
        throw Exception('Failed to remove SOS contact');
      }
    } catch (e) {
      print('AuthViewModel: Error removing SOS contact: $e');
      errorMessage.value = 'Failed to remove SOS contact';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
