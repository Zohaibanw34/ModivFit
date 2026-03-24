import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/auth/services/auth_service.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final AuthService _authService = AuthService();

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Logout'.tr),
          content: Text('Are you sure you want to logout?'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Yes'.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _authService.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Settings',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 5,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F1F1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 23, top: 40, right: 23),
              child: SizedBox(
                width: 345,
                height: 519,
                child: Column(
                  children: [
                    _SettingsActionTile(
                      label: 'Profile Settings',
                      trailingIcon: Icons.edit_outlined,
                      onTap: () => Get.toNamed(AppRoutes.profileSettings),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Subscription',
                      trailingIcon: Icons.edit_outlined,
                      onTap: () => Get.toNamed(AppRoutes.subscription),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Change Fitness Level',
                      trailingIcon: Icons.edit_outlined,
                      onTap: () => Get.toNamed(AppRoutes.changeFitnessLevel),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Help',
                      onTap: () => Get.toNamed(AppRoutes.help),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Language Preferences',
                      trailingIcon: Icons.edit_outlined,
                      onTap: () => Get.toNamed(AppRoutes.languagePreferences),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Change Theme',
                      trailingIcon: Icons.edit_outlined,
                      onTap: () => Get.toNamed(AppRoutes.changeTheme),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Change Password',
                      trailingIcon: Icons.edit_outlined,
                      onTap: () => Get.toNamed(AppRoutes.changePassword),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      label: 'Logout',
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const _SettingsActionTile({
    required this.label,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  trailingIcon ?? Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
