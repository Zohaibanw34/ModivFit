import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';

class RecordChallengeScreen extends StatefulWidget {
  const RecordChallengeScreen({super.key});

  @override
  State<RecordChallengeScreen> createState() => _RecordChallengeScreenState();
}

class _RecordChallengeScreenState extends State<RecordChallengeScreen> {
  final _repsController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AppApiService _apiService = AppApiService();

  late final String _challengeId;
  late final String _title;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments is Map<String, dynamic>
        ? Get.arguments as Map<String, dynamic>
        : <String, dynamic>{};
    _challengeId = (args['id'] ?? '').toString();
    _title = (args['title'] ?? args['name'] ?? 'Challenge').toString();
  }

  @override
  void dispose() {
    _repsController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_challengeId.isEmpty) {
      Get.snackbar('Challenge', 'Missing challenge id');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final reps = _repsController.text.trim();
    final time = _timeController.text.trim();
    final notes = _notesController.text.trim();
    final buffer = StringBuffer();
    if (reps.isNotEmpty) buffer.write('Reps: $reps. ');
    if (time.isNotEmpty) buffer.write('Time: $time. ');
    if (notes.isNotEmpty) buffer.write(notes);
    final description =
        buffer.toString().trim().isEmpty ? 'Workout completed.' : buffer.toString().trim();

    setState(() => _isSubmitting = true);
    try {
      final result = await _apiService.updateChallengeProgress(
        _challengeId,
        <String, dynamic>{'description': description},
      );
      if (result['ok'] == true) {
        Get.back(result: true);
        Get.snackbar('Challenge', 'Progress recorded');
      } else {
        Get.snackbar(
          'Challenge',
          'Record failed (${result['statusCode']})',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Challenge',
        'Unable to connect to server',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Record Challenge',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g. 5:00 min, optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: const Text('Record Challenge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

