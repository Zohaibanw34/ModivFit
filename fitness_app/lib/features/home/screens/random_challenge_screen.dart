import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

import 'package:fitness_app/features/home/models/random_challenge.dart';
import 'package:fitness_app/features/home/services/random_challenge_repository.dart';
import 'package:fitness_app/features/home/widgets/category_selection_panel.dart';
import 'package:fitness_app/layout/main_layout.dart';

class RandomChallengeScreen extends StatefulWidget {
  const RandomChallengeScreen({super.key});

  @override
  State<RandomChallengeScreen> createState() => _RandomChallengeScreenState();
}

class _RandomChallengeScreenState extends State<RandomChallengeScreen> {
  static final _rng = Random();
  final List<RandomChallenge> _queue = [];
  late final RandomChallengeRepository _repository;
  RandomChallenge? _currentChallenge;
  late final Worker _challengeWatcher;
  bool _isAdRunning = false;
  String _selectedCategory = kChallengeCategories.first;

  @override
  void initState() {
    super.initState();
    _repository = Get.isRegistered<RandomChallengeRepository>()
        ? Get.find()
        : Get.put(RandomChallengeRepository(), permanent: true);
    _challengeWatcher = ever<List<RandomChallenge>>(
      _repository.observableChallenges,
      (_) => _refreshQueue(),
    );
    _refreshQueue();
  }

  void _prepareQueue() {
    final pool = _filteredChallengePool();
    _queue
      ..clear()
      ..addAll(pool);
    _queue.shuffle(_rng);
  }

  List<RandomChallenge> _filteredChallengePool() {
    final matches = _repository.challenges
        .where((challenge) => challenge.category == _selectedCategory)
        .toList();
    return matches.isEmpty ? _repository.challenges : matches;
  }

  RandomChallenge? _pickNextChallenge() {
    if (_queue.isEmpty) {
      _prepareQueue();
    }
    if (_queue.isEmpty) return null;
    return _queue.removeLast();
  }

  void _refreshQueue() {
    final next = _pickNextChallenge();
    if (!mounted) return;
    setState(() => _currentChallenge = next);
  }

  void _startRandomChallenge() {
    final next = _pickNextChallenge();
    if (next == null) return;
    setState(() {
      _currentChallenge = next;
    });
  }

  void _recordChallenge() {
    if (_currentChallenge == null) return;
    Get.to(
      () => ChallengeRecordingScreen(challenge: _currentChallenge!),
    );
  }

  void _showAdPopup({
    required String title,
    required String message,
    required VoidCallback onSuccess,
  }) {
    if (_isAdRunning) return;
    // Prevent overlapping dialogs by tracking whether we're already showing the ad.
    setState(() => _isAdRunning = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text('Watch the short ad to unlock this action'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Future.delayed(const Duration(seconds: 2));
                  onSuccess();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Watch Ad'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isAdRunning = false);
      }
    });
  }

  void _discardChallenge() {
    if (_currentChallenge == null) return;
    _showAdPopup(
      title: 'Discard Challenge',
      message: 'Abandon the challenge and select a new one.',
      onSuccess: () {
        final next = _pickNextChallenge();
        if (next == null) {
          Get.snackbar('Challenge Discarded', 'No challenge available yet');
          return;
        }
        setState(() => _currentChallenge = next);
        Get.snackbar('Challenge Discarded', 'A fresh challenge is ready');
      },
    );
  }

  void _onCategorySelected(String category) {
    if (category == _selectedCategory) return;
    setState(() {
      _selectedCategory = category;
    });
    _prepareQueue();
    _refreshQueue();
  }

  Future<void> _showCategoryPopup() async {
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: CategorySelectionPanel(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                Navigator.of(dialogContext).pop(category);
              },
            ),
          ),
        );
      },
    );
    if (selected != null) {
      _onCategorySelected(selected);
    }
  }

  @override
  void dispose() {
    _challengeWatcher.dispose();
    super.dispose();
  }

  int get _totalTimeLimitMinutes => _currentChallenge?.timeLimitMinutes ?? 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 420 ? 12.0 : 24.0;

    return MainLayout(
      title: 'Challenges',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 2,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _showCategoryPopup,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 342,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 271,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _isAdRunning || _currentChallenge == null
                                  ? null
                                  : _startRandomChallenge,
                          child: const Text('Start Random Challenge'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Current Challenges",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _buildCategoryChallengeList(),
                ),
                const SizedBox(height: 20),
                _buildCurrentChallengeCard(screenWidth),
                const SizedBox(height: 16),
                const Text(
                  'Challenge Description',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 131,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _currentChallenge?.description ??
                        'Post a challenge from My Post to see it here.',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 24),
                _ActionButtons(
                  onRecord: _currentChallenge != null ? _recordChallenge : null,
                  onDiscard: _currentChallenge != null ? _discardChallenge : null,
                  isBusy: _isAdRunning,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentChallengeCard(double screenWidth) {
    if (_currentChallenge == null) {
      return const _NoChallengeCard();
    }
    final current = _currentChallenge!;
    final progressPercent = current.progress.clamp(0, 1).toDouble();
    final totalMinutes = _totalTimeLimitMinutes;
    final imageSize = screenWidth < 360 ? 60.0 : 80.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: current.imageProvider != null
                        ? Image(
                            image: current.imageProvider!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.fitness_center,
                              size: imageSize * 0.6,
                              color: Colors.grey.shade500,
                            ),
                          ),
                  ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    current.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                    current.subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.black54, size: 18),
                        const SizedBox(width: 4),
                        Text(
                        '${totalMinutes.toString().padLeft(2, '0')}:00 min',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressPercent,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue.shade400,
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(current.progress * 100).round()}% complete',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                'Duration ${current.duration}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChallengeList() {
    final matches = _repository.challenges
        .where((challenge) => challenge.category == _selectedCategory)
        .toList();
    if (matches.isEmpty) {
      return const Center(
        child: Text(
          'No challenges available for this category.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) =>
          _CategoryChallengeTile(challenge: matches[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}

class _CategoryChallengeTile extends StatelessWidget {
  final RandomChallenge challenge;

  const _CategoryChallengeTile({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (challenge.imageProvider != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: challenge.imageProvider!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.grey),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  challenge.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onRecord;
  final VoidCallback? onDiscard;
  final bool isBusy;

  const _ActionButtons({
    Key? key,
    this.onRecord,
    this.onDiscard,
    required this.isBusy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onRecord,
            icon: const Icon(Icons.mic, size: 20),
            label: const Text('Record Challenge'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isBusy ? null : onDiscard,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.black.withOpacity(0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Discard'),
          ),
        ),
      ],
    );
  }
}

class _NoChallengeCard extends StatelessWidget {
  const _NoChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
          Icon(Icons.hourglass_empty, size: 38, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Post a challenge from the feed and it will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class ChallengeRecordingScreen extends StatefulWidget {
  final RandomChallenge challenge;

  const ChallengeRecordingScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeRecordingScreen> createState() =>
      _ChallengeRecordingScreenState();
}

class _ChallengeRecordingScreenState extends State<ChallengeRecordingScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCameraReady = false;
  bool _isRecording = false;
  Timer? _recordingTimer;
  late int _remainingSeconds;

  int get _challengeSeconds => widget.challenge.timeLimitMinutes * 60;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _challengeSeconds;
    _setupCamera();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      final available = await availableCameras();
      // Bail out early if no cameras or widget unmounted to avoid calling setState on disposed state.
      if (!mounted || available.isEmpty) return;
      _cameras = available;
      await _initializeCamera(_cameraIndex);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCameraReady = false);
    }
  }

  Future<void> _initializeCamera(int index) async {
    final camera = _cameras.isNotEmpty ? _cameras[index] : null;
    if (camera == null) return;
    final oldController = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: true,
    );
    await oldController?.dispose();
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _cameraIndex = index;
        _isCameraReady = true;
      });
    } catch (_) {
      controller.dispose();
      if (!mounted) return;
      setState(() => _isCameraReady = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isCameraReady = false);
    await _initializeCamera(nextIndex);
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !_isCameraReady || _isRecording) return;
    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _remainingSeconds = _challengeSeconds;
      });
      // Kick off a timer that counts down the remaining seconds and auto-stops when time is up.
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_remainingSeconds <= 1) {
          timer.cancel();
          setState(() => _remainingSeconds = 0);
          await _finishRecording(auto: true);
          return;
        }
        setState(() => _remainingSeconds -= 1);
      });
    } catch (_) {
      Get.snackbar('Recording failed', 'Unable to start video capture');
    }
  }

  Future<void> _finishRecording({bool auto = false}) async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    try {
      final file = await controller.stopVideoRecording();
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() => _isRecording = false);
      // Notify the user about the recording result and return the saved path.
      final message =
          auto ? 'Challenge time completed' : 'Recording saved successfully';
      Get.snackbar('Challenge recorded', message);
      Get.back(result: file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      Get.snackbar('Recording failed', 'Unable to stop video capture');
    }
  }

  String _formattedRemaining() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _progress() {
    if (_challengeSeconds == 0) return 0;
    return (_challengeSeconds - _remainingSeconds) / _challengeSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Record ${widget.challenge.name}';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraReady && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          Container(
            color: const Color(0xFF0F0F0F),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Remaining ${_formattedRemaining()} / ${widget.challenge.timeLimitMinutes} min',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress(),
                  color: Colors.greenAccent,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isRecording ? () => _finishRecording() : _startRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          size: 20,
                        ),
                        label: Text(
                          _isRecording ? 'Stop' : 'Start recording',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.white,
                          foregroundColor:
                              _isRecording ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_cameras.length > 1)
                      IconButton(
                        onPressed: _switchCamera,
                        color: Colors.white,
                        icon: const Icon(Icons.flip_camera_ios),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.challenge.subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
