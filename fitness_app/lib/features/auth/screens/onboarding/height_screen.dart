import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/core/constants/onboarding_data.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/core/widgets/primary_next_button.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';
import 'package:fitness_app/core/widgets/unit_toggle.dart';

class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  bool _isCm = false;
  int _selectedIndex = 8;
  bool _saving = false;

  late final FixedExtentScrollController _controller;

  final List<int> _cmValues = List.generate(81, (i) => 120 + i);
  final List<String> _ftValues = List.generate(37, (i) {
    final totalInches = 48 + i; // 4'0" to 7'0"
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet' $inches\"";
  });

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

    final num heightValue;
    final String unit;
    if (_isCm) {
      heightValue = _cmValues[_selectedIndex];
      unit = 'cm';
    } else {
      heightValue = 48 + _selectedIndex;
      unit = 'in';
    }

    setState(() => _saving = true);
    OnboardingData.instance.heightValue = heightValue;
    OnboardingData.instance.heightUnit = unit;
    setState(() => _saving = false);
    Get.toNamed(AppRoutes.weight);
  }

  @override
  Widget build(BuildContext context) {
    final values = _isCm ? _cmValues.map((e) => "$e cm").toList() : _ftValues;

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
                "What's your height?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              UnitToggle(
                leftLabel: "cm",
                rightLabel: "ft",
                isLeftSelected: _isCm,
                onChanged: (leftSelected) {
                  setState(() {
                    _isCm = leftSelected;
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
