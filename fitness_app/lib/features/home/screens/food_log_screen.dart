import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedMeal = 'breakfast';
  late final HomeProfileController _profileController;
  final AppApiService _apiService = AppApiService();

  bool _isLoading = true;
  String? _error;
  final List<_FoodLogEntry> _todayLogs = <_FoodLogEntry>[];

  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFats = 0;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getMyFoodLogs();

      if (result['ok'] != true) {
        setState(() {
          _error = 'Unable to load food logs';
          _isLoading = false;
        });
        return;
      }

      final allData = _extractList(result['data']);
      final today = DateTime.now();
      int totalCalories = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFats = 0;
      final todayLogs = <_FoodLogEntry>[];

      for (final item in allData) {
        final entry = _FoodLogEntry.fromMap(item);
        if (entry.createdAt.year == today.year &&
            entry.createdAt.month == today.month &&
            entry.createdAt.day == today.day) {
          todayLogs.add(entry);
          totalCalories += entry.calories;
          totalProtein += entry.protein;
          totalCarbs += entry.carbs;
          totalFats += entry.fats;
        }
      }

      setState(() {
        _todayLogs
          ..clear()
          ..addAll(todayLogs);
        _totalCalories = totalCalories;
        _totalProtein = totalProtein;
        _totalCarbs = totalCarbs;
        _totalFats = totalFats;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to connect to server';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .where((e) => e is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is List) {
        return nested
            .where((e) => e is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> _createFoodLog() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final meal = _selectedMeal;
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = int.tryParse(_proteinController.text) ?? 0;
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fats = int.tryParse(_fatsController.text) ?? 0;

    try {
      final result = await _apiService.createFoodLog(
        message: name,
        title: name,
        type: meal,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
      );
      if (result['ok'] == true) {
        _nameController.clear();
        _caloriesController.clear();
        _proteinController.clear();
        _carbsController.clear();
        _fatsController.clear();
        await _loadData();
        if (!mounted) return;
        Get.back();
      } else {
        Get.snackbar(
          'Add Food',
          'Save failed (${result['statusCode']})',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Add Food',
        'Unable to connect to server',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealLogs = _todayLogs
        .where((e) => e.type == _selectedMeal)
        .toList(growable: false);

    return MainLayout(
      title: 'FoodLog',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 1,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.only(left: 23, right: 19, top: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MealTabs(
                          selected: _selectedMeal,
                          onChanged: (value) =>
                              setState(() => _selectedMeal = value),
                        ),
                        const SizedBox(height: 18),
                        _DailySummaryRow(
                          calories: _totalCalories,
                          protein: _totalProtein,
                          carbs: _totalCarbs,
                          fats: _totalFats,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedMeal == 'breakfast'
                                  ? 'Breakfast'
                                  : _selectedMeal == 'lunch'
                                      ? 'Lunch'
                                      : 'Dinner',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _openAddFoodSheet(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (mealLogs.isEmpty)
                          const Text(
                            'No food added yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Column(
                            children: [
                              for (final entry in mealLogs) ...[
                                _FoodRow(entry: entry),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _openAddFoodSheet() async {
    _nameController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatsController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Food',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food name',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedMeal,
                  items: const [
                    DropdownMenuItem(
                      value: 'breakfast',
                      child: Text('Breakfast'),
                    ),
                    DropdownMenuItem(
                      value: 'lunch',
                      child: Text('Lunch'),
                    ),
                    DropdownMenuItem(
                      value: 'dinner',
                      child: Text('Dinner'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedMeal = value);
                  },
                  decoration: const InputDecoration(labelText: 'Meal'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _fatsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createFoodLog,
                    child: const Text('Add Food'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FoodLogEntry {
  final String id;
  final String title;
  final String type;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final DateTime createdAt;

  const _FoodLogEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.createdAt,
  });

  factory _FoodLogEntry.fromMap(Map<String, dynamic> map) {
    DateTime created;
    try {
      created = DateTime.parse((map['created_at'] ?? '').toString());
    } catch (_) {
      created = DateTime.now();
    }
    String _string(String key) =>
        (map[key] ?? '').toString().trim();
    int _int(String key) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
      return 0;
    }

    return _FoodLogEntry(
      id: _string('id'),
      title: _string('title').isNotEmpty
          ? _string('title')
          : _string('description'),
      type: _string('type').isNotEmpty
          ? _string('type').toLowerCase()
          : 'breakfast',
      calories: _int('calories'),
      protein: _int('protein'),
      carbs: _int('carbs'),
      fats: _int('fats'),
      createdAt: created,
    );
  }
}

class _MealTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MealTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _chip('Breakfast', 'breakfast'),
        _chip('Lunch', 'lunch'),
        _chip('Dinner', 'dinner'),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final isSelected = selected == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailySummaryRow extends StatelessWidget {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const _DailySummaryRow({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard('Calories', '$calories'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard('Protein', '${protein}g'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard('Carbs', '${carbs}g'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard('Fat', '${fats}g'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final _FoodLogEntry entry;

  const _FoodRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.calories} kcal • P ${entry.protein}g • C ${entry.carbs}g • F ${entry.fats}g',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
