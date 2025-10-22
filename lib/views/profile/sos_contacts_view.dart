import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart'; // For openAppSettings
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/user_model.dart';

class SosContactsView extends StatefulWidget {
  const SosContactsView({super.key});

  @override
  State<SosContactsView> createState() => _SosContactsViewState();
}

class _SosContactsViewState extends State<SosContactsView> {
  final authController = Get.find<AuthViewModel>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Contacts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(),
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FBFF), Color(0xFFF7FFFB)],
          ),
        ),
        child: Obx(() {
          final user = authController.userModel;

          if (user == null) {
            return const Center(
              child: Text('Please sign in to manage SOS contacts'),
            );
          }

          if (user.sosContacts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: user.sosContacts.length,
            itemBuilder: (context, index) {
              final contact = user.sosContacts[index];
              return _buildContactCard(contact, index);
            },
          );
        }),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'pick_contact',
            onPressed: () => _pickContactFromDevice(),
            backgroundColor: const Color(0xFF6D83F2),
            child: const Icon(Icons.contacts),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_manual',
            onPressed: () => _showAddContactDialog(),
            icon: const Icon(Icons.edit),
            label: const Text('Manual'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withOpacity(0.1),
                    const Color(0xFFF59E0B).withOpacity(0.1),
                  ],
                ),
              ),
              child: const Icon(
                Icons.emergency_outlined,
                size: 64,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No SOS Contacts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D23),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add trusted contacts who can be quickly reached in emergency situations',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddContactDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(SosContact contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D23),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact.phone,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.relation,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditContactDialog(contact, index);
            } else if (value == 'delete') {
              _showDeleteConfirmation(index);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickContactFromDevice() async {
    try {
      // Request contacts permission using flutter_contacts
      final permissionGranted = await FlutterContacts.requestPermission();

      if (!permissionGranted) {
        Get.snackbar(
          'Permission Required',
          'Please grant contacts permission to select contacts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange[700],
          duration: const Duration(seconds: 3),
        );

        // Open app settings for user to manually grant permission
        await openAppSettings();
        return;
      }

      // Pick a contact
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // Fetch full contact details including phone numbers
        final fullContact = await FlutterContacts.getContact(contact.id);

        if (fullContact != null) {
          String phone = '';
          if (fullContact.phones.isNotEmpty) {
            phone = fullContact.phones.first.number;
          }

          final sosContact = SosContact(
            name: fullContact.displayName,
            phone: phone,
            relation: 'Contact',
          );

          await authController.addSosContact(sosContact);

          Get.snackbar(
            'Success',
            'SOS contact added successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green[700],
          );
        }
      }
    } catch (e) {
      print('Error picking contact: $e');
      Get.snackbar(
        'Error',
        'Failed to pick contact. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[700],
      );
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Add SOS Contact'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pick from device button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D83F2), Color(0xFF00C6FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _pickContactFromDevice();
                  },
                  icon: const Icon(Icons.contacts),
                  label: const Text('Pick from Device Contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR ENTER MANUALLY',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter contact name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 (555) 123-4567',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'e.g., Family, Friend, Therapist',
                  prefixIcon: const Icon(Icons.people_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                Get.snackbar(
                  'Missing Information',
                  'Please enter both name and phone number',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red[700],
                );
                return;
              }

              final newContact = SosContact(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                relation: relationshipController.text.trim().isEmpty
                    ? 'Contact'
                    : relationshipController.text.trim(),
              );

              await authController.addSosContact(newContact);
              Get.back();

              Get.snackbar(
                'Success',
                'SOS contact added successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green.withOpacity(0.1),
                colorText: Colors.green[700],
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(SosContact contact, int index) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);
    final relationshipController = TextEditingController(
      text: contact.relation,
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF6D83F2)),
            SizedBox(width: 12),
            Text('Edit SOS Contact'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: const Icon(Icons.people_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                Get.snackbar(
                  'Missing Information',
                  'Please enter both name and phone number',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red[700],
                );
                return;
              }

              final updatedContact = SosContact(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                relation: relationshipController.text.trim().isEmpty
                    ? 'Contact'
                    : relationshipController.text.trim(),
              );

              await authController.updateSosContact(index, updatedContact);
              Get.back();

              Get.snackbar(
                'Success',
                'SOS contact updated successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green.withOpacity(0.1),
                colorText: Colors.green[700],
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D83F2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Delete Contact'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this SOS contact?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await authController.removeSosContact(index);
              Get.back();

              Get.snackbar(
                'Deleted',
                'SOS contact removed successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange.withOpacity(0.1),
                colorText: Colors.orange[700],
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
