import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../widgets/loading_animation.dart';
import '../community/widgets/user_search_card.dart';
import '../community/widgets/post_search_card.dart';
import '../profile/user_profile_view.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF9FBFF), // very light indigo tint
              Color(0xFFF7FFFB), // very light mint tint
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with search bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6D83F2),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                      spreadRadius: -4,
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
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Search',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: textController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: Color(0xFF1A1D23),
                          fontSize: 15,
                        ),
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
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          suffixIcon: Obx(
                            () => searchController.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
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
                            vertical: 14,
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
                                        searchController
                                                .selectedTabIndex
                                                .value ==
                                            0
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          searchController
                                                  .selectedTabIndex
                                                  .value ==
                                              0
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                      width: 1.5,
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
                                          : Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w700,
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
                                        searchController
                                                .selectedTabIndex
                                                .value ==
                                            1
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          searchController
                                                  .selectedTabIndex
                                                  .value ==
                                              1
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                      width: 1.5,
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
                                          : Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w700,
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
                          const LoadingAnimation(
                            size: 120,
                            color: Color(0xFF6D83F2),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            searchController.selectedTabIndex.value == 0
                                ? 'Searching users...'
                                : 'Searching posts...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '${searchController.userSearchResults.length} user${searchController.userSearchResults.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D23),
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
                  Get.to(() => UserProfileView(user: user));
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${searchController.postSearchResults.length} post${searchController.postSearchResults.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D23),
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6D83F2).withOpacity(0.15),
                    const Color(0xFF00C6FF).withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: const Color(0xFF6D83F2)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D23),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
