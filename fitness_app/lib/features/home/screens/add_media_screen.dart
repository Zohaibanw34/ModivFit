import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:fitness_app/features/home/screens/media_post_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddMediaScreen extends StatefulWidget {
  const AddMediaScreen({super.key});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final ImagePicker _picker = ImagePicker();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  int _cameraIndex = 0;
  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _flashOn = false;
  double _videoSpeed = 1.0;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _initializeCamera(_cameraIndex);
    } catch (_) {}
  }

  Future<void> _initializeCamera(int index) async {
    final oldController = _cameraController;
    final camera = _cameras[index];
    final controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await oldController?.dispose();
    _cameraController = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() {
        _cameraIndex = index;
        _isCameraReady = true;
        _flashOn = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCameraReady = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isCameraReady = false);
    await _initializeCamera(nextIndex);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !_isCameraReady) return;
    final next = !_flashOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    if (!mounted) return;
    setState(() => _flashOn = next);
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMedia();
    if (picked == null) return;
    final isVideo =
        picked.mimeType?.startsWith('video/') == true ||
        _isVideoFile(picked.path);

    if (isVideo) {
      await _openPostComposer(isVideo: true, mediaPath: picked.path);
      return;
    }

    final bytes = await picked.readAsBytes();
    await _openPostComposer(
      isVideo: false,
      imageBytes: bytes,
      imagePath: picked.path,
    );
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !_isCameraReady || _isRecording) return;
    final file = await controller.takePicture();
    final bytes = await file.readAsBytes();
    await _openPostComposer(
      isVideo: false,
      imageBytes: bytes,
      imagePath: file.path,
    );
  }

  Future<void> _toggleVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !_isCameraReady) return;

    if (_isRecording) {
      try {
        final file = await controller.stopVideoRecording();
        if (!mounted) return;
        setState(() => _isRecording = false);
        await _openPostComposer(isVideo: true, mediaPath: file.path);
      } catch (_) {
        if (mounted) setState(() => _isRecording = false);
        Get.snackbar('Recording failed', 'Unable to stop video capture');
      }
      return;
    }

    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);
    } catch (_) {
      Get.snackbar('Recording failed', 'Unable to start video capture');
    }
  }

  Future<void> _startTimerAndRecord() async {
    if (_isRecording || _countdown > 0) return;
    setState(() => _countdown = 3);
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        await _toggleVideoRecording();
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  Future<void> _setVideoSpeed(double speed) async {
    setState(() => _videoSpeed = speed);
  }

  Future<void> _openSpeedSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Video Speed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _videoSpeed,
                    min: 0.25,
                    max: 3.0,
                    divisions: 11,
                    activeColor: const Color(0xFFE84C64),
                    label: '${_videoSpeed.toStringAsFixed(2)}x',
                    onChanged: (value) async {
                      setSheetState(() => _videoSpeed = value);
                      await _setVideoSpeed(value);
                    },
                  ),
                  Text(
                    '${_videoSpeed.toStringAsFixed(2)}x',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPostComposer({
    required bool isVideo,
    Uint8List? imageBytes,
    String? mediaPath,
    String? imagePath,
  }) async {
    final posted = await Get.to<bool>(
      () => MediaPostPreviewScreen(
        isVideo: isVideo,
        imageBytes: imageBytes,
        mediaPath: mediaPath,
        imagePath: imagePath,
        speed: _videoSpeed,
      ),
    );

    if (posted == true && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isCameraReady && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              right: 14,
              top: 94,
              child: SizedBox(
                width: 29,
                height: 223,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ControlAction(
                      icon: Icons.flip_camera_ios_outlined,
                      label: 'Flip',
                      onTap: _flipCamera,
                    ),
                    _ControlAction(
                      icon: Icons.speed_outlined,
                      label: 'Speed',
                      onTap: _openSpeedSheet,
                    ),
                    _ControlAction(
                      icon: Icons.timer_outlined,
                      label: 'Timer',
                      onTap: _startTimerAndRecord,
                    ),
                    _ControlAction(
                      icon: _flashOn
                          ? Icons.flash_on_outlined
                          : Icons.flash_off_outlined,
                      label: 'Flash',
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
            if (_countdown > 0)
              Positioned.fill(
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  GestureDetector(
                    onTap: _capturePhoto,
                    onLongPress: _toggleVideoRecording,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? const Color(0xFFE84C64)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleVideoRecording,
                    icon: Icon(
                      _isRecording
                          ? Icons.stop_circle_outlined
                          : Icons.videocam_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
        ],
      ),
    );
  }
}
