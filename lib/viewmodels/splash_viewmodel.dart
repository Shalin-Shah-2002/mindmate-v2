import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/auth/login_view.dart';
import '../views/home/home_view.dart';
import '../services/auth_service.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashViewModel extends GetxController {
  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate app initialization
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is signed in, check if profile exists
        final profileExists = await _authService.userProfileExists(
          currentUser.uid,
        );

        if (profileExists) {
          // User has complete profile, initialize AuthViewModel and go to home
          Get.put(AuthViewModel());
          Get.offAll(() => const HomeView());
        } else {
          // User needs to complete profile, but Firebase user exists
          // This shouldn't normally happen, but let's handle it
          Get.offAll(() => const LoginView());
        }
      } else {
        // No user signed in, go to login
        Get.offAll(() => const LoginView());
      }
    } catch (e) {
      // If Firebase is not initialized or there's an error, go to login
      print('Error checking auth state: $e');
      Get.offAll(() => const LoginView());
    }
  }
}
