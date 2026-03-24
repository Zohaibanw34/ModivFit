import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/core/constants/onboarding_data.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/core/widgets/primary_next_button.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';
import 'package:fitness_app/core/widgets/unit_toggle.dart';
import 'package:fitness_app/features/auth/services/auth_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final AuthService _authService = AuthService();
  bool _isKg = true;
  int _selectedIndex = 20;
  bool _saving = false;

  late final FixedExtentScrollController _controller;

  final List<int> _kgValues = List.generate(121, (i) => 40 + i);
  final List<int> _lbValues = List.generate(221, (i) => 80 + i);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_saving) return;

    final weightValue = _isKg
        ? _kgValues[_selectedIndex].toDouble()
        : _lbValues[_selectedIndex].toDouble();
    final unit = _isKg ? 'kg' : 'lb';

    setState(() => _saving = true);
    OnboardingData.instance.weightValue = weightValue;
    OnboardingData.instance.weightUnit = unit;

    final signupData = await _authService.getPendingSignupData();
    final name = (signupData['name'] ?? '').trim();
    final email = (signupData['email'] ?? '').trim();
    final password = (signupData['password'] ?? '').trim();
    final phone = (signupData['phone'] ?? '').trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signup data missing. Please create account again.'),
        ),
      );
      Get.offAllNamed(AppRoutes.createAccount);
      return;
    }

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      phone: phone.isEmpty ? null : phone,
      onboardingData: OnboardingData.instance.toRegistrationApiMap(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      await _authService.clearPendingSignupData();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = _isKg
        ? _kgValues.map((e) => "$e kg").toList()
        : _lbValues.map((e) => "$e lb").toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ResponsivePage(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                "What's your weight?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              UnitToggle(
                leftLabel: "kg",
                rightLabel: "lb",
                isLeftSelected: _isKg,
                onChanged: (leftSelected) {
                  setState(() {
                    _isKg = leftSelected;
                    _selectedIndex = _selectedIndex.clamp(0, values.length - 1);
                    _controller.jumpToItem(_selectedIndex);
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= values.length) return null;
                      final isSelected = index == _selectedIndex;
                      return Center(
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE6E6E6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            values[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryNextButton(
                onPressed: _saving ? null : _saveAndContinue,
                label: _saving ? 'Saving...' : 'Next',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
