import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/features/settings/services/subscription_service.dart';

class SubscriptionOptionsScreen extends StatefulWidget {
  const SubscriptionOptionsScreen({super.key});

  @override
  State<SubscriptionOptionsScreen> createState() =>
      _SubscriptionOptionsScreenState();
}

class _SubscriptionOptionsScreenState extends State<SubscriptionOptionsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  String _selectedPlan = 'Monthly';
  bool _busy = false;

  Future<void> _selectPlan(String planName) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _selectedPlan = planName;
    });

    final result = await _subscriptionService.selectPlan(
      planName: planName,
      isPremium: true,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
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
            padding: const EdgeInsets.only(top: 28),
            child: Center(
              child: SizedBox(
                width: 324,
                child: Column(
                  children: [
                    _PlanOptionTile(
                      title: 'Monthly',
                      price: '\$9.99/month',
                      description: 'All features, no ads',
                      selected: _selectedPlan == 'Monthly',
                      onTap: () => _selectPlan('Monthly'),
                    ),
                    const SizedBox(height: 18),
                    _PlanOptionTile(
                      title: 'Quarterly',
                      price: '\$24.99 every 3 months',
                      description: 'Save 15%',
                      selected: _selectedPlan == 'Quarterly',
                      onTap: () => _selectPlan('Quarterly'),
                    ),
                    const SizedBox(height: 18),
                    _PlanOptionTile(
                      title: 'Yearly',
                      price: '\$89.99/year',
                      description: 'Save 25% + 2 bonus months + premium badge',
                      selected: _selectedPlan == 'Yearly',
                      onTap: () => _selectPlan('Yearly'),
                    ),
                    const SizedBox(height: 18),
                    if (_busy) const CircularProgressIndicator(),
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

class _PlanOptionTile extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOptionTile({
    required this.title,
    required this.price,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 324,
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF4E97FF) : Colors.transparent,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.tr,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              price.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 28 / 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description.tr,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
