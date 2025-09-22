import 'package:get/get.dart';

class NavigationViewModel extends GetxController {
  // Observable for current tab index
  final RxInt currentIndex = 0.obs;

  // Tab names for reference
  static const List<String> tabNames = [
    'Home',
    'Community',
    'AI Chat',
    'Profile',
  ];

  // Change current tab
  void changeTab(int index) {
    if (index >= 0 && index < tabNames.length) {
      currentIndex.value = index;
    }
  }

  // Get current tab name
  String get currentTabName => tabNames[currentIndex.value];
}
