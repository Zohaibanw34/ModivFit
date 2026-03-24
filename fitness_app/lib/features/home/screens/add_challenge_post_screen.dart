import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fitness_app/features/auth/services/auth_service.dart';
import 'package:fitness_app/features/home/controllers/challenges_feed_controller.dart';
import 'package:fitness_app/features/home/models/random_challenge.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/features/home/services/random_challenge_repository.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/routes/app_routes.dart';

class AddChallengePostScreen extends StatefulWidget {
  const AddChallengePostScreen({super.key});

  @override
  State<AddChallengePostScreen> createState() => _AddChallengePostScreenState();
}

class _AddChallengePostScreenState extends State<AddChallengePostScreen> {
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final AppApiService _apiService = AppApiService();
  final AuthService _authService = AuthService();

  String _category = 'Medium';
  String _fitnessLevel = 'Beginner';
  String? _selectedImageName;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _postChallenge() async {
    final name = _nameController.text.trim();
    final time = _timeController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || time.isEmpty || description.isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Ensure user is authenticated before calling protected endpoint
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      Get.snackbar(
        'Authentication required',
        'Please log in before creating a challenge.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    final controller = Get.find<ChallengesFeedController>();
    final feedDescription = _selectedImageName == null
        ? description
        : '$description\nImage: $_selectedImageName';
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final apiFields = <String, dynamic>{
      'name': name,
      'title': name,
      'category': _category,
      'fitness_level': _fitnessLevel,
      'description': description,
      'time': time,
    };
    try {
      final result = await _apiService.createChallenge(apiFields);
      if (result['ok'] == true) {
        final remoteId = _extractRemoteId(result['data']);
        controller.addMyPost(
          title: name,
          target: time,
          category: _category,
          fitnessLevel: _fitnessLevel,
          description: feedDescription,
          imageBytes: _selectedImageBytes,
          backendId: remoteId,
        );
        _addChallengeToRandomPool(
          title: name,
          duration: time,
          description: description,
          category: _category,
          fitnessLevel: _fitnessLevel,
          imageBytes: _selectedImageBytes,
        );
        Get.back();
      } else {
        final code = result['statusCode'];
        final message =
            (result['data'] is Map<String, dynamic>
                    ? (result['data'] as Map<String, dynamic>)['message']
                    : null)
                ?.toString();
        Get.snackbar(
          'Challenge failed',
          '$message (${code ?? 'unknown'})',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Challenge failed',
        'Unable to connect to the server',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _addChallengeToRandomPool({
    required String title,
    required String duration,
    required String description,
    required String category,
    required String fitnessLevel,
    Uint8List? imageBytes,
  }) {
    final repository = Get.isRegistered<RandomChallengeRepository>()
        ? Get.find<RandomChallengeRepository>()
        : Get.put(RandomChallengeRepository(), permanent: true);
    repository.addChallenge(
      RandomChallenge(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: title,
        subtitle: '$category - $fitnessLevel',
        description: description,
        duration: duration.isNotEmpty ? duration : '00:00 min',
        progress: 0.0,
        timeLimitMinutes: _parseDurationMinutes(duration),
        imageBytes: imageBytes,
        category: category,
      ),
    );
  }

  int _parseDurationMinutes(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    if (match == null) return 5;
    return int.tryParse(match.group(1)!) ?? 5;
  }

  String? _extractRemoteId(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;

    String? _fromMap(Map<String, dynamic> map) {
      const candidates = ['id', 'challenge_id', 'post_id', '_id'];
      for (final key in candidates) {
        final value = map[key];
        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
      return null;
    }

    // 1) Try top-level
    final direct = _fromMap(raw);
    if (direct != null) return direct;

    // 2) Common Laravel wrappers: data, challenge
    for (final key in ['data', 'challenge', 'item']) {
      final nested = raw[key];
      if (nested is Map<String, dynamic>) {
        final nestedId = _fromMap(nested);
        if (nestedId != null) return nestedId;
      }
    }

    // 3) Fallback: scan first nested map that has an id-like field
    for (final value in raw.values) {
      if (value is Map<String, dynamic>) {
        final nestedId = _fromMap(value);
        if (nestedId != null) return nestedId;
      }
    }

    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImageName = file.name;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _openImagePickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // add challenge to random pool
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Add Challenge',
      showAppBar: true,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: 2,
      constrainBody: false,
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _InputBox(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDecoration('Challenge Name'),
                ),
              ),
              const SizedBox(height: 10),
              _InputBox(
                child: TextField(
                  controller: _timeController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDecoration('Time'),
                ),
              ),
              const SizedBox(height: 10),
              _InputBox(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9A9A9A),
                  ),
                  decoration: _fieldDecoration('Select Category'),
                  items: const ['Easy', 'Medium', 'Hard']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _category = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              _InputBox(
                child: DropdownButtonFormField<String>(
                  initialValue: _fitnessLevel,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9A9A9A),
                  ),
                  decoration: _fieldDecoration('Fitness Level'),
                  items: const ['Beginner', 'Intermediate', 'Advanced']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _fitnessLevel = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              _InputBox(
                child: InkWell(
                  onTap: _openImagePickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedImageName == null
                                ? 'Upload Image'
                                : _selectedImageName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7C7C7C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.file_upload_outlined,
                          size: 16,
                          color: Color(0xFF8B8B8B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedImageBytes != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _InputBox(
                height: 98,
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDecoration('Discription'),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _postChallenge,
                  child: const Text(
                    'Post',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9C9C9C)),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    );
  }
}

class _InputBox extends StatelessWidget {
  final Widget child;
  final double height;

  const _InputBox({required this.child, this.height = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6D6D6)),
      ),
      child: child,
    );
  }
}
