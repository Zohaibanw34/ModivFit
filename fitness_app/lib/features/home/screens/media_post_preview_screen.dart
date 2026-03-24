import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class MediaPostPreviewScreen extends StatefulWidget {
  final bool isVideo;
  final Uint8List? imageBytes;
  final String? mediaPath;
  final String? imagePath;
  final double speed;

  const MediaPostPreviewScreen({
    super.key,
    required this.isVideo,
    this.imageBytes,
    this.mediaPath,
    this.imagePath,
    this.speed = 1.0,
  });

  @override
  State<MediaPostPreviewScreen> createState() => _MediaPostPreviewScreenState();
}

class _MediaPostPreviewScreenState extends State<MediaPostPreviewScreen> {
  late final HomeProfileController _profileController;
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;

  String _visibility = 'Public';
  String? _soundName;
  String? _soundPath;
  bool _isPosting = false;

  final List<String> _favoriteSounds = <String>[
    'Morning Energy',
    'Gym Flow',
    'Night Cardio',
    'Power Lift Beat',
  ];

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
    _initializeVideoIfNeeded();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoIfNeeded() async {
    if (!widget.isVideo || widget.mediaPath == null) return;
    final controller = VideoPlayerController.file(File(widget.mediaPath!));
    _videoController = controller;
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setPlaybackSpeed(widget.speed);
    await controller.play();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickSoundFromPhone() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    setState(() {
      _soundName = file.name;
      _soundPath = file.path;
    });
  }

  Future<void> _openAddSoundSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add sounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.library_music, color: Colors.white),
                  title: const Text(
                    'Choose from phone',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickSoundFromPhone();
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saved / Favorites',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ..._favoriteSounds.map(
                  (sound) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.music_note, color: Colors.white),
                    title: Text(
                      sound,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() {
                        _soundName = sound;
                        _soundPath = null;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _postNow() async {
    if (_isPosting) return;
    setState(() => _isPosting = true);
    if (widget.isVideo) {
      Get.snackbar(
        'Uploading',
        'Video upload may take a minute…',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
    final caption = _captionController.text.trim();
    final uploaded = await _profileController.createMediaPost(
      isVideo: widget.isVideo,
      mediaPath: widget.isVideo ? widget.mediaPath : widget.imagePath,
      imageBytes: widget.imageBytes,
      caption: caption,
      visibility: _visibility,
      soundName: _soundName,
      soundPath: _soundPath,
      speed: widget.speed,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);
    if (!uploaded) {
      final msg = _profileController.syncError.value ?? 'Unable to post media';
      Get.snackbar('Post', msg, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildPreview()),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(result: false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _openAddSoundSheet,
                        icon: const Icon(Icons.music_note, color: Colors.white),
                        label: Text(
                          _soundName == null ? 'Add sounds' : _soundName!,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0x4D000000),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Column(
                children: [
                  SizedBox(
                    width: 349,
                    height: 45,
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a caption',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0x66000000),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 350,
                    height: 38,
                    child: Row(
                      children: [
                        Container(
                          width: 130,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x66000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _visibility,
                              dropdownColor: const Color(0xFF171717),
                              style: const TextStyle(color: Colors.white),
                              iconEnabledColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Public',
                                  child: Text('Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'Private',
                                  child: Text('Private'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _visibility = value);
                              },
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 90,
                          height: 38,
                          child: ElevatedButton(
                            onPressed: _isPosting ? null : _postNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE84C64),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isPosting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Post',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
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

  Widget _buildPreview() {
    if (widget.isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }

    if (widget.imageBytes != null) {
      return Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    }
    if (widget.mediaPath != null && widget.mediaPath!.isNotEmpty) {
      return Image.file(File(widget.mediaPath!), fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }
}
