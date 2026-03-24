import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:fitness_app/core/constants/otp_purpose.dart';
import 'package:fitness_app/core/constants/success_purpose.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';
import 'package:fitness_app/features/auth/services/auth_service.dart';
import 'package:fitness_app/routes/app_routes.dart';

class VerificationScreen extends StatefulWidget {
  final OtpPurpose purpose;
  final String? email;
  final String? expectedOtp;

  const VerificationScreen({
    super.key,
    required this.purpose,
    this.email,
    this.expectedOtp,
  });

  String get title {
    switch (purpose) {
      case OtpPurpose.signup:
        return 'Verify Your Account';
      case OtpPurpose.login:
        return 'Login Verification';
      case OtpPurpose.forgotPassword:
        return 'Reset Password';
      case OtpPurpose.changePassword:
        return 'Verification Code';
    }
  }

  String get description {
    switch (purpose) {
      case OtpPurpose.signup:
        return 'Enter the code sent to your email to complete signup';
      case OtpPurpose.login:
        return 'Enter the code sent to login securely';
      case OtpPurpose.forgotPassword:
        return 'Enter the code to reset your password';
      case OtpPurpose.changePassword:
        return 'We have sent the verification code to your email address';
    }
  }

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const int _otpMaxLength = 4;
  final AuthService _authService = AuthService();
  final List<TextEditingController> controllers = List.generate(
    _otpMaxLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(
    _otpMaxLength,
    (_) => FocusNode(),
  );
  bool _loading = false;

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => controllers.map((c) => c.text).join();

  Future<void> _handleContinue() async {
    final otp = _otp;
    if (otp.length != _otpMaxLength || otp.contains(RegExp(r'[^0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 4-digit OTP'.tr)),
      );
      return;
    }

    if (widget.purpose == OtpPurpose.signup ||
        widget.purpose == OtpPurpose.forgotPassword ||
        widget.purpose == OtpPurpose.changePassword) {
      final email = widget.email?.trim() ?? '';
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email not found. Go back and retry.'.tr)),
        );
        return;
      }

      setState(() => _loading = true);
      final result = switch (widget.purpose) {
        OtpPurpose.signup => await _authService.verifySignupOtp(
          email: email,
          otp: otp,
        ),
        OtpPurpose.forgotPassword => await _authService.verifyForgotOtp(
          email: email,
          otp: otp,
        ),
        OtpPurpose.changePassword => await _authService.verifyChangePasswordOtp(
          email: email,
          otp: otp,
        ),
        _ => const AuthResult(success: false, message: 'Invalid OTP purpose'),
      };
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      if (!result.success) return;
    }

    switch (widget.purpose) {
      case OtpPurpose.signup:
        Get.offNamed(AppRoutes.success, arguments: SuccessPurpose.registration);
        break;
      case OtpPurpose.forgotPassword:
      case OtpPurpose.changePassword:
        Get.offNamed(
          AppRoutes.setNewPassword,
          arguments: {
            'purpose': widget.purpose,
            'email': widget.email?.trim() ?? '',
            'otp': otp,
          },
        );
        break;
      case OtpPurpose.login:
        Get.offNamed(AppRoutes.home);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ResponsivePage(
          scroll: true,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.description.tr,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: List.generate(_otpMaxLength, (index) {
                  return SizedBox(
                    width: 56,
                    height: 56,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < _otpMaxLength - 1) {
                          FocusScope.of(
                            context,
                          ).requestFocus(focusNodes[index + 1]);
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(
                            context,
                          ).requestFocus(focusNodes[index - 1]);
                        }
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: _loading ? null : _handleContinue,
                  child: Text(
                    _loading ? 'Verifying...'.tr : 'Continue'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
