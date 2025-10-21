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
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Obx(() => pages[navController.currentIndex.value]),
      bottomNavigationBar: Obx(() {
        final selected = navController.currentIndex.value;
        return Container(
          color: Colors.transparent,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DecoratedBox(
              // Outer gradient border similar to HomeView accents
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D83F2).withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // Frosted-like surface
                  color: const Color(0xFF1F2228).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavItem(
                      index: 0,
                      selectedIndex: selected,
                      activeIcon: Icons.home,
                      inactiveIcon: Icons.home_outlined,
                      label: 'Home',
                      onTap: () => navController.changeTab(0),
                    ),
                    _NavItem(
                      index: 1,
                      selectedIndex: selected,
                      activeIcon: Icons.menu_book,
                      inactiveIcon: Icons.menu_book_outlined,
                      label: 'Community',
                      onTap: () => navController.changeTab(1),
                    ),
                    _NavItem(
                      index: 2,
                      selectedIndex: selected,
                      activeIcon: Icons.chat_bubble,
                      inactiveIcon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      onTap: () => navController.changeTab(2),
                    ),
                    _NavItem(
                      index: 3,
                      selectedIndex: selected,
                      activeIcon: Icons.person,
                      inactiveIcon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () => navController.changeTab(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = index == selectedIndex;
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withOpacity(0.55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width:
            (MediaQuery.of(context).size.width - 32 - 36) / 4, // equal spacing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtle gradient halo when active
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                      )
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? Colors.white.withOpacity(0.08)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  active ? activeIcon : inactiveIcon,
                  color: active ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
