import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';

class SearchViewModel extends GetxController {
  final UserService _userService = UserService();
  final PostService _postService = PostService();

  // Search state
  final RxString searchQuery = ''.obs;
  final RxList<UserModel> userSearchResults = <UserModel>[].obs;
  final RxList<PostModel> postSearchResults = <PostModel>[].obs;
  final RxBool isSearchingUsers = false.obs;
  final RxBool isSearchingPosts = false.obs;

  // Tab state
  final RxInt selectedTabIndex = 0.obs; // 0 for Users, 1 for Posts

  // Backward compatibility
  RxList<UserModel> get searchResults => userSearchResults;
  RxBool get isSearching => isSearchingUsers;

  /// Search users by name
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      userSearchResults.clear();
      searchQuery.value = '';
      return;
    }

    try {
      isSearchingUsers.value = true;
      searchQuery.value = query.trim();

      final results = await _userService.searchUsersByName(query);
      userSearchResults.value = results;
    } catch (e) {
      Get.snackbar(
        'Search Error',
        'Failed to search users: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      userSearchResults.clear();
    } finally {
      isSearchingUsers.value = false;
    }
  }

  /// Search posts by content
  Future<void> searchPosts(String query) async {
    if (query.trim().isEmpty) {
      postSearchResults.clear();
      searchQuery.value = '';
      return;
    }

    try {
      isSearchingPosts.value = true;
      searchQuery.value = query.trim();

      print('SearchViewModel: Searching posts for query: "$query"');
      final results = await _postService.searchPosts(query);
      print('SearchViewModel: Found ${results.length} posts matching "$query"');
      postSearchResults.value = results;
    } catch (e) {
      print('SearchViewModel: Error searching posts: $e');
      Get.snackbar(
        'Search Error',
        'Failed to search posts: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      postSearchResults.clear();
    } finally {
      isSearchingPosts.value = false;
    }
  }

  /// Search both users and posts simultaneously
  Future<void> searchAll(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    searchQuery.value = query.trim();
    print('SearchViewModel: Starting search for: "$query"');

    // First check if there are any posts at all
    try {
      final allPosts = await _postService.getAllPosts(limit: 5);
      print('SearchViewModel: Found ${allPosts.length} posts in database');
      if (allPosts.isNotEmpty) {
        print(
          'SearchViewModel: Sample post content: "${allPosts.first.content}"',
        );
      }
    } catch (e) {
      print('SearchViewModel: Error getting posts: $e');
    }

    // Search both users and posts simultaneously
    await Future.wait([searchUsers(query), searchPosts(query)]);
  }

  /// Clear search results and query
  void clearSearch() {
    searchQuery.value = '';
    userSearchResults.clear();
    postSearchResults.clear();
    isSearchingUsers.value = false;
    isSearchingPosts.value = false;
  }

  /// Refresh search with current query
  Future<void> refreshSearch() async {
    if (searchQuery.value.isNotEmpty) {
      await searchAll(searchQuery.value);
    }
  }

  /// Switch between tabs
  void switchTab(int index) {
    selectedTabIndex.value = index;
  }

  /// Get total search results count
  int get totalResultsCount =>
      userSearchResults.length + postSearchResults.length;

  /// Check if any search is in progress
  bool get isAnySearching => isSearchingUsers.value || isSearchingPosts.value;
}
