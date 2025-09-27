import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../community/widgets/user_search_card.dart';
import '../community/widgets/post_search_card.dart';

class SearchResultsView extends StatelessWidget {
  final String? initialQuery;

  const SearchResultsView({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    final searchController = Get.put(SearchViewModel());
    final TextEditingController textController = TextEditingController();

    // Set initial query if provided
    if (initialQuery != null && initialQuery!.isNotEmpty) {
      textController.text = initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchController.searchAll(initialQuery!);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Navigation row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: textController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (query) {
                        if (query.isEmpty) {
                          searchController.clearSearch();
                        } else {
                          searchController.searchAll(query);
                        }
                      },
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          searchController.searchAll(query);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search users and posts...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).primaryColor,
                        ),
                        suffixIcon: Obx(
                          () => searchController.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    textController.clear();
                                    searchController.clearSearch();
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Tab bar (only show when there's a search query)
                  Obx(() {
                    if (searchController.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => searchController.switchTab(0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      searchController.selectedTabIndex.value ==
                                          0
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        searchController
                                                .selectedTabIndex
                                                .value ==
                                            0
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Users (${searchController.userSearchResults.length})',
                                  style: TextStyle(
                                    color:
                                        searchController
                                                .selectedTabIndex
                                                .value ==
                                            0
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => searchController.switchTab(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      searchController.selectedTabIndex.value ==
                                          1
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        searchController
                                                .selectedTabIndex
                                                .value ==
                                            1
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Posts (${searchController.postSearchResults.length})',
                                  style: TextStyle(
                                    color:
                                        searchController
                                                .selectedTabIndex
                                                .value ==
                                            1
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Search results
            Expanded(
              child: Obx(() {
                if (searchController.searchQuery.value.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search,
                    title: 'Start your search',
                    subtitle:
                        'Enter keywords to find users and posts in the community',
                  );
                }

                if (searchController.isAnySearching) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          searchController.selectedTabIndex.value == 0
                              ? 'Searching users...'
                              : 'Searching posts...',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show results based on selected tab
                if (searchController.selectedTabIndex.value == 0) {
                  return _buildUsersTab(searchController);
                } else {
                  return _buildPostsTab(searchController);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(SearchViewModel searchController) {
    if (searchController.userSearchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search,
        title: 'No users found',
        subtitle: 'Try searching with a different name or check your spelling',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${searchController.userSearchResults.length} user${searchController.userSearchResults.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: searchController.userSearchResults.length,
            itemBuilder: (context, index) {
              final user = searchController.userSearchResults[index];
              return UserSearchCard(
                user: user,
                onTap: () {
                  // TODO: Navigate to user profile
                  Get.snackbar(
                    'User Profile',
                    'Opening ${user.name}\'s profile...',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(context).primaryColor,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(SearchViewModel searchController) {
    if (searchController.postSearchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.article_outlined,
        title: 'No posts found',
        subtitle:
            'Try searching with different keywords or check your spelling',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${searchController.postSearchResults.length} post${searchController.postSearchResults.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: searchController.postSearchResults.length,
            itemBuilder: (context, index) {
              final post = searchController.postSearchResults[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PostSearchCard(
                  post: post,
                  onTap: () {
                    // TODO: Navigate to full post view
                    Get.snackbar(
                      'Post',
                      'Opening full post view...',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Theme.of(context).primaryColor,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
