import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class SearchViewModel extends GetxController {
  final UserService _userService = UserService();

  // Search state
  final RxString searchQuery = ''.obs;
  final RxList<UserModel> searchResults = <UserModel>[].obs;
  final RxBool isSearching = false.obs;

  /// Search users by name
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      searchQuery.value = '';
      return;
    }

    try {
      isSearching.value = true;
      searchQuery.value = query.trim();

      final results = await _userService.searchUsersByName(query);
      searchResults.value = results;
    } catch (e) {
      Get.snackbar(
        'Search Error',
        'Failed to search users: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Clear search results and query
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  /// Refresh search with current query
  Future<void> refreshSearch() async {
    if (searchQuery.value.isNotEmpty) {
      await searchUsers(searchQuery.value);
    }
  }
}
