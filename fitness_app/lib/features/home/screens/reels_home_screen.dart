import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/models/reel_item.dart';
import 'package:fitness_app/features/home/screens/reels_watch_screen.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/features/home/widgets/empty_error_view.dart';
import 'package:fitness_app/layout/main_layout.dart';

class ReelsHomeScreen extends StatefulWidget {
  const ReelsHomeScreen({super.key});

  @override
  State<ReelsHomeScreen> createState() => _ReelsHomeScreenState();
}

class _ReelsHomeScreenState extends State<ReelsHomeScreen> {
  final AppApiService _apiService = AppApiService();
  final List<ReelItem> _items = <ReelItem>[];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;
  bool _hasOpenedWatchFromAdd = false;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadReels();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_loadingMore || _isLoading || _error != null) return;
    if (_currentPage >= _lastPage) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMoreReels();
  }

  Future<void> _loadReels() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });
    final searchQuery = _searchController.text.trim();
    try {
      final result = await _apiService.getReels(search: searchQuery.isEmpty ? null : searchQuery, page: 1);
      final ok = result['ok'] == true || result['success'] == true;
      if (!ok) {
        setState(() {
          _error = 'Unable to load reels';
          _isLoading = false;
        });
        return;
      }
      final data = result['data'] ?? result;
      final pagination = data['pagination'] is Map ? data['pagination'] as Map<String, dynamic> : null;
      if (pagination != null) {
        _currentPage = (pagination['current_page'] is int) ? pagination['current_page'] as int : 1;
        _lastPage = (pagination['last_page'] is int) ? pagination['last_page'] as int : 1;
      }
      final list = _extractList(data)
          .map(_reelFromMap)
          .whereType<ReelItem>()
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _isLoading = false;
      });
      final openWatch = !_hasOpenedWatchFromAdd &&
          Get.arguments is Map &&
          (Get.arguments as Map)['openWatchView'] == true;
      if (openWatch && _items.isNotEmpty) {
        _hasOpenedWatchFromAdd = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Get.to(
            () => ReelsWatchScreen(
              items: List<ReelItem>.from(_items),
              initialIndex: 0,
            ),
          );
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Unable to connect to server';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReels() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() => _loadingMore = true);
    final searchQuery = _searchController.text.trim();
    try {
      final result = await _apiService.getReels(
        search: searchQuery.isEmpty ? null : searchQuery,
        page: _currentPage + 1,
      );
      final ok = result['ok'] == true || result['success'] == true;
      if (!ok || !mounted) {
        setState(() => _loadingMore = false);
        return;
      }
      final data = result['data'] ?? result;
      final pagination = data['pagination'] is Map ? data['pagination'] as Map<String, dynamic> : null;
      if (pagination != null && mounted) {
        _currentPage = (pagination['current_page'] is int) ? pagination['current_page'] as int : _currentPage + 1;
        _lastPage = (pagination['last_page'] is int) ? pagination['last_page'] as int : _lastPage;
      }
      final list = _extractList(data)
          .map(_reelFromMap)
          .whereType<ReelItem>()
          .toList(growable: false);
      final existingIds = _items.map((e) => e.id).toSet();
      final newItems = list.where((e) => !existingIds.contains(e.id)).toList();
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .where((e) => e is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      final nested = raw['items'] ?? raw['data'];
      if (nested is List) {
        return nested
            .where((e) => e is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  ReelItem? _reelFromMap(Map<String, dynamic> map) {
    String _string(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    int _int(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    bool _bool(List<String> keys) {
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
      return false;
    }

    final id = _string(['id', 'reel_id']);
    if (id.isEmpty) return null;

    final user = map['user'] is Map<String, dynamic>
        ? map['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    String _userString(Map<String, dynamic> src, List<String> keys) {
      for (final key in keys) {
        final value = src[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final userId = _string(['user_id']);
    final userName = _string(['user_name', 'username', 'name']);
    final handle = _string(['handle', 'user_handle', 'username']);
    final avatar = _string([
      'avatar_url',
      'profile_image',
      'profile_image_url',
      'image_url',
    ]);
    final media = _string(['media_url', 'url', 'video_url', 'image_url']);
    final caption = _string(['caption', 'description', 'title']);
    final likeCount = _int(['like_count', 'likes', 'likes_count']);
    final commentCount = _int(['comment_count', 'comments_count', 'comments']);
    final createdAtRaw = _string(['created_at', 'timestamp', 'time']);
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtRaw);
    } catch (_) {
      createdAt = DateTime.now();
    }

    if (media.isEmpty) return null;

    final hashtagsRaw = map['hashtags'];
    final hashtags = <String>[];
    if (hashtagsRaw is List) {
      for (final tag in hashtagsRaw) {
        if (tag == null) continue;
        final text = tag.toString().trim();
        if (text.isNotEmpty) hashtags.add(text);
      }
    }

    final resolvedUserId = userId.isNotEmpty
        ? userId
        : _userString(user, ['id']);
    final resolvedUserName = userName.isNotEmpty
        ? userName
        : _userString(user, ['name']);
    final resolvedHandle = handle.isNotEmpty
        ? handle
        : _userString(user, ['user_name', 'username']);
    final resolvedAvatar = avatar.isNotEmpty
        ? avatar
        : _userString(user, ['media']);

    return ReelItem(
      id: id,
      userId: resolvedUserId,
      userName: resolvedUserName.isNotEmpty ? resolvedUserName : 'User',
      userHandle: resolvedHandle,
      profileImage: resolvedAvatar.isNotEmpty
          ? resolvedAvatar
          : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      previewImage: media,
      ageText: '',
      createdAt: createdAt,
      description: caption,
      hashtags: hashtags,
      likeCount: likeCount,
      dislikeCount: _int(['dislike_count', 'dislikes_count']),
      favoriteCount: _int(['favorite_count', 'favourite_count']),
      commentCount: commentCount,
      isLiked: _bool(['is_liked', 'liked']),
      isDisliked: _bool(['is_disliked', 'disliked']),
      isFavorite: _bool(['is_favorite', 'is_favourite', 'favorite']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = List<ReelItem>.from(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return MainLayout(
      title: 'Reels',
      currentIndex: -1,
      constrainBody: false,
      useScreenPadding: false,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          top: true,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(390.0, constraints.maxWidth);
              final searchWidth = math.min(335.0, contentWidth - 24);

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        child: Container(
                          width: contentWidth,
                          height: 110,
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: Container(
                            width: searchWidth,
                            height: 47,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _loadReels(),
                              decoration: InputDecoration(
                                hintText: 'Search by user, video, hashtag',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search, size: 20),
                                  onPressed: () => _loadReels(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                                ? EmptyErrorView.serverError(onRetry: _loadReels)
                                : items.isEmpty
                                    ? RefreshIndicator(
                                        onRefresh: _loadReels,
                                        child: SingleChildScrollView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          child: SizedBox(
                                            height: constraints.maxHeight - 32,
                                            child: EmptyErrorView.empty(
                                              message: 'No reels yet',
                                              detail: 'Upload a video from Profile or tap + to add one. Pull down to refresh.',
                                              icon: Icons.video_library_outlined,
                                            ),
                                          ),
                                        ),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: _loadReels,
                                        child: SingleChildScrollView(
                                          controller: _scrollController,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            16,
                                            20,
                                            16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: Text(
                                                  'Recommended',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ),
                                              _StaggeredReels(items: items),
                                              if (_loadingMore)
                                                const Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StaggeredReels extends StatelessWidget {
  final List<ReelItem> items;

  const _StaggeredReels({required this.items});

  @override
  Widget build(BuildContext context) {
    final left = <_IndexedReel>[];
    final right = <_IndexedReel>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        left.add(_IndexedReel(index: i, item: items[i]));
      } else {
        right.add(_IndexedReel(index: i, item: items[i]));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (final entry in left) ...[
                _ReelCard(
                  item: entry.item,
                  onTap: () => Get.to(
                    () => ReelsWatchScreen(
                      items: items,
                      initialIndex: entry.index,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 42),
            child: Column(
              children: [
                for (final entry in right) ...[
                  _ReelCard(
                    item: entry.item,
                    onTap: () => Get.to(
                      () => ReelsWatchScreen(
                        items: items,
                        initialIndex: entry.index,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReelCard extends StatelessWidget {
  final ReelItem item;
  final VoidCallback onTap;

  const _ReelCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 165,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage(item.previewImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x12000000),
                Color(0x22000000),
                Color(0x88000000),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(item.profileImage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.ageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndexedReel {
  final int index;
  final ReelItem item;

  const _IndexedReel({required this.index, required this.item});
}
