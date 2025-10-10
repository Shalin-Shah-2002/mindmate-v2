import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  GroupPrivacy _selectedPrivacy = GroupPrivacy.public;
  GroupCategory _selectedCategory = GroupCategory.support;
  int _maxMembers = 100;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Create Group',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildCategorySection(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 24),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Group Name',
              hintText: 'Enter a name for your group',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.group),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a group name';
              }
              if (value.trim().length < 3) {
                return 'Group name must be at least 3 characters';
              }
              if (value.trim().length > 50) {
                return 'Group name must be less than 50 characters';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what your group is about',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              if (value.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              if (value.trim().length > 500) {
                return 'Description must be less than 500 characters';
              }
              return null;
            },
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: GroupCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ...GroupPrivacy.values.map((privacy) {
            return RadioListTile<GroupPrivacy>(
              value: privacy,
              groupValue: _selectedPrivacy,
              onChanged: (GroupPrivacy? value) {
                if (value != null) {
                  setState(() => _selectedPrivacy = value);
                }
              },
              title: Text(
                privacy.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(_getPrivacyDescription(privacy)),
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.primary,
            );
          }),
        ],
      ),
    );
  }

  String _getPrivacyDescription(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return 'Anyone can find, join, and see group content';
      case GroupPrivacy.private:
        return 'Only members can see group content and member list';
      case GroupPrivacy.invitation_only:
        return 'People can only join if invited by a member';
    }
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.people, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maximum Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_maxMembers members',
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
          const SizedBox(height: 8),
          Slider(
            value: _maxMembers.toDouble(),
            min: 10,
            max: 1000,
            divisions: 99,
            onChanged: (double value) {
              setState(() {
                _maxMembers = value.round();
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tags to help people find your group',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags',
              hintText: 'Enter tags separated by commas',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.tag),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final tags = value.split(',').map((t) => t.trim()).toList();
                if (tags.length > 5) {
                  return 'Maximum 5 tags allowed';
                }
                for (final tag in tags) {
                  if (tag.length > 20) {
                    return 'Each tag must be less than 20 characters';
                  }
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Get.find<AuthViewModel>();
    final currentUser = authViewModel.user;

    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'You must be signed in to create a group.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final tags = _tagsController.text.isNotEmpty
          ? _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList()
          : <String>[];

      final groupId = await GroupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        privacy: _selectedPrivacy,
        category: _selectedCategory,
        tags: tags,
        maxMembers: _maxMembers,
      );

      if (groupId != null) {
        Get.snackbar(
          'Group Created',
          'Your group "${_nameController.text.trim()}" has been created successfully!',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        // Navigate back and show success
        Get.back(result: groupId);
      } else {
        Get.snackbar(
          'Error',
          'Failed to create group. Please try again.',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create group: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
