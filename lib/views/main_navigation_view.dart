import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../views/home/home_view.dart';
import '../views/community/community_view.dart';
import '../views/ai_chat/ai_chat_view.dart';
import '../views/profile/profile_view.dart';

class MainNavigationView extends StatelessWidget {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationViewModel navController = Get.put(NavigationViewModel());

    // List of views corresponding to each tab
    final List<Widget> pages = [
      const HomeView(),
      const CommunityView(),
      const AIChatView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: Obx(() => pages[navController.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: navController.currentIndex.value,
          onTap: navController.changeTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
