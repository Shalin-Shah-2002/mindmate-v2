import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingViewModel());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6D83F2),
                Color(0xFF5B72E8),
                Color(0xFF00B4D8),
                Color(0xFF00C6FF),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Obx(
                      () => controller.currentPage.value < 2
                          ? TextButton(
                              onPressed: controller.skip,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),

                // PageView for onboarding screens
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    children: [
                      _buildOnboardingPage(
                        context,
                        image: 'assets/illustrations/meditating.png',
                        icon: Icons.psychology,
                        title: 'AI-Powered Support',
                        description:
                            'Chat with our intelligent AI therapist for personalized mental health guidance and support anytime you need.',
                        color: const Color(0xFF6D83F2),
                      ),
                      _buildOnboardingPage(
                        context,
                        image: 'assets/illustrations/SOS illustrations.png',
                        icon: Icons.favorite,
                        title: 'Track Your Wellness',
                        description:
                            'Monitor your mood, journal your thoughts, and gain insights into your mental health journey with visual analytics.',
                        color: const Color(0xFF00B4D8),
                      ),
                      _buildOnboardingPage(
                        context,
                        image:
                            'assets/illustrations/Young Woman Chatting on Smartphone.png',
                        icon: Icons.people,
                        title: 'Connect & Grow Together',
                        description:
                            'Join a supportive community, share experiences, access meditation resources, and get help when you need it most.',
                        color: const Color(0xFF00C6FF),
                      ),
                    ],
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: controller.currentPage.value == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: controller.currentPage.value == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.currentPage.value < 2
                            ? controller.nextPage
                            : controller.finish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6D83F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: Text(
                          controller.currentPage.value < 2
                              ? 'Next'
                              : 'Get Started',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context, {
    required String image,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration with glow effect
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(icon, size: 120, color: Colors.white);
                },
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.3,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


