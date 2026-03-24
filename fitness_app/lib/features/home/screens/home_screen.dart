import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/screens/recommended_meals_screen.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProfileController _profileController;
  final AppApiService _apiService = AppApiService();

  bool _mealLoading = true;
  String? _mealError;
  String _mealTitle = 'Nut Butter Toast With Boiled Eggs';
  int _mealCalories = 164;
  final List<_HomeChallengeSample> _dynamicChallenges = <_HomeChallengeSample>[];

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
    _loadRecommendedMeal();
    _loadHomeChallenges();
  }

  Future<void> _loadRecommendedMeal() async {
    setState(() {
      _mealLoading = true;
      _mealError = null;
    });
    try {
      final result = await _apiService.getRecommendedMeal();
      if (result['ok'] != true) {
        setState(() {
          _mealError = 'Unable to load recommendation';
          _mealLoading = false;
        });
        return;
      }
      final data = result['data'] is Map<String, dynamic>
          ? result['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final title = (data['title'] ?? '').toString().trim();
      final caloriesRaw = data['calories'];
      int calories;
      if (caloriesRaw is int) {
        calories = caloriesRaw;
      } else if (caloriesRaw is num) {
        calories = caloriesRaw.toInt();
      } else {
        calories = int.tryParse((caloriesRaw ?? '').toString()) ?? 0;
      }
      setState(() {
        if (title.isNotEmpty) {
          _mealTitle = title;
        }
        if (calories > 0) {
          _mealCalories = calories;
        }
        _mealLoading = false;
      });
    } catch (_) {
      setState(() {
        _mealError = 'Unable to connect to server';
        _mealLoading = false;
      });
    }
  }

  Future<void> _loadHomeChallenges() async {
    try {
      final result = await _apiService.getHome();
      if (result['ok'] != true) return;
      final data = result['data'] as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>? ?? data;
      final rawChallenges = (payload['challenges'] ?? []) as List;
      final items = <_HomeChallengeSample>[];
      for (final raw in rawChallenges) {
        if (raw is! Map) continue;
        final map = raw.cast<String, dynamic>();
        final title = (map['title'] ?? map['name'] ?? '').toString();
        if (title.trim().isEmpty) continue;
        final subtitle = (map['description'] ?? '').toString();
        final timeValue = map['time'];
        final duration = timeValue == null || '$timeValue'.isEmpty
            ? '5:00 min'
            : '${timeValue.toString()} min';
        final category = (map['category'] ?? 'Weightlifting').toString();
        final media = (map['media'] ?? '').toString();
        double progress = 0.0;
        if (map['progress'] != null) {
          if (map['progress'] is num) progress = (map['progress'] as num).toDouble();
          if (map['progress'] is String) progress = double.tryParse(map['progress'] as String) ?? 0.0;
        }
        items.add(
          _HomeChallengeSample(
            title: title,
            subtitle: subtitle,
            duration: duration,
            progress: progress.clamp(0.0, 1.0),
            imageUrl: media.isNotEmpty
                ? media
                : "https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg",
            category: category,
          ),
        );
      }
      if (items.isNotEmpty && mounted) {
        setState(() {
          _dynamicChallenges
            ..clear()
            ..addAll(items);
        });
      }
    } catch (_) {
      // keep static samples as fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Home',
      isHome: true,
      showBottomNav: true,
      currentIndex: 0,
      constrainBody: false,
      useScreenPadding: false,
      body: Container(
        color: const Color(0xFF1C1C1E),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // HEADER: Welcome [Name] + profile + bell
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => Text(
                          'Welcome ${_profileController.displayName.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(
                          () => InkWell(
                            onTap: () => Get.toNamed(AppRoutes.profile),
                            borderRadius: BorderRadius.circular(18),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  _profileController.avatarProvider,
                              backgroundColor: const Color(0xFFEAEAEA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => Get.toNamed(AppRoutes.notifications),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // MAIN WHITE CARD: Current Challenges + Recommended Meal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Challenges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: _buildFilteredChallenges(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recommended Meal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.recommendedMeals),
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Get.to(
                          () => MealDetailScreen(
                            id: 'home_meal',
                            title: _mealTitle,
                            calories: _mealCalories,
                            description: '',
                            imageUrl: 'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg',
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.network(
                                'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg',
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                right: 12,
                                child: _mealLoading
                                    ? const Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _mealTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _mealError != null
                                                ? _mealError!
                                                : '$_mealCalories kcal',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredChallenges() {
    final source =
        _dynamicChallenges.isNotEmpty ? _dynamicChallenges : _homeChallengeSamples;
    if (source.isEmpty) {
      return const Center(
        child: Text(
          'No challenges yet for this category.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: source.length,
      itemBuilder: (context, index) {
        final sample = source[index];
        return _ChallengeItem(
          title: sample.title,
          subtitle: sample.subtitle,
          duration: sample.duration,
          progress: sample.progress,
          imageUrl: sample.imageUrl,
          onTap: () => Get.toNamed(AppRoutes.randomChallenge),
          onRefresh: () => _loadHomeChallenges(),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}
// CHALLENGE ITEM WIDGET

class _HomeChallengeSample {
  final String title;
  final String subtitle;
  final String duration;
  final double progress;
  final String imageUrl;
  final String category;

  const _HomeChallengeSample({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.progress,
    required this.imageUrl,
    required this.category,
  });
}

const List<_HomeChallengeSample> _homeChallengeSamples = [
  _HomeChallengeSample(
    title: 'Push Up',
    subtitle: '100 Push up a day',
    duration: '5:00 min',
    progress: 0.45,
    imageUrl: 'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg',
    category: 'Calisthenics',
  ),
  _HomeChallengeSample(
    title: 'Sit Up',
    subtitle: '20 Sit up a day',
    duration: '5:00 min',
    progress: 0.75,
    imageUrl: 'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg',
    category: 'Calisthenics',
  ),
  _HomeChallengeSample(
    title: 'Knee Push Up',
    subtitle: '20 Knee Push up a day',
    duration: '5:00 min',
    progress: 0.45,
    imageUrl: 'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg',
    category: 'Calisthenics',
  ),
  _HomeChallengeSample(
    title: 'Deadlift Series',
    subtitle: '4 sets of 5 reps',
    duration: '6:00 min',
    progress: 0.55,
    imageUrl: 'https://images.pexels.com/photos/2261477/pexels-photo-2261477.jpeg',
    category: 'Weightlifting',
  ),
  _HomeChallengeSample(
    title: 'Jump Rope',
    subtitle: '2 min bursts',
    duration: '4:00 min',
    progress: 0.62,
    imageUrl: 'https://images.pexels.com/photos/3757373/pexels-photo-3757373.jpeg',
    category: 'Cardio-Based',
  ),
];

class _ChallengeItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final double progress;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const _ChallengeItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.progress,
    required this.imageUrl,
    this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEFEFEF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF19C4C1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                duration,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.sync, size: 18, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
