import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/auth_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get or create the AuthViewModel safely
    late AuthViewModel authController;
    try {
      authController = Get.find<AuthViewModel>();
    } catch (e) {
      authController = Get.put(AuthViewModel());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindMate'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Obx(
            () => authController.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => authController.signOut(),
                    icon: const Icon(Icons.logout),
                  ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User profile section - needs to be reactive
            Obx(() {
              if (authController.userModel != null) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          authController.userModel!.photoUrl.isNotEmpty
                          ? NetworkImage(authController.userModel!.photoUrl)
                          : null,
                      child: authController.userModel!.photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, ${authController.userModel!.name}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authController.userModel!.bio.isNotEmpty
                          ? authController.userModel!.bio
                          : 'Your mental wellness journey starts here',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (authController
                        .userModel!
                        .moodPreferences
                        .isNotEmpty) ...[
                      const Text(
                        'Your Focus Areas:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: authController.userModel!.moodPreferences
                            .map(
                              (pref) => Chip(
                                label: Text(pref),
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                );
              } else {
                return const Column(
                  children: [
                    Text(
                      'Home Screen',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Welcome to MindMate!'),
                  ],
                );
              }
            }),
            const SizedBox(height: 40),
            const Text(
              'More features coming soon...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
