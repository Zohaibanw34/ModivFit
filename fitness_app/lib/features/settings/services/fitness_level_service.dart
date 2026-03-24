import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitnessLevelUpdateResult {
  final bool success;
  final String message;

  const FitnessLevelUpdateResult({
    required this.success,
    required this.message,
  });
}

class FitnessLevelService {
  static const String _fitnessLevelKey = 'user_fitness_level';

  final AppApiService _apiService = AppApiService();

  Future<String> getSavedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_fitnessLevelKey);
    return _toDisplayLevel(stored);
  }

  Future<void> saveLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fitnessLevelKey, _toApiLevel(level));
  }

  Future<String> resolveInitialLevel() async {
    final cached = await getSavedLevel();
    final profileResult = await _apiService.getProfile();
    if (profileResult['ok'] != true) return cached;

    final payload = _extractPayload(profileResult['data']);
    final remoteLevel = _pickString(payload, const [
      'fitness_level',
      'fitnessLevel',
      'level',
    ]);

    if (remoteLevel == null || remoteLevel.trim().isEmpty) return cached;
    final normalized = _toDisplayLevel(remoteLevel);
    await saveLevel(normalized);
    return normalized;
  }

  Future<FitnessLevelUpdateResult> updateLevel(String level) async {
    final displayLevel = _toDisplayLevel(level);
    final apiLevel = _toApiLevel(displayLevel);

    await saveLevel(displayLevel);

    final result = await _apiService.updateProfile(<String, dynamic>{
      'fitness_level': apiLevel,
      'fitnessLevel': apiLevel,
      'level': apiLevel,
    });

    if (result['ok'] == true) {
      return const FitnessLevelUpdateResult(
        success: true,
        message: 'Fitness level updated',
      );
    }

    return const FitnessLevelUpdateResult(
      success: false,
      message: 'Saved locally. Server update failed.',
    );
  }

  Map<String, dynamic> _extractPayload(dynamic raw) {
    if (raw is! Map<String, dynamic>) return <String, dynamic>{};
    final nested = raw['data'];
    if (nested is Map<String, dynamic>) return nested;
    return raw;
  }

  String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  String _toDisplayLevel(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'advanced') return 'Advanced';
    if (normalized == 'intermediate') return 'Intermediate';
    return 'Beginner';
  }

  String _toApiLevel(String raw) {
    return _toDisplayLevel(raw).toLowerCase();
  }
}
