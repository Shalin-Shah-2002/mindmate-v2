import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'resources/resources_view.dart';
import '../viewmodels/auth_viewmodel.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeViewModel>();
    final authController = Get.find<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: GetBuilder<ThemeViewModel>(
        builder: (_) {
          final isDark = themeController.isDark;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section Card
              _buildSectionCard(
                'Appearance',
                Icons.brightness_6_outlined,
                const Color(0xFF10B981),
                [
                  SwitchListTile(
                    title: const Text('Dark mode'),
                    subtitle: const Text('Use dark theme'),
                    value: isDark,
                    onChanged: (v) => themeController.toggleDark(v),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isDark ? 'Dark mode active' : 'Light mode active',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Profile Section Card
              _buildSectionCard(
                'Profile & Account',
                Icons.person_outline,
                const Color(0xFF6366F1),
                [
                  _buildSettingItem(
                    'Edit Profile',
                    'Update your personal information',
                    Icons.edit_outlined,
                    const Color(0xFF6366F1),
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Profile editing will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        colorText: Colors.blue[700],
                      );
                    },
                  ),
                  _buildSettingItem(
                    'Privacy Settings',
                    'Control your data and visibility',
                    Icons.privacy_tip_outlined,
                    const Color(0xFF8B5CF6),
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Privacy settings will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        colorText: Colors.purple[700],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notifications Section Card
              _buildSectionCard(
                'Notifications',
                Icons.notifications_outlined,
                const Color(0xFFF59E0B),
                [
                  _buildSettingItem(
                    'Push Notifications',
                    'Manage your notification preferences',
                    Icons.notifications_outlined,
                    const Color(0xFFF59E0B),
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Notification settings will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        colorText: Colors.orange[700],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Safety & Support Section Card
              _buildSectionCard(
                'Safety & Support',
                Icons.security_outlined,
                const Color(0xFFEF4444),
                [
                  _buildSettingItem(
                    'Emergency Contacts',
                    'Set up your support network',
                    Icons.emergency_outlined,
                    const Color(0xFFEF4444),
                    () {
                      Get.snackbar(
                        'Coming Soon',
                        'Emergency contacts management will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.withOpacity(0.1),
                        colorText: Colors.red[700],
                      );
                    },
                  ),
                  _buildSettingItem(
                    'Crisis Resources',
                    'Quick access to mental health support',
                    Icons.health_and_safety_outlined,
                    const Color(0xFF059669),
                    () => Get.to(() => const ResourcesView()),
                  ),
                  const Divider(height: 32, indent: 16, endIndent: 16),
                  _buildSettingItem(
                    'Sign Out',
                    'Sign out from your account',
                    Icons.logout,
                    const Color(0xFFEF4444),
                    () {
                      Get.dialog(
                        AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.logout, color: Color(0xFFEF4444)),
                              SizedBox(width: 12),
                              Text('Sign Out'),
                            ],
                          ),
                          content: const Text(
                            'Are you sure you want to sign out of your account?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Get.back();
                                authController.signOut();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                    },
                    isDestructive: true,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // App Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MindMate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Mental Health Companion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.grey[50],
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red : color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : const Color(0xFF374151),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
