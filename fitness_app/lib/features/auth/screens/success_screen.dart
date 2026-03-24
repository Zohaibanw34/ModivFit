import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/core/constants/success_purpose.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';

class SuccessScreen extends StatelessWidget {
  final SuccessPurpose purpose;

  const SuccessScreen({super.key, required this.purpose});

  String get _title {
    switch (purpose) {
      case SuccessPurpose.registration:
        return "Registration Successful!";
      case SuccessPurpose.passwordUpdated:
        return "Successfully";
    }
  }

  String get _description {
    switch (purpose) {
      case SuccessPurpose.registration:
        return "Congratulations! Your account setup is complete.";
      case SuccessPurpose.passwordUpdated:
        return "Your password has been updated successfully.";
    }
  }

  String get _nextRoute {
    switch (purpose) {
      case SuccessPurpose.registration:
        return AppRoutes.login;
      case SuccessPurpose.passwordUpdated:
        return AppRoutes.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsivePage(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.offNamed(_nextRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: Text(
                    purpose == SuccessPurpose.passwordUpdated
                        ? "Back to Login"
                        : "Continue",
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


