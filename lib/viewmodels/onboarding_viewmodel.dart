import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/auth/login_view.dart';

class OnboardingViewModel extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < 2) {
      pageController.animateToPage(
        currentPage.value + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void finish() {
    // Navigate to login screen
    Get.offAll(
      () => const LoginView(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }
}
