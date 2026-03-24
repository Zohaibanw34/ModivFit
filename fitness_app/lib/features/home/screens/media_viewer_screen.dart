import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:fitness_app/core/network/api_config.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/widgets/tiktok_style_action_bar.dart';

class MediaViewerScreen extends StatefulWidget {
  final UserMediaItem media;

  const MediaViewerScreen({super.key, required this.media});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
    _playAttachedSoundIfAny();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoIfNeeded() async {
    if (!widget.media.isVideo) return;
    try {
      final path = widget.media.localPath;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        final controller = VideoPlayerController.file(File(path));
        _videoController = controller;
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setPlaybackSpeed(widget.media.speed);
        await controller.play();
        if (mounted) setState(() {});
        return;
      }

      final remote = widget.media.mediaUrl ?? widget.media.imageUrl;
      if (remote != null && remote.trim().isNotEmpty) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(remote));
        _videoController = controller;
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setPlaybackSpeed(widget.media.speed);
        await controller.play();
        if (mounted) setState(() {});
        return;
      }

      if (mounted) {
        setState(() => _videoError = 'Video source not found');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _videoError = 'Unable to play this video');
      }
    }
  }

  Future<void> _playAttachedSoundIfAny() async {
    final path = widget.media.soundPath;
    if (path == null || path.isEmpty) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(path));
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Center(child: _buildMedia(media))),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 100,
              child: Obx(() {
                final controller = Get.find<HomeProfileController>();
                final item = _currentItem(controller);
                return TikTokStyleActionBar(
                  isLiked: item.isLiked,
                  likeCount: item.likeCount,
                  onLike: () {
                    controller.toggleLike(widget.media.id);
                  },
                  commentCount: item.commentCount,
                  onComment: () => _showCommentsSheet(controller),
                  isSaved: item.isSaved,
                  saveCount: item.saveCount,
                  onSave: () {
                    controller.toggleSave(widget.media.id);
                  },
                  onShare: _sharePost,
                );
              }),
            ),
            Positioned(
              left: 16,
              right: 80,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x80000000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (media.caption.trim().isNotEmpty)
                      Text(
                        media.caption,
                        style: const TextStyle(color: Colors.white),
                      ),
                    if ((media.soundName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Sound: ${media.soundName}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Visibility: ${media.visibility}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  UserMediaItem _currentItem(HomeProfileController controller) {
    final idx = controller.mediaItems.indexWhere((e) => e.id == widget.media.id);
    if (idx >= 0) return controller.mediaItems[idx];
    return widget.media;
  }

  void _sharePost() {
    final link = '${ApiConfig.baseUrl}/posts/${widget.media.id}';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar('Share', 'Link copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  void _showCommentsSheet(HomeProfileController controller) {
    final item = _currentItem(controller);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => _MediaViewerCommentsSheet(
          initialCount: item.commentCount,
          scrollController: scrollController,
          onCommentAdded: () {
            controller.incrementCommentCount(item.id);
          },
        ),
      ),
    );
  }

  Widget _buildMedia(UserMediaItem media) {
    if (media.isVideo) {
      final controller = _videoController;
      if (_videoError != null) {
        return Text(
          _videoError!,
          style: const TextStyle(color: Colors.white70),
        );
      }
      if (controller == null || !controller.value.isInitialized) {
        return const CircularProgressIndicator(color: Colors.white);
      }
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }

    if (media.bytes != null) {
      return Image.memory(media.bytes!, fit: BoxFit.contain);
    }
    if ((media.localPath ?? '').isNotEmpty) {
      return Image.file(File(media.localPath!), fit: BoxFit.contain);
    }
    if ((media.imageUrl ?? '').isNotEmpty) {
      return Image.network(media.imageUrl!, fit: BoxFit.contain);
    }
    return const Icon(Icons.image_not_supported, color: Colors.white70);
  }
}

class _MediaViewerCommentsSheet extends StatefulWidget {
  final int initialCount;
  final ScrollController scrollController;
  final VoidCallback onCommentAdded;

  const _MediaViewerCommentsSheet({
    required this.initialCount,
    required this.scrollController,
    required this.onCommentAdded,
  });

  @override
  State<_MediaViewerCommentsSheet> createState() =>
      _MediaViewerCommentsSheetState();
}

class _MediaViewerCommentsSheetState extends State<_MediaViewerCommentsSheet> {
  final TextEditingController _textController = TextEditingController();
  int _commentCount = 0;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCount;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _posting) return;
    setState(() => _posting = true);
    _textController.clear();
    widget.onCommentAdded();
    if (mounted) setState(() => _commentCount = _commentCount + 1);
    setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_commentCount',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Text(
                'No comments yet.\nBe the first to comment!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _posting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _posting ? null : _postComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
