import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/core/constants/onboarding_data.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/core/widgets/primary_next_button.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final List<int> years = List.generate(30, (i) => 1996 + i);
  late final FixedExtentScrollController _controller;
  int _selectedIndex = 10;
  bool _saving = false;

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

    final selectedYear = years[_selectedIndex];
    final currentYear = DateTime.now().year;
    final selectedAge = (currentYear - selectedYear).clamp(1, 120);

    setState(() => _saving = true);
    OnboardingData.instance.birthYear = selectedYear;
    OnboardingData.instance.age = selectedAge;
    setState(() => _saving = false);
    Get.toNamed(AppRoutes.height);
  }

  @override
  Widget build(BuildContext context) {
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
                "What's your Age?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      if (index < 0 || index >= years.length) return null;
                      final isSelected = index == _selectedIndex;
                      return Center(
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE6E6E6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            years[index].toString(),
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
