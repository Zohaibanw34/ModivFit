import 'dart:typed_data';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/core/network/api_config.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';

class UserMediaItem {
  final String id;
  final Uint8List? bytes;
  final String? localPath;
  final bool isVideo;
  final String? imageUrl;
  final String? mediaUrl;
  final String caption;
  final String visibility;
  final String? soundName;
  final String? soundPath;
  final double speed;
  bool isLiked;
  int likeCount;
  int commentCount;
  bool isSaved;
  int saveCount;

  UserMediaItem({
    required this.id,
    this.bytes,
    this.localPath,
    this.isVideo = false,
    this.imageUrl,
    this.mediaUrl,
    this.caption = '',
    this.visibility = 'Public',
    this.soundName,
    this.soundPath,
    this.speed = 1.0,
    this.isLiked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isSaved = false,
    this.saveCount = 0,
  });
}

class HomeProfileController extends GetxController {
  final AppApiService _apiService = AppApiService();

  final RxString displayName = ''.obs;
  final RxString userName = ''.obs;
  final RxnString userId = RxnString();
  final RxString bio = 'Tap edit profile to add your bio'.obs;
  final Rxn<Uint8List> avatarBytes = Rxn<Uint8List>();
  final RxnString avatarUrl = RxnString();
  final RxInt followingCount = 0.obs;
  final RxInt followerCount = 0.obs;
  final RxBool isSyncing = false.obs;
  final RxnString syncError = RxnString();
  bool _profileLoadedOnce = false;

  final RxList<UserMediaItem> mediaItems = <UserMediaItem>[].obs;

  void setDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    displayName.value = trimmed;
  }

  void setAvatarBytes(Uint8List bytes) {
    avatarBytes.value = bytes;
  }

  void setAvatarUrl(String? value) {
    final url = value?.trim() ?? '';
    avatarUrl.value = url.isEmpty ? null : _resolveImageUrl(url);
  }

  void setUserId(String? value) {
    final cleaned = value?.trim() ?? '';
    userId.value = cleaned.isEmpty ? null : cleaned;
  }

  void setProfile({
    required String name,
    required String username,
    required String userBio,
    Uint8List? avatar,
    String? id,
  }) {
    final trimmedName = name.trim();
    final trimmedUsername = username.trim();
    final trimmedBio = userBio.trim();

    if (trimmedName.isNotEmpty) displayName.value = trimmedName;
    if (trimmedUsername.isNotEmpty) {
      userName.value = trimmedUsername.startsWith('@')
          ? trimmedUsername
          : '@$trimmedUsername';
    }
    bio.value = trimmedBio.isEmpty
        ? 'Tap edit profile to add your bio'
        : trimmedBio;
    if (avatar != null) avatarBytes.value = avatar;
    if (id != null) userId.value = id.trim().isEmpty ? null : id.trim();
  }

  void addMedia(
    Uint8List bytes, {
    String caption = '',
    String visibility = 'Public',
    String? soundName,
    String? soundPath,
  }) {
    final id =
        'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    mediaItems.insert(
      0,
      UserMediaItem(
        id: id,
        bytes: bytes,
        localPath: null,
        caption: caption,
        visibility: visibility,
        soundName: soundName,
        soundPath: soundPath,
      ),
    );
  }

  void addVideoMedia(
    String filePath, {
    String caption = '',
    String visibility = 'Public',
    String? soundName,
    String? soundPath,
    double speed = 1.0,
  }) {
    final id =
        'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    mediaItems.insert(
      0,
      UserMediaItem(
        id: id,
        localPath: filePath,
        isVideo: true,
        mediaUrl: null,
        caption: caption,
        visibility: visibility,
        soundName: soundName,
        soundPath: soundPath,
        speed: speed,
      ),
    );
  }

  void toggleLike(String id) {
    final index = mediaItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = mediaItems[index];
    item.isLiked = !item.isLiked;
    item.likeCount = (item.likeCount + (item.isLiked ? 1 : -1)).clamp(0, 1 << 31);
    mediaItems.refresh();
  }

  void toggleSave(String id) {
    final index = mediaItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = mediaItems[index];
    item.isSaved = !item.isSaved;
    item.saveCount = (item.saveCount + (item.isSaved ? 1 : -1)).clamp(0, 1 << 31);
    mediaItems.refresh();
  }

  void incrementCommentCount(String id) {
    final index = mediaItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    mediaItems[index].commentCount = mediaItems[index].commentCount + 1;
    mediaItems.refresh();
  }

  List<UserMediaItem> get likedMediaItems =>
      mediaItems.where((item) => item.isLiked).toList(growable: false);

  int get likesCount => likedMediaItems.length;

  ImageProvider? get avatarProvider {
    final remoteAvatar = avatarUrl.value;
    if (remoteAvatar != null && remoteAvatar.trim().isNotEmpty) {
      return NetworkImage(remoteAvatar);
    }
    final bytes = avatarBytes.value;
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }

  Future<void> loadProfileFromApi({bool force = false}) async {
    if (_profileLoadedOnce && !force) return;
    isSyncing.value = true;
    syncError.value = null;
    try {
      final result = await _apiService.getProfile();
      final ok = result['ok'] == true;
      if (!ok) {
        syncError.value = 'Unable to load profile (${result['statusCode']})';
        return;
      }
      final basePayload = _extractPayload(result['data']);
      // Some APIs wrap user data inside a `user` key
      final Map<String, dynamic> userPayload =
          basePayload['user'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(basePayload['user'] as Map)
              : basePayload;

      final remoteId = _pickString(userPayload, ['id', 'user_id']);
      final remoteName = _pickString(userPayload, ['name', 'full_name']);
      final remoteUsername = _pickString(userPayload, [
        'username',
        'user_name',
        'handle',
      ]);
      final remoteBio = _pickString(userPayload, ['bio', 'about']);
      final remoteAvatar = _pickString(userPayload, [
        'avatar_url',
        'profile_image_url',
        'image_url',
        'avatar',
        'image',
        'photo_url',
      ]);

      if (remoteName != null && remoteName.trim().isNotEmpty) {
        displayName.value = remoteName.trim();
      }
      if (remoteUsername != null && remoteUsername.trim().isNotEmpty) {
        final trimmed = remoteUsername.trim();
        userName.value = trimmed.startsWith('@') ? trimmed : '@$trimmed';
      }
      if (remoteBio != null) {
        final trimmedBio = remoteBio.trim();
        bio.value = trimmedBio.isEmpty
            ? 'Tap edit profile to add your bio'
            : trimmedBio;
      }
      if (remoteAvatar != null && remoteAvatar.trim().isNotEmpty) {
        setAvatarUrl(remoteAvatar);
        avatarBytes.value = null;
      }

      if (remoteId != null && remoteId.trim().isNotEmpty) {
        setUserId(remoteId.trim());
      }

      _hydrateMediaFromPayload(basePayload);
      final mediaResult = await _apiService.getProfileMedia();
      if (mediaResult['ok'] == true) {
        final mediaPayload = _extractPayload(mediaResult['data']);
        _hydrateMediaFromPayload(mediaPayload);
      }

      _profileLoadedOnce = true;
    } catch (_) {
      syncError.value = 'Unable to connect to server';
    } finally {
      isSyncing.value = false;
    }
  }

  Future<bool> saveProfileToApi({
    required String name,
    required String username,
    required String userBio,
  }) async {
    isSyncing.value = true;
    syncError.value = null;
    try {
      final trimmedName = name.trim();
      final trimmedUsername = username.trim();
      final cleanUsername = trimmedUsername.startsWith('@')
          ? trimmedUsername.substring(1)
          : trimmedUsername;
      final trimmedBio = userBio.trim();

      final result = await _apiService.updateProfile({
        'name': trimmedName,
        'username': cleanUsername,
        'user_name': cleanUsername,
        'bio': trimmedBio,
      });

      final ok = result['ok'] == true;
      if (!ok) {
        syncError.value = 'Unable to save profile (${result['statusCode']})';
        return false;
      }

      setProfile(
        name: trimmedName,
        username: cleanUsername,
        userBio: trimmedBio,
      );
      return true;
    } catch (_) {
      syncError.value = 'Unable to connect to server';
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  Future<bool> uploadAvatarToApi(String imagePath) async {
    isSyncing.value = true;
    syncError.value = null;
    try {
      final result = await _apiService.uploadProfileImage(File(imagePath));
      final ok = result['ok'] == true;
      if (!ok) {
        syncError.value =
            'Unable to upload profile image (${result['statusCode']})';
      } else {
        final payload = _extractPayload(result['data']);
      final remoteAvatar = _pickString(payload, [
        'avatar_url',
        'profile_image_url',
        'image_url',
        'avatar',
        'image',
        'photo_url',
      ]);

      final remoteId = _pickString(payload, ['id', 'user_id']);
      if (remoteId != null && remoteId.trim().isNotEmpty) {
        setUserId(remoteId.trim());
      }
        if (remoteAvatar != null && remoteAvatar.trim().isNotEmpty) {
          setAvatarUrl(remoteAvatar);
          avatarBytes.value = null;
        } else {
          await loadProfileFromApi(force: true);
        }
      }
      return ok;
    } catch (_) {
      syncError.value = 'Unable to connect to server';
      return false;
    } finally {
      isSyncing.value = false;
    }
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
      if (value is String) return value;
    }
    return null;
  }

  int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  bool? _pickBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final v = value.trim().toLowerCase();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
    }
    return null;
  }

  String _resolveImageUrl(String raw) {
    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null &&
          (uri.host == '127.0.0.1' || uri.host == 'localhost')) {
        final fixed = uri.replace(host: ApiConfig.host);
        return fixed.toString();
      }
      return value;
    }
    if (value.startsWith('/')) {
      return '${ApiConfig.baseUrl}$value';
    }
    return '${ApiConfig.baseUrl}/$value';
  }

  Future<bool> createMediaPost({
    required bool isVideo,
    String? mediaPath,
    Uint8List? imageBytes,
    String caption = '',
    String visibility = 'Public',
    String? soundName,
    String? soundPath,
    double speed = 1.0,
  }) async {
    final trimmedCaption = caption.trim();
    final trimmedVisibility = visibility.trim().isEmpty ? 'Public' : visibility;

    final localFilePath = mediaPath?.trim() ?? '';
    if (localFilePath.isEmpty && imageBytes == null) {
      syncError.value = 'No media selected';
      return false;
    }

    if (localFilePath.isNotEmpty) {
      final file = File(localFilePath);
      if (!file.existsSync()) {
        syncError.value = 'Selected file does not exist';
        return false;
      }
    }

    final fallbackLocalId =
        'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';

    isSyncing.value = true;
    syncError.value = null;
    try {
      if (localFilePath.isNotEmpty) {
        final file = File(localFilePath);
        final Map<String, dynamic> result;
        if (isVideo) {
          final postFuture = _apiService.uploadMediaPost(
            mediaFile: file,
            isVideo: true,
            caption: trimmedCaption,
            visibility: trimmedVisibility,
            soundName: soundName,
            soundPath: soundPath,
            speed: speed,
          );
          final reelFuture = _apiService.uploadReel(
            mediaFile: file,
            caption: trimmedCaption,
          );
          final results = await Future.wait([postFuture, reelFuture]);
          result = results[0] as Map<String, dynamic>;
        } else {
          result = await _apiService.uploadMediaPost(
            mediaFile: file,
            isVideo: false,
            caption: trimmedCaption,
            visibility: trimmedVisibility,
            soundName: soundName,
            soundPath: soundPath,
            speed: speed,
          );
        }

        if (result['ok'] == true) {
          final payload = _extractPayload(result['data']);
          final remoteId = _pickString(payload, ['id', 'post_id', '_id']);
          final remoteCaption = _pickString(payload, [
            'caption',
            'description',
            'text',
          ]);
          final remoteVisibility = _pickString(payload, [
            'visibility',
            'scope',
          ]);
          final remoteSoundName = _pickString(payload, [
            'sound_name',
            'sound',
            'music_name',
          ]);
          final remoteMediaUrl = _pickString(payload, [
            'media_url',
            'video_url',
            'image_url',
            'file_url',
            'url',
          ]);
          final remoteThumbUrl = _pickString(payload, [
            'thumbnail_url',
            'thumb_url',
            'preview_url',
            'image_url',
          ]);
          final remoteType = _pickString(payload, [
            'type',
            'media_type',
            'kind',
          ]);
          final remoteIsVideo =
              (remoteType ?? '').toLowerCase() == 'video' ||
              (remoteMediaUrl ?? '').toLowerCase().contains('.mp4');

          mediaItems.insert(
            0,
            UserMediaItem(
              id: remoteId ?? fallbackLocalId,
              isVideo: isVideo || remoteIsVideo,
              localPath: localFilePath,
              mediaUrl: remoteMediaUrl == null
                  ? null
                  : _resolveImageUrl(remoteMediaUrl),
              imageUrl: remoteThumbUrl == null
                  ? null
                  : _resolveImageUrl(remoteThumbUrl),
              caption: (remoteCaption ?? trimmedCaption).trim(),
              visibility: (remoteVisibility ?? trimmedVisibility).trim(),
              soundName: (remoteSoundName ?? soundName)?.trim(),
              soundPath: soundPath,
              speed: speed,
            ),
          );
          return true;
        }

        final data = result['data'];
        final message = data is Map<String, dynamic>
            ? (data['message']?.toString() ?? '')
            : '';
        final tried = data is Map<String, dynamic> ? data['tried'] : null;
        final triedText = tried is List && tried.isNotEmpty
            ? ' Tried: ${tried.map((e) => (e as Map)['endpoint']).join(', ')}'
            : '';
        syncError.value =
            'Upload failed (${result['statusCode']}) ${message.trim()}$triedText';
        return false;
      }

      if (imageBytes != null) {
        addMedia(
          imageBytes,
          caption: trimmedCaption,
          visibility: trimmedVisibility,
          soundName: soundName,
          soundPath: soundPath,
        );
        return true;
      }

      syncError.value = 'No media selected';
      return false;
    } catch (_) {
      syncError.value = 'Unable to connect to server';
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  void _hydrateMediaFromPayload(Map<String, dynamic> payload) {
    final list = _pickMediaList(payload);
    if (list == null || list.isEmpty) return;

    final hydrated = <UserMediaItem>[];
    for (final raw in list) {
      if (raw is! Map<String, dynamic>) continue;
      final id =
          _pickString(raw, ['id', 'post_id', '_id']) ??
          'remote_${hydrated.length}_${DateTime.now().millisecondsSinceEpoch}';
      final caption =
          _pickString(raw, ['caption', 'description', 'text']) ?? '';
      final visibility = _pickString(raw, ['visibility', 'scope']) ?? 'Public';
      final soundName = _pickString(raw, ['sound_name', 'sound', 'music_name']);
      final mediaUrl = _pickString(raw, [
        'media_url',
        'video_url',
        'image_url',
        'file_url',
        'url',
      ]);
      final thumbUrl = _pickString(raw, [
        'thumbnail_url',
        'thumb_url',
        'preview_url',
        'image_url',
      ]);
      final mediaType = _pickString(raw, ['type', 'media_type', 'kind']) ?? '';
      final isVideo =
          mediaType.toLowerCase() == 'video' ||
          (mediaUrl ?? '').toLowerCase().contains('.mp4');
      final likeCount = _pickInt(raw, ['like_count', 'likes_count', 'likes']) ?? 0;
      final commentCount = _pickInt(raw, ['comment_count', 'comments_count', 'comments']) ?? 0;
      final saveCount = _pickInt(raw, ['save_count', 'saves', 'favorite_count']) ?? 0;
      final isLiked = _pickBool(raw, ['is_liked', 'liked']) ?? false;
      final isSaved = _pickBool(raw, ['is_saved', 'saved', 'is_favorite']) ?? false;

      hydrated.add(
        UserMediaItem(
          id: id,
          isVideo: isVideo,
          mediaUrl: mediaUrl == null ? null : _resolveImageUrl(mediaUrl),
          imageUrl: thumbUrl == null ? null : _resolveImageUrl(thumbUrl),
          caption: caption,
          visibility: visibility,
          soundName: soundName,
          likeCount: likeCount,
          commentCount: commentCount,
          saveCount: saveCount,
          isLiked: isLiked,
          isSaved: isSaved,
        ),
      );
    }

    if (hydrated.isNotEmpty) {
      mediaItems.assignAll(hydrated);
    }
  }

  List<dynamic>? _pickMediaList(Map<String, dynamic> map) {
    const keys = <String>[
      'media',
      'posts',
      'items',
      'media_items',
      'profile_media',
      'data',
    ];
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        for (final nestedKey in keys) {
          final nested = value[nestedKey];
          if (nested is List) return nested;
        }
      }
    }
    return null;
  }
}
