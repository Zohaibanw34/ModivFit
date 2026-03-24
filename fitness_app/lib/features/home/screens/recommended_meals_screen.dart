import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/features/home/widgets/empty_error_view.dart';
import 'package:fitness_app/layout/main_layout.dart';

class RecommendedMealsScreen extends StatefulWidget {
  const RecommendedMealsScreen({super.key});

  @override
  State<RecommendedMealsScreen> createState() => _RecommendedMealsScreenState();
}

class _RecommendedMealsScreenState extends State<RecommendedMealsScreen> {
  final AppApiService _apiService = AppApiService();
  final List<_MealItem> _meals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getRecommendedMeals();
      final ok = result['ok'] == true || result['success'] == true;
      if (!ok) {
        setState(() {
          _error = 'Unable to load meals';
          _loading = false;
        });
        return;
      }
      final data = result['data'] ?? result;
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final list = items.map((m) => _MealItem(
            id: (m['id'] ?? '').toString(),
            title: (m['title'] ?? m['name'] ?? 'Meal').toString(),
            calories: (m['calories'] is int) ? m['calories'] as int : int.tryParse((m['calories'] ?? '').toString()) ?? 0,
            description: (m['description'] ?? '').toString(),
            imageUrl: (m['image_url'] ?? '').toString(),
          )).toList();
      if (mounted) {
        setState(() {
          _meals.clear();
          _meals.addAll(list);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to connect';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Recommended Meals',
      showBackButton: true,
      showBottomNav: false,
      currentIndex: -1,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyErrorView.serverError(onRetry: _load)
              : _meals.isEmpty
                  ? EmptyErrorView.empty(
                      message: 'No meals yet',
                      detail: 'Your recommended meals will show here.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _meals.length,
                        itemBuilder: (_, i) {
                          final meal = _meals[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => Get.to(
                                () => MealDetailScreen(
                                  id: meal.id,
                                  title: meal.title,
                                  calories: meal.calories,
                                  description: meal.description,
                                  imageUrl: meal.imageUrl,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (meal.imageUrl.isNotEmpty)
                                    Image.network(
                                      meal.imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.restaurant),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.restaurant, size: 40),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${meal.calories} kcal',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _MealItem {
  final String id;
  final String title;
  final int calories;
  final String description;
  final String imageUrl;

  _MealItem({
    required this.id,
    required this.title,
    required this.calories,
    required this.description,
    required this.imageUrl,
  });
}

class MealDetailScreen extends StatelessWidget {
  final String id;
  final String title;
  final int calories;
  final String description;
  final String imageUrl;

  const MealDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.calories,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Meal',
      showBackButton: true,
      showBottomNav: false,
      currentIndex: -1,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, size: 64),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant, size: 64),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$calories kcal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
