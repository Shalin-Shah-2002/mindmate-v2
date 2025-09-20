import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../views/auth/profile_form_view.dart';
import '../views/home/home_view.dart';

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
  }

  void _initializeAuthListener() {
    try {
      _firebaseUser.bindStream(_authService.authStateChanges);
    } catch (e) {
      print('Firebase not initialized, auth listener disabled: $e');
      // Set user as null if Firebase is not available
      _firebaseUser.value = null;
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
          // User has completed profile, load it and go to home
          final userProfile = await _authService.getUserProfile(user.uid);
          _userModel.value = userProfile;
          print('AuthViewModel: Navigating to home view...');
          Get.offAll(() => const HomeView());
        } else {
          print('AuthViewModel: User needs to complete profile, navigating to profile form...');
          // User needs to complete profile
          Get.offAll(() => ProfileFormView(firebaseUser: user));
        }
      } else {
        print('AuthViewModel: Google Sign-In returned null (user may have canceled)');
        errorMessage.value = 'Sign-in was canceled or failed. Please try again.';
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
        Get.offAll(() => const HomeView());
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
      await _authService.signOut();
      _userModel.value = null;
      Get.offAllNamed('/login');
    } catch (e) {
      errorMessage.value = 'Failed to sign out: ${e.toString()}';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
