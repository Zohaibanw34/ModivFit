import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/core/constants/otp_purpose.dart';
import 'package:fitness_app/features/auth/services/auth_service.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/layout/main_layout.dart';

class ChangePasswordFlowScreen extends StatefulWidget {
  const ChangePasswordFlowScreen({super.key});

  @override
  State<ChangePasswordFlowScreen> createState() =>
      _ChangePasswordFlowScreenState();
}

class _ChangePasswordFlowScreenState extends State<ChangePasswordFlowScreen> {
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter a valid email'.tr)));
      return;
    }

    setState(() => _loading = true);
    final result = await _authService.sendChangePasswordOtp(email: email);
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));

    if (!result.success) return;

    Get.toNamed(
      AppRoutes.verification,
      arguments: {'purpose': OtpPurpose.changePassword, 'email': email},
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Change Password',
      showAppBar: true,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: 5,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Enter your email address to receive\n'
                      'a password reset link.'
                  .tr,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: _loading ? null : _sendCode,
                child: Text(
                  _loading ? 'Sending...'.tr : 'Send Code'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remember password? '.tr,
                  style: TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                  child: Text('Back to Log In'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
