import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../community/widgets/user_search_card.dart';

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
        searchController.searchUsers(initialQuery!);
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
                        'Search Users',
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
                          searchController.searchUsers(query);
                        }
                      },
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          searchController.searchUsers(query);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search users by name...',
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
                    subtitle: 'Enter a name to find users in the community',
                  );
                }

                if (searchController.isSearching.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Searching users...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (searchController.searchResults.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.person_search,
                    title: 'No users found',
                    subtitle:
                        'Try searching with a different name or check your spelling',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Results header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${searchController.searchResults.length} result${searchController.searchResults.length == 1 ? '' : 's'} found',
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
                        itemCount: searchController.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchController.searchResults[index];
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
              }),
            ),
          ],
        ),
      ),
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
