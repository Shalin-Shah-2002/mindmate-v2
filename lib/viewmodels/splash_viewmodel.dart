import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/auth/login_view.dart';
import '../views/main_navigation_view.dart';
import '../services/auth_service.dart';

class SplashViewModel extends GetxController {
  final AuthService _authService = AuthService();

  // Reactive variables for splash state
  final RxBool isInitializing = true.obs;
  final RxString statusMessage = 'Initializing...'.obs;

  // No auto-initialization, wait for animation to trigger

  /// Called by splash screen when animation completes
  Future<void> navigateToNextScreen() async {
    try {
      statusMessage.value = 'Checking authentication...';

      // Check if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        statusMessage.value = 'Loading profile...';

        // User is signed in, check if profile exists
        final profileExists = await _authService.userProfileExists(
          currentUser.uid,
        );

        if (profileExists) {
          statusMessage.value = 'Welcome back!';

          // User has complete profile, go to main navigation
          // AuthViewModel is already initialized in main.dart

          // Small delay for smooth transition
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAll(() => const MainNavigationView());
        } else {
          statusMessage.value = 'Setting up profile...';

          // User needs to complete profile, but Firebase user exists
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAll(() => const LoginView());
        }
      } else {
        statusMessage.value = 'Ready to start!';

        // No user signed in, go to login
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAll(() => const LoginView());
      }
    } catch (e) {
      // If Firebase is not initialized or there's an error, go to login
      // Log error for debugging
      // print('Error checking auth state: $e');
      statusMessage.value = 'Starting fresh...';

      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAll(() => const LoginView());
    } finally {
      isInitializing.value = false;
    }
  }
}
