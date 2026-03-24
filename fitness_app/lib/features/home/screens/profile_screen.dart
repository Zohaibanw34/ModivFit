import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/screens/follow_list_screen.dart';
import 'package:fitness_app/features/home/screens/media_viewer_screen.dart';
import 'package:fitness_app/features/home/screens/profile_media_scroll_screen.dart';
import 'package:fitness_app/layout/main_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final HomeProfileController _profileController;
  int _tabIndex = 0; // 0 = Public, 1 = Likes

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileController.loadProfileFromApi();
    });
  }

  Future<void> _openEditProfileSheet() async {
    if (!mounted) return;

    final nameCtrl = TextEditingController(
      text: _profileController.displayName.value,
    );
    final userCtrl = TextEditingController(
      text: _profileController.userName.value,
    );
    final bioCtrl = TextEditingController(text: _profileController.bio.value);
    Uint8List? selectedAvatar;
    String? selectedAvatarPath;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          setSheetState(() {
                            selectedAvatar = bytes;
                            selectedAvatarPath = picked.path;
                          });
                        },
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: selectedAvatar != null
                              ? MemoryImage(selectedAvatar!)
                              : _profileController.avatarProvider,
                          backgroundColor: const Color(0xFFEAEAEA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () {
                          if (Navigator.of(sheetContext).canPop()) {
                            Navigator.of(sheetContext).pop({
                              'name': nameCtrl.text,
                              'username': userCtrl.text,
                              'bio': bioCtrl.text,
                              'avatar': selectedAvatar,
                              'avatarPath': selectedAvatarPath,
                            });
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      final name = (result['name'] ?? '').toString();
      final username = (result['username'] ?? '').toString();
      final userBio = (result['bio'] ?? '').toString();
      final avatarPath = (result['avatarPath'] ?? '').toString();

      if (avatarPath.isNotEmpty) {
        await _profileController.uploadAvatarToApi(avatarPath);
        await _profileController.loadProfileFromApi(force: true);
      }

      final saved = await _profileController.saveProfileToApi(
        name: name,
        username: username,
        userBio: userBio,
      );
      if (!saved && mounted) {
        Get.snackbar(
          'Profile',
          _profileController.syncError.value ?? 'Profile save failed',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    nameCtrl.dispose();
    userCtrl.dispose();
    bioCtrl.dispose();
  }

  void _openFollowList(String type) {
    Get.to(() => FollowListScreen(type: type));
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Profile',
      showBottomNav: true,
      currentIndex: 0,
      body: Container(
        color: const Color(0xFFF6F6F6),
        child: SafeArea(
          child: Obx(() {
            final items = _tabIndex == 0
                ? _profileController.mediaItems.toList(growable: false)
                : _profileController.likedMediaItems;
            final displayNameValue = _profileController.displayName.value.trim();
            final usernameValue = _profileController.userName.value.trim();
            final displayNameText =
                displayNameValue.isEmpty ? 'Add your name' : displayNameValue;
            final usernameText = usernameValue.isEmpty
                ? 'Tap edit profile to set a username'
                : usernameValue;
            final avatarProvider = _profileController.avatarProvider;
            final mediaEmptyMessage = _tabIndex == 0
                ? 'Upload something from your phone to populate this grid.'
                : 'Like a post to keep it here.';

            return Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  displayNameText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 48,
                  backgroundImage: avatarProvider,
                  backgroundColor: const Color(0xFFEAEAEA),
                  child: avatarProvider == null
                      ? const Icon(Icons.person, size: 32, color: Colors.black54)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  usernameText,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _openFollowList('Following'),
                      child: _StatItem(
                        label: 'Following',
                        value: _profileController.followingCount.value,
                      ),
                    ),
                    const SizedBox(width: 26),
                    GestureDetector(
                      onTap: () => _openFollowList('Followers'),
                      child: _StatItem(
                        label: 'Followers',
                        value: _profileController.followerCount.value,
                      ),
                    ),
                    const SizedBox(width: 26),
                    _StatItem(
                      label: 'Likes',
                      value: _profileController.likesCount,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: _openEditProfileSheet,
                    child: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profileController.bio.value,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                _ProfileTabs(
                  selectedIndex: _tabIndex,
                  onTap: (index) => setState(() => _tabIndex = index),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            mediaEmptyMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final media = items[index];
                            return GestureDetector(
                              onTap: () => Get.to(
                                () => ProfileMediaScrollScreen(
                                  items: items,
                                  initialIndex: index,
                                ),
                              ),
                              onDoubleTap: () =>
                                  _profileController.toggleLike(media.id),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (media.bytes != null)
                                    Image.memory(media.bytes!, fit: BoxFit.cover)
                                  else if (media.isVideo &&
                                      (media.imageUrl ?? media.mediaUrl ?? '')
                                          .trim()
                                          .isEmpty)
                                    Container(
                                      color: Colors.black87,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    )
                                  else if (media.isVideo)
                                    _VideoGridThumbnail(
                                      imageUrl: media.imageUrl,
                                      mediaUrl: media.mediaUrl,
                                      localPath: media.localPath,
                                    )
                                  else if ((media.localPath ?? '').isNotEmpty)
                                    Image.file(
                                      File(media.localPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: const Color(0xFFE8E8E8),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    )
                                  else
                                    Image.network(
                                      media.imageUrl ?? media.mediaUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: const Color(0xFFE8E8E8),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _profileController.toggleLike(media.id),
                                      child: Icon(
                                        media.isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: media.isLiked
                                            ? Colors.red
                                            : Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  if (media.caption.trim().isNotEmpty)
                                    Positioned(
                                      left: 6,
                                      right: 6,
                                      bottom: 6,
                                      child: Text(
                                        media.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ProfileTabs({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Public',
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _TabButton(
            label: 'Likes',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// In-memory cache for video thumbnails (URL/path -> image bytes).
final Map<String, Uint8List?> _videoThumbCache = <String, Uint8List?>{};

/// Shows a thumbnail for a video in the profile grid, or a play-icon placeholder.
class _VideoGridThumbnail extends StatefulWidget {
  final String? imageUrl;
  final String? mediaUrl;
  final String? localPath;

  const _VideoGridThumbnail({
    this.imageUrl,
    this.mediaUrl,
    this.localPath,
  });

  @override
  State<_VideoGridThumbnail> createState() => _VideoGridThumbnailState();
}

class _VideoGridThumbnailState extends State<_VideoGridThumbnail> {
  Uint8List? _thumbBytes;
  bool _loadFailed = false;

  static Widget _placeholder() => Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 40,
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  /// True if we have a backend-provided image URL (use Image.network, not video thumbnail).
  bool get _hasImageUrl =>
      (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty);

  Future<void> _loadThumbnail() async {
    if (_hasImageUrl) return;

    final mediaUrl = widget.mediaUrl?.trim();
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      try {
        final cached = _videoThumbCache[mediaUrl];
        if (cached != null && mounted) {
          setState(() => _thumbBytes = cached);
          return;
        }
        final bytes = await _thumbnailFromVideoUrl(mediaUrl);
        if (!mounted) return;
        _videoThumbCache[mediaUrl] = bytes;
        setState(() {
          _thumbBytes = bytes;
          _loadFailed = bytes == null;
        });
      } catch (_) {
        if (mounted) setState(() => _loadFailed = true);
      }
      return;
    }

    final localPath = widget.localPath?.trim();
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      try {
        final cached = _videoThumbCache[localPath];
        if (cached != null && mounted) {
          setState(() => _thumbBytes = cached);
          return;
        }
        final bytes = await VideoThumbnail.thumbnailData(
          video: localPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 400,
          quality: 70,
        );
        if (!mounted) return;
        _videoThumbCache[localPath] = bytes;
        setState(() {
          _thumbBytes = bytes;
          _loadFailed = bytes == null;
        });
      } catch (_) {
        if (mounted) setState(() => _loadFailed = true);
      }
    }
  }

  Future<Uint8List?> _thumbnailFromVideoUrl(String url) async {
    final cached = _videoThumbCache[url];
    if (cached != null) return cached;

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/thumb_${url.hashCode}.mp4');
      if (!file.existsSync()) {
        final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Timeout'),
          );
        if (response.statusCode != 200) return null;
        await file.writeAsBytes(response.bodyBytes);
      }
      final bytes = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 70,
      );
      try {
        file.deleteSync();
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasImageUrl) {
      return Image.network(
        widget.imageUrl!.trim(),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black87,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (_loadFailed) return _placeholder();
    if (_thumbBytes != null) {
      return Image.memory(_thumbBytes!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.black87,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
