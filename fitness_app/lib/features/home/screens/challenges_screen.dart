import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/routes/app_routes.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final AppApiService _apiService = AppApiService();
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;
  List<dynamic> _categories = <dynamic>[];
  Map<String, dynamic>? _currentChallenge;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getChallengeCategories(),
        _apiService.getCurrentChallenge(),
      ]);

      final categoryResult = results[0];
      final currentResult = results[1];

      if (categoryResult['ok'] != true || currentResult['ok'] != true) {
        setState(() {
          _error = 'Unable to load challenges data';
          _isLoading = false;
        });
        return;
      }

      final categoryData = _extractData(categoryResult['data']);
      final currentData = _extractData(currentResult['data']);

      final categories = categoryData['categories'] ?? <dynamic>[];
      final current = currentData['challenge'] ?? currentData;

      setState(() {
        _categories = categories is List ? categories : <dynamic>[];
        _currentChallenge = current is Map<String, dynamic> ? current : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to connect to server';
        _isLoading = false;
      });
    }
  }

  Future<void> _startRandom() async {
    setState(() => _isBusy = true);
    try {
      final selectedCategory = _categories.isNotEmpty
          ? _categories.first.toString()
          : null;
      final result = await _apiService.startRandomChallenge(
        fields: {if (selectedCategory != null) 'category': selectedCategory},
      );

      if (result['ok'] == true) {
        await _loadData();
        if (!mounted) return;
        Get.snackbar('Challenge', 'Random challenge started');
      } else {
        if (!mounted) return;
        Get.snackbar('Challenge', 'Start failed (${result['statusCode']})');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _updateProgress() async {
    final current = _currentChallenge;
    if (current == null) return;
    final id = (current['id'] ?? '').toString();
    if (id.isEmpty) return;
    final result = await Get.toNamed(
      AppRoutes.recordChallenge,
      arguments: current,
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deleteCurrent() async {
    final current = _currentChallenge;
    if (current == null) return;
    final id = (current['id'] ?? '').toString();
    if (id.isEmpty) return;

    await _showDiscardSheet(id);
  }

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is! Map<String, dynamic>) return <String, dynamic>{};
    final nested = raw['data'];
    if (nested is Map<String, dynamic>) return nested;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Challenges',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 2,
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEAEAEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.isEmpty
                                ? const [Text('No category found')]
                                : _categories
                                      .map(
                                        (e) => Chip(label: Text(e.toString())),
                                      )
                                      .toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isBusy ? null : _startRandom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              child: const Text(
                                'Start Random Challenge',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEAEAEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Challenge',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(_currentChallenge?.toString() ?? 'No challenge'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isBusy ? null : _showExtendTimeSheet,
                                  child: const Text('Increase Time Limit'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isBusy ? null : _deleteCurrent,
                                  child: const Text('Discard Challenge'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showExtendTimeSheet() async {
    setState(() => _isBusy = true);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Increase Time Limit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Do you want to extend your time limit?',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _extendTimeLimit();
                    },
                    icon: const Icon(Icons.ondemand_video_outlined, size: 18),
                    label: const Text('Watch Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _extendTimeLimit() async {
    try {
      final result = await _apiService.extendChallengeLimits(<String, dynamic>{
        'reason': 'watch_ad',
      });
      if (result['ok'] == true) {
        await _loadData();
        if (!mounted) return;
        Get.snackbar('Challenge', 'Time limit extended');
      } else {
        if (!mounted) return;
        Get.snackbar(
          'Challenge',
          'Extension failed (${result['statusCode']})',
        );
      }
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Challenge',
        'Unable to connect to server',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showDiscardSheet(String id) async {
    setState(() => _isBusy = true);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discard Challenge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to discard this challenge?',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _confirmDelete(id);
                    },
                    icon: const Icon(Icons.ondemand_video_outlined, size: 18),
                    label: const Text('Watch Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _confirmDelete(String id) async {
    try {
      final result = await _apiService.deleteChallenge(id);
      if (result['ok'] == true) {
        await _loadData();
        if (!mounted) return;
        Get.snackbar('Challenge', 'Challenge deleted');
      } else {
        if (!mounted) return;
        Get.snackbar(
          'Challenge',
          'Delete failed (${result['statusCode']})',
        );
      }
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Challenge',
        'Unable to connect to server',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
