import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'group_chat_view.dart';
import 'create_group_view.dart';

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  GroupCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDiscoverTab(), _buildMyGroupsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      title: const Text(
        'Groups',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey.shade600,
        tabs: const [
          Tab(text: 'Discover'),
          Tab(text: 'My Groups'),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search groups...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          // Category filters
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: GroupCategory.values.length + 1, // +1 for "All"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(
                    'All',
                    '🌟',
                    _selectedCategory == null,
                    () => setState(() => _selectedCategory = null),
                  );
                }

                final category = GroupCategory.values[index - 1];
                return _buildCategoryChip(
                  category.displayName,
                  category.emoji,
                  _selectedCategory == category,
                  () => setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    String emoji,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(emoji), const SizedBox(width: 4), Text(label)],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    return StreamBuilder<List<Group>>(
      stream: GroupService.getPublicGroups(category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading groups: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!;

        if (groups.isEmpty) {
          return _buildEmptyState(
            'No groups found',
            'Be the first to create a group in this category!',
            Icons.group_add,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index]);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Group>>(
      future: GroupService.searchGroups(
        _searchQuery,
        category: _selectedCategory,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Search error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!;

        if (groups.isEmpty) {
          return _buildEmptyState(
            'No results found',
            'Try searching with different keywords or check your spelling.',
            Icons.search_off,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index]);
          },
        );
      },
    );
  }

  Widget _buildMyGroupsTab() {
    final authViewModel = Get.find<AuthViewModel>();
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      return _buildEmptyState(
        'Sign in required',
        'Please sign in to view your groups.',
        Icons.login,
      );
    }

    return StreamBuilder<List<Group>>(
      stream: GroupService.getUserGroups(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(
            'Error loading your groups: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!;

        if (groups.isEmpty) {
          return _buildEmptyState(
            'No groups yet',
            'Join some groups to get started!\nTap "Discover" to find groups you\'re interested in.',
            Icons.group,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index], isJoined: true);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(Group group, {bool isJoined = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _onGroupTap(group, isJoined),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group.category.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (group.privacy != GroupPrivacy.public)
                              Icon(
                                group.privacy == GroupPrivacy.private
                                    ? Icons.lock
                                    : Icons.mail,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.category.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.people,
                    group.displayMemberCount,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (group.tags.isNotEmpty)
                    _buildInfoChip(Icons.tag, group.tags.first, Colors.green),
                  const Spacer(),
                  if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Joined',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: group.isFull ? null : () => _joinGroup(group),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(group.isFull ? 'Full' : 'Join'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _onGroupTap(Group group, bool isJoined) {
    if (isJoined) {
      // Navigate to group chat
      Get.to(() => GroupChatView(group: group));
    } else {
      // Show group details and join option
      _showGroupDetails(group);
    }
  }

  void _showGroupDetails(Group group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      group.category.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        group.category.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.people,
                  group.displayMemberCount,
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.category,
                  group.category.displayName,
                  Colors.purple,
                ),
                if (group.tags.isNotEmpty)
                  ...group.tags
                      .take(3)
                      .map(
                        (tag) => _buildInfoChip(Icons.tag, tag, Colors.green),
                      ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: group.isFull
                    ? null
                    : () {
                        Navigator.pop(context);
                        _joinGroup(group);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  group.isFull ? 'Group is Full' : 'Join Group',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _joinGroup(Group group) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Joining group...')),
          ],
        ),
      ),
    );

    try {
      final success = await GroupService.joinGroup(group.id);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (success) {
        Get.snackbar(
          'Joined Group',
          'Welcome to ${group.name}!',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        // Navigate to group chat
        Get.to(() => GroupChatView(group: group));
      } else {
        Get.snackbar(
          'Could not join group',
          'Please check your permissions or try again later.',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog

      Get.snackbar(
        'Error',
        'Failed to join group: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showCreateGroupDialog() {
    Get.to(() => const CreateGroupView());
  }
}
