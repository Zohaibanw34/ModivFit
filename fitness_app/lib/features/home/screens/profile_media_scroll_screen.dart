import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:fitness_app/core/network/api_config.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/widgets/tiktok_style_action_bar.dart';

class ProfileMediaScrollScreen extends StatefulWidget {
  final List<UserMediaItem> items;
  final int initialIndex;

  const ProfileMediaScrollScreen({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<ProfileMediaScrollScreen> createState() =>
      _ProfileMediaScrollScreenState();
}

class _ProfileMediaScrollScreenState extends State<ProfileMediaScrollScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'No media',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final media = widget.items[index];
              final isActive = index == _currentIndex;
              return _ProfileMediaSlide(
                media: media,
                isActive: isActive,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 100,
            child: SafeArea(
              child: _currentIndex >= 0 && _currentIndex < widget.items.length
                  ? _buildActionBar(widget.items[_currentIndex])
                  : const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SafeArea(
              child: Text(
                '${_currentIndex + 1} / ${widget.items.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(UserMediaItem item) {
    final controller = Get.find<HomeProfileController>();
    return TikTokStyleActionBar(
      isLiked: item.isLiked,
      likeCount: item.likeCount,
      onLike: () {
        controller.toggleLike(item.id);
        setState(() {});
      },
      commentCount: item.commentCount,
      onComment: () => _showCommentsSheet(item, controller),
      isSaved: item.isSaved,
      saveCount: item.saveCount,
      onSave: () {
        controller.toggleSave(item.id);
        setState(() {});
      },
      onShare: () => _sharePost(item),
    );
  }

  void _sharePost(UserMediaItem item) {
    final link = '${ApiConfig.baseUrl}/posts/${item.id}';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar('Share', 'Link copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  void _showCommentsSheet(UserMediaItem item, HomeProfileController controller) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => _PostCommentsSheet(
          postId: item.id,
          initialCount: item.commentCount,
          scrollController: scrollController,
          onCommentAdded: () {
            controller.incrementCommentCount(item.id);
            setState(() {});
          },
        ),
      ),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  final String postId;
  final int initialCount;
  final ScrollController scrollController;
  final VoidCallback onCommentAdded;

  const _PostCommentsSheet({
    required this.postId,
    required this.initialCount,
    required this.scrollController,
    required this.onCommentAdded,
  });

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
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
              color: Colors.grey[300],
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

class _ProfileMediaSlide extends StatefulWidget {
  final UserMediaItem media;
  final bool isActive;

  const _ProfileMediaSlide({
    required this.media,
    required this.isActive,
  });

  @override
  State<_ProfileMediaSlide> createState() => _ProfileMediaSlideState();
}

class _ProfileMediaSlideState extends State<_ProfileMediaSlide> {
  VideoPlayerController? _videoController;
  String? _videoError;
  bool _initialized = false;

  @override
  void didUpdateWidget(covariant _ProfileMediaSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initVideoIfNeeded();
      } else {
        _disposeVideo();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initVideoIfNeeded();
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _initialized = false;
    if (mounted) setState(() {});
  }

  Future<void> _initVideoIfNeeded() async {
    if (!widget.media.isVideo || _initialized) return;
    try {
      final path = widget.media.localPath;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        final controller = VideoPlayerController.file(File(path));
        _videoController = controller;
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setPlaybackSpeed(widget.media.speed);
        await controller.play();
        if (mounted) {
          setState(() => _initialized = true);
        }
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
        if (mounted) {
          setState(() => _initialized = true);
        }
        return;
      }

      if (mounted) {
        setState(() => _videoError = 'Video source not found');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _videoError = 'Unable to play video');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;

    if (media.isVideo) {
      final controller = _videoController;
      if (_videoError != null) {
        return Center(
          child: Text(
            _videoError!,
            style: const TextStyle(color: Colors.white70),
          ),
        );
      }
      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    if (media.bytes != null) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.memory(media.bytes!, fit: BoxFit.contain),
        ),
      );
    }
    if ((media.localPath ?? '').isNotEmpty) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.file(File(media.localPath!), fit: BoxFit.contain),
        ),
      );
    }
    if ((media.imageUrl ?? media.mediaUrl ?? '').isNotEmpty) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.network(
            media.imageUrl ?? media.mediaUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, __, ___) => const Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.media_bluetooth_off, color: Colors.white54, size: 48),
    );
  }
}
