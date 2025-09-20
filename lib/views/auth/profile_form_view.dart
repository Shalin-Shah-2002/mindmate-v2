import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ProfileFormView extends StatefulWidget {
  final User firebaseUser;

  const ProfileFormView({super.key, required this.firebaseUser});

  @override
  State<ProfileFormView> createState() => _ProfileFormViewState();
}

class _ProfileFormViewState extends State<ProfileFormView> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  // Form Data
  DateTime? _selectedDob;
  List<String> _selectedMoodPreferences = [];
  List<SosContact> _sosContacts = [];
  bool _isPrivate = false;
  bool _darkMode = false;
  String _fontSize = 'medium';
  bool _ttsEnabled = false;

  // Available mood preferences
  final List<String> _moodOptions = [
    'Anxiety',
    'Depression',
    'Stress',
    'Sleep Issues',
    'Relationships',
    'Work/School',
    'Self-Esteem',
    'Grief',
    'Anger Management',
    'Social Anxiety',
  ];

  // Current page index
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    // Pre-fill with Firebase user data
    _nameController.text = widget.firebaseUser.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${((_currentPage + 1) / _totalPages * 100).round()}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildBasicInfoPage(),
                  _buildMoodPreferencesPage(),
                  _buildSOSContactsPage(),
                  _buildSettingsPage(),
                ],
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPage == _totalPages - 1
                          ? _submitForm
                          : _nextPage,
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? 'Complete Profile'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let us know a bit about yourself',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Profile Picture
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.firebaseUser.photoURL != null
                      ? NetworkImage(widget.firebaseUser.photoURL!)
                      : null,
                  child: widget.firebaseUser.photoURL == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio (Optional)',
              hintText: 'Tell us a bit about yourself...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 16),

          // Date of Birth
          InkWell(
            onTap: _selectDateOfBirth,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDob != null
                    ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                    : 'Select your date of birth',
                style: TextStyle(
                  color: _selectedDob != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Setting
          SwitchListTile(
            title: const Text('Private Profile'),
            subtitle: const Text('Only you can see your posts and activity'),
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Preferences',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select topics you\'d like support with (optional)',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moodOptions.map((mood) {
              final isSelected = _selectedMoodPreferences.contains(mood);
              return FilterChip(
                label: Text(mood),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedMoodPreferences.add(mood);
                    } else {
                      _selectedMoodPreferences.remove(mood);
                    }
                  });
                },
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSContactsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOS Emergency Contacts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add trusted contacts for emergency situations (optional)',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // SOS Contacts List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sosContacts.length,
            itemBuilder: (context, index) {
              final contact = _sosContacts[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.contact_emergency),
                  title: Text(contact.name),
                  subtitle: Text('${contact.phone} - ${contact.relation}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeSOSContact(index),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Add Contact Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addSOSContact,
              icon: const Icon(Icons.add),
              label: const Text('Add Emergency Contact'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Preferences',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customize your app experience',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Dark Mode
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: (value) => setState(() => _darkMode = value),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),

          // Font Size
          const Text(
            'Font Size',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'small', label: Text('Small')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'large', label: Text('Large')),
            ],
            selected: {_fontSize},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _fontSize = selection.first);
            },
          ),

          const SizedBox(height: 24),

          // Text-to-Speech
          SwitchListTile(
            title: const Text('Text-to-Speech'),
            subtitle: const Text('Enable voice reading for posts and content'),
            value: _ttsEnabled,
            onChanged: (value) => setState(() => _ttsEnabled = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // ~18 years
      firstDate: DateTime.now().subtract(
        const Duration(days: 36500),
      ), // ~100 years
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() => _selectedDob = picked);
    }
  }

  void _addSOSContact() {
    showDialog(
      context: context,
      builder: (context) => _SOSContactDialog(
        onAdd: (contact) {
          setState(() => _sosContacts.add(contact));
        },
      ),
    );
  }

  void _removeSOSContact(int index) {
    setState(() => _sosContacts.removeAt(index));
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDob == null) {
      Get.snackbar('Error', 'Please select your date of birth');
      return;
    }

    // Create UserModel
    final userModel = UserModel(
      id: widget.firebaseUser.uid,
      name: _nameController.text.trim(),
      email: widget.firebaseUser.email ?? '',
      photoUrl: widget.firebaseUser.photoURL ?? '',
      bio: _bioController.text.trim(),
      dob: _selectedDob!,
      moodPreferences: _selectedMoodPreferences,
      createdAt: DateTime.now(),
      followers: [],
      following: [],
      isPrivate: _isPrivate,
      sosContacts: _sosContacts,
      settings: UserSettings(
        darkMode: _darkMode,
        fontSize: _fontSize,
        ttsEnabled: _ttsEnabled,
      ),
    );

    // Initialize AuthViewModel if not already available and save profile
    final authViewModel = Get.put(AuthViewModel());
    authViewModel.saveUserProfile(userModel);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class _SOSContactDialog extends StatefulWidget {
  final Function(SosContact) onAdd;

  const _SOSContactDialog({required this.onAdd});

  @override
  State<_SOSContactDialog> createState() => _SOSContactDialogState();
}

class _SOSContactDialogState extends State<_SOSContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relation = 'Family';

  final List<String> _relations = [
    'Family',
    'Friend',
    'Partner',
    'Doctor',
    'Counselor',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _relation,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
              items: _relations.map((relation) {
                return DropdownMenuItem(value: relation, child: Text(relation));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _relation = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final contact = SosContact(
                name: _nameController.text.trim(),
                phone: _phoneController.text.trim(),
                relation: _relation,
              );
              widget.onAdd(contact);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
