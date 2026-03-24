import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/core/constants/onboarding_data.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';
import 'package:fitness_app/features/settings/services/fitness_level_service.dart';

class FitnessLevelScreen extends StatefulWidget {
  const FitnessLevelScreen({super.key});

  @override
  State<FitnessLevelScreen> createState() => _FitnessLevelScreenState();
}

class _FitnessLevelScreenState extends State<FitnessLevelScreen> {
  final FitnessLevelService _fitnessLevelService = FitnessLevelService();
  String? selectedLevel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    selectedLevel = OnboardingData.instance.fitnessLevel;
    _hydrateSavedLevel();
  }

  Future<void> _hydrateSavedLevel() async {
    final saved = await _fitnessLevelService.getSavedLevel();
    if (!mounted) return;
    if (selectedLevel == null || selectedLevel!.trim().isEmpty) {
      setState(() => selectedLevel = saved);
    }
  }

  Future<void> _saveAndContinue() async {
    if (selectedLevel == null || _saving) return;

    setState(() => _saving = true);
    OnboardingData.instance.fitnessLevel = selectedLevel;
    await _fitnessLevelService.saveLevel(selectedLevel!);
    setState(() => _saving = false);
    Get.toNamed(AppRoutes.age);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 202, 216, 218),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Screen title
              const Center(
                child: Text(
                  "What's your fitness level?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Beginner
              _levelButton(
                title: "Beginner",
                isSelected: selectedLevel == "Beginner",
                onTap: () {
                  setState(() {
                    selectedLevel = "Beginner";
                  });
                },
              ),

              const SizedBox(height: 16),

              // Intermediate
              _levelButton(
                title: "Intermediate",
                isSelected: selectedLevel == "Intermediate",
                onTap: () {
                  setState(() {
                    selectedLevel = "Intermediate";
                  });
                },
              ),

              const SizedBox(height: 16),

              // Advanced
              _levelButton(
                title: "Advanced",
                isSelected: selectedLevel == "Advanced",
                onTap: () {
                  setState(() {
                    selectedLevel = "Advanced";
                  });
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedLevel == null
                        ? Colors.grey
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveAndContinue,
                  child: const Text(
                    "Next",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fitness level selection button
  Widget _levelButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black
              : const Color.fromARGB(255, 202, 216, 218),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
