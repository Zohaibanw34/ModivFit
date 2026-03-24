import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/routes/app_routes.dart';

import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/features/settings/screens/subscription_plan.dart';
import 'package:fitness_app/features/settings/services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isBasicSelected = true;
  bool _isSubmitting = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  final List<String> _basicIncluded = const [
    '3 Beginner-Level Challenges Per Day',
    '1 Daily Workout Video',
    'Manual Meal Logging',
    'General Meal Guides',
    'Basic Trial Access Up To Gold III',
    'Global Leaderboard View',
    '3 Weekly Video Uploads (No HD)',
    '1 Free Tutorial + 1 Free Workout Video/Week',
  ];

  final List<String> _basicExcluded = const [
    'Time Extension Vault',
    'Ad-Free',
    'Offline Mode',
    'Community Rooms',
    'Custom Notifications',
  ];

  final List<String> _premiumIncluded = const [
    'Unlimited Challenges Based On Fitness Level',
    'Access To 100+ Curated Workout Videos',
    'Add Personalized Challenges',
    'Personalized Meal Plans',
    'Advanced Meal Logging + Barcode Scan',
    'Micronutrient Tracking',
    'Unlimited HD Video Uploads',
    'Elite Difficulty Challenges',
    'Personal Leaderboard Rank, Badges, Highlights',
    'Time Extension Vault (Bank 60 Days)',
    '100% Ad-Free',
    'Offline Mode Support',
    'Challenge Chat Rooms + Expert Q&A',
    'Motivational Alerts & Reminders',
  ];

  Future<bool> _saveSelectedPlan(
    String planName, {
    required bool premium,
  }) async {
    if (_isSubmitting) return false;
    setState(() => _isSubmitting = true);
    final result = await _subscriptionService.selectPlan(
      planName: planName,
      isPremium: premium,
    );
    if (!mounted) return false;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    return result.success;
  }

  Future<void> _onPrimaryTap() async {
    if (_isSubmitting) return;
    if (isBasicSelected) {
      showDialog(
        context: context,
        builder: (_) => PremiumPlansDialog(
          onPlanSelected: (planName) =>
              _saveSelectedPlan(planName, premium: true),
        ),
      );
      return;
    }
    Get.toNamed(AppRoutes.subscriptionOptions);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Subscription',
      showAppBar: true,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: 5,
      body: Container(
        width: double.infinity,
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 18,
              left: 14,
              right: 14,
              bottom: 16,
            ),
            child: Column(
              children: [
                SubscriptionTabSwitcher(
                  isBasicSelected: isBasicSelected,
                  onBasicTap: () => setState(() => isBasicSelected = true),
                  onPremiumTap: () => setState(() => isBasicSelected = false),
                ),
                const SizedBox(height: 14),
                SubscriptionFeatureContainer(
                  title: isBasicSelected ? 'Basic Plan (Free)' : 'Premium Plan',
                  included: isBasicSelected ? _basicIncluded : _premiumIncluded,
                  excluded: isBasicSelected ? _basicExcluded : const [],
                ),
                const SizedBox(height: 12),
                SubscriptionPrimaryButton(
                  label: _isSubmitting
                      ? 'Please wait...'
                      : (isBasicSelected ? 'Switch to Premium' : 'Continue'),
                  onTap: _onPrimaryTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
