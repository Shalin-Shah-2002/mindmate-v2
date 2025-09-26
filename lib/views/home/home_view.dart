import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../search/search_results_view.dart';

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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MindMate',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => authController.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: () => authController.signOut(),
                          icon: const Icon(Icons.logout),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            GestureDetector(
              onTap: () {
                Get.to(
                  () => const SearchResultsView(),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Search for users...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User profile section - needs to be reactive
            Obx(() {
              if (authController.userModel != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            authController.userModel!.photoUrl.isNotEmpty
                            ? NetworkImage(authController.userModel!.photoUrl)
                            : null,
                        backgroundColor: Colors.white,
                        child: authController.userModel!.photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, ${authController.userModel!.name}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        authController.userModel!.bio.isNotEmpty
                            ? authController.userModel!.bio
                            : 'Your mental wellness journey starts here',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.psychology, size: 40, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Welcome to MindMate!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('Your mental wellness companion'),
                    ],
                  ),
                );
              }
            }),
            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Track Mood',
                    Icons.mood,
                    Colors.blue,
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Mood tracking will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Meditate',
                    Icons.self_improvement,
                    Colors.green,
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Meditation feature will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Resources',
                    Icons.library_books,
                    Colors.orange,
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Resource library will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'SOS Help',
                    Icons.emergency,
                    Colors.red,
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'SOS feature will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Focus Areas (if available)
            Obx(() {
              if (authController.userModel != null &&
                  authController.userModel!.moodPreferences.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Focus Areas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: authController.userModel!.moodPreferences
                          .map(
                            (pref) => Chip(
                              label: Text(pref),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            }),

            // Daily Tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Daily Tip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take a few minutes today to practice deep breathing. It can help reduce stress and improve focus.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
