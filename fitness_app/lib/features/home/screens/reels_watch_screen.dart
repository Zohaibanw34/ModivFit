import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:fitness_app/core/network/api_config.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/models/reel_item.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/routes/app_routes.dart';

class ReelsWatchScreen extends StatefulWidget {
  final List<ReelItem> items;
  final int initialIndex;

  const ReelsWatchScreen({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<ReelsWatchScreen> createState() => _ReelsWatchScreenState();
}

class _ReelsWatchScreenState extends State<ReelsWatchScreen> {
  final AppApiService _apiService = AppApiService();
  final Set<String> _pendingActions = <String>{};
  late final PageController _controller;
  late final List<ReelItem> _items;
  late int _index;
  late final HomeProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _items = List<ReelItem>.from(widget.items);
    _index = widget.initialIndex.clamp(0, _items.length - 1);
    _controller = PageController(initialPage: _index);
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _items[_index];

    return MainLayout(
      title: 'Watch',
      currentIndex: -1,
      constrainBody: false,
      useScreenPadding: false,
      highlightCenterAdd: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              itemCount: _items.length,
              onPageChanged: (value) {
                setState(() => _index = value);
                if (value >= 0 && value < _items.length) {
                  _apiService.incrementReelView(_items[value].id);
                }
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                final followKey = '${item.userId}_follow';
                return _WatchSlide(
                  item: item,
                  isActive: index == _index,
                  isFollowLoading: _pendingActions.contains(followKey),
                  onFollowTap: () => _toggleFollow(index),
                  onProfileTap: () => _openUserProfile(item),
                  onDoubleTapLike: () => _toggleLike(index),
                );
              },
            ),
          ),
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.profile),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: _profileController.avatarProvider,
                    backgroundColor: const Color(0xFFEAEAEA),
                    child: _profileController.avatarProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.black54,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: SizedBox(
                    width: 264,
                    height: 24,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _WatchTabs(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 92,
            child: SizedBox(
              width: 41,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionIcon(
                    icon: current.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: _formatCount(current.likeCount),
                    active: current.isLiked,
                    isLoading: _pendingActions.contains('${current.id}_like'),
                    onTap: () => _toggleLike(_index),
                  ),
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline,
                    label: _formatCount(current.commentCount),
                    onTap: () => _showCommentsSheet(current),
                  ),
                  _ActionIcon(
                    icon: Icons.send_outlined,
                    label: 'Share',
                    onTap: () => _showShareSheet(current),
                  ),
                  _ActionIcon(
                    icon: current.isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: _formatCount(current.favoriteCount),
                    active: current.isFavorite,
                    isLoading: _pendingActions.contains(
                      '${current.id}_favorite',
                    ),
                    onTap: () => _toggleFavorite(_index),
                  ),
                  _ActionIcon(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onTap: () => _showMoreMenu(current),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final key = '${item.id}_like';
    if (_pendingActions.contains(key)) return;

    final targetLiked = !item.isLiked;
    ReelItem next = item.copyWith(
      isLiked: targetLiked,
      likeCount: _safeCount(item.likeCount, targetLiked ? 1 : -1),
    );

    if (targetLiked && item.isDisliked) {
      next = next.copyWith(
        isDisliked: false,
        dislikeCount: _safeCount(item.dislikeCount, -1),
      );
    }

    _updateItem(index, next);
    _setPending(key, true);

    try {
      final result = await _apiService.toggleReelReaction(
        reelId: item.id,
        reactionType: 'like',
        isActive: targetLiked,
      );
      if (result['ok'] != true) {
        _updateItem(index, item);
        _showActionError('Unable to update like');
        return;
      }

      if (targetLiked && item.isDisliked) {
        await _apiService.toggleReelReaction(
          reelId: item.id,
          reactionType: 'dislike',
          isActive: false,
        );
      }

      final payload = _extractPayload(result['data']);
      final resolvedLikeCount = _pickInt(payload, <String>[
        'like_count',
        'likes_count',
        'likes',
        'total_likes',
      ]);
      final resolvedIsLiked = _pickBool(payload, <String>['is_liked', 'liked']);
      _updateItem(
        index,
        _items[index].copyWith(
          likeCount: resolvedLikeCount ?? _items[index].likeCount,
          isLiked: resolvedIsLiked ?? _items[index].isLiked,
        ),
      );
    } catch (_) {
      _updateItem(index, item);
      _showActionError('Unable to connect to server');
    } finally {
      _setPending(key, false);
    }
  }

  Future<void> _toggleDislike(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final key = '${item.id}_dislike';
    if (_pendingActions.contains(key)) return;

    final targetDisliked = !item.isDisliked;
    ReelItem next = item.copyWith(
      isDisliked: targetDisliked,
      dislikeCount: _safeCount(item.dislikeCount, targetDisliked ? 1 : -1),
    );

    if (targetDisliked && item.isLiked) {
      next = next.copyWith(
        isLiked: false,
        likeCount: _safeCount(item.likeCount, -1),
      );
    }

    _updateItem(index, next);
    _setPending(key, true);

    try {
      final result = await _apiService.toggleReelReaction(
        reelId: item.id,
        reactionType: 'dislike',
        isActive: targetDisliked,
      );
      if (result['ok'] != true) {
        _updateItem(index, item);
        _showActionError('Unable to update dislike');
        return;
      }

      if (targetDisliked && item.isLiked) {
        await _apiService.toggleReelReaction(
          reelId: item.id,
          reactionType: 'like',
          isActive: false,
        );
      }

      final payload = _extractPayload(result['data']);
      final resolvedDislikeCount = _pickInt(payload, <String>[
        'dislike_count',
        'dislikes_count',
        'dislikes',
        'total_dislikes',
      ]);
      final resolvedIsDisliked = _pickBool(payload, <String>[
        'is_disliked',
        'disliked',
      ]);
      _updateItem(
        index,
        _items[index].copyWith(
          dislikeCount: resolvedDislikeCount ?? _items[index].dislikeCount,
          isDisliked: resolvedIsDisliked ?? _items[index].isDisliked,
        ),
      );
    } catch (_) {
      _updateItem(index, item);
      _showActionError('Unable to connect to server');
    } finally {
      _setPending(key, false);
    }
  }

  Future<void> _toggleFavorite(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final key = '${item.id}_favorite';
    if (_pendingActions.contains(key)) return;

    final targetFavorite = !item.isFavorite;
    _updateItem(
      index,
      item.copyWith(
        isFavorite: targetFavorite,
        favoriteCount: _safeCount(item.favoriteCount, targetFavorite ? 1 : -1),
      ),
    );
    _setPending(key, true);

    try {
      final result = await _apiService.toggleReelReaction(
        reelId: item.id,
        reactionType: 'favorite',
        isActive: targetFavorite,
      );
      if (result['ok'] != true) {
        _updateItem(index, item);
        _showActionError('Unable to update favorite');
        return;
      }

      final payload = _extractPayload(result['data']);
      final resolvedFavoriteCount = _pickInt(payload, <String>[
        'favorite_count',
        'favourite_count',
        'favorites_count',
        'favourites_count',
        'favorites',
        'favourites',
        'bookmarks',
      ]);
      final resolvedIsFavorite = _pickBool(payload, <String>[
        'is_favorite',
        'is_favourite',
        'favorite',
        'favourite',
      ]);
      _updateItem(
        index,
        _items[index].copyWith(
          favoriteCount: resolvedFavoriteCount ?? _items[index].favoriteCount,
          isFavorite: resolvedIsFavorite ?? _items[index].isFavorite,
        ),
      );
    } catch (_) {
      _updateItem(index, item);
      _showActionError('Unable to connect to server');
    } finally {
      _setPending(key, false);
    }
  }

  Future<void> _toggleFollow(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final key = '${item.userId}_follow';
    if (_pendingActions.contains(key)) return;

    final shouldFollow = !item.isFollowing;
    _updateItem(
      index,
      item.copyWith(
        isFollowing: shouldFollow,
        creatorFollowerCount: _safeCount(
          item.creatorFollowerCount,
          shouldFollow ? 1 : -1,
        ),
        viewerFollowingCount: _safeCount(
          item.viewerFollowingCount,
          shouldFollow ? 1 : -1,
        ),
      ),
    );
    _setPending(key, true);

    try {
      final result = await _apiService.followUser(
        userId: item.userId,
        follow: shouldFollow,
      );
      if (result['ok'] != true) {
        _updateItem(index, item);
        _showActionError('Unable to update follow');
        return;
      }

      final payload = _extractPayload(result['data']);
      final resolvedFollowing = _pickBool(payload, <String>[
        'is_following',
        'following',
      ]);
      final creatorFollowerCount = _pickInt(payload, <String>[
        'creator_follower_count',
        'follower_count',
        'followers',
      ]);
      final viewerFollowingCount = _pickInt(payload, <String>[
        'viewer_following_count',
        'my_following_count',
        'following_count',
      ]);
      _updateItem(
        index,
        _items[index].copyWith(
          isFollowing: resolvedFollowing ?? _items[index].isFollowing,
          creatorFollowerCount:
              creatorFollowerCount ?? _items[index].creatorFollowerCount,
          viewerFollowingCount:
              viewerFollowingCount ?? _items[index].viewerFollowingCount,
        ),
      );
    } catch (_) {
      _updateItem(index, item);
      _showActionError('Unable to connect to server');
    } finally {
      _setPending(key, false);
    }
  }

  void _openUserProfile(ReelItem item) {
    Get.toNamed(
      AppRoutes.userProfileDetail,
      arguments: <String, dynamic>{
        'userId': item.userId,
        'userName': item.userName,
        'userHandle': item.userHandle,
        'avatarUrl': item.profileImage,
      },
    );
  }

  void _updateItem(int index, ReelItem item) {
    if (!mounted || index < 0 || index >= _items.length) return;
    setState(() => _items[index] = item);
  }

  void _setPending(String key, bool value) {
    if (!mounted) return;
    setState(() {
      if (value) {
        _pendingActions.add(key);
      } else {
        _pendingActions.remove(key);
      }
    });
  }

  int _safeCount(int current, int delta) {
    return (current + delta).clamp(0, 1 << 31);
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      final shortened = (value / 1000000).toStringAsFixed(
        value % 1000000 == 0 ? 0 : 1,
      );
      return '${shortened}M';
    }
    if (value >= 1000) {
      final shortened = (value / 1000).toStringAsFixed(
        value % 1000 == 0 ? 0 : 1,
      );
      return '${shortened}K';
    }
    return '$value';
  }

  Map<String, dynamic> _extractPayload(dynamic raw) {
    if (raw is! Map<String, dynamic>) return <String, dynamic>{};
    final nested = raw['data'];
    if (nested is Map<String, dynamic>) return nested;
    return raw;
  }

  int? _pickInt(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  bool? _pickBool(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return null;
  }

  void _showActionError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCommentsSheet(ReelItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => _ReelCommentsSheet(
          reelId: item.id,
          initialCommentCount: item.commentCount,
          scrollController: scrollController,
          apiService: _apiService,
          currentUserAvatar: _profileController.avatarProvider,
          onCommentCountUpdated: (int newCount) {
            final idx = _items.indexWhere((e) => e.id == item.id);
            if (idx >= 0) {
              _updateItem(idx, _items[idx].copyWith(commentCount: newCount));
            }
          },
        ),
      ),
    );
  }

  void _showShareSheet(ReelItem item) {
    final reelLink = '${ApiConfig.baseUrl}/reels/${item.id}';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share reel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Copy link'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: reelLink));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Share to...'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: reelLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied. Paste to share.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('Share to story'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Story share coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(ReelItem item) {
    final screen = MediaQuery.of(context).size;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        screen.width - 220,
        screen.height - 320,
        screen.width - 10,
        screen.height - 90,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'not_interested',
          child: ListTile(
            leading: Icon(Icons.visibility_off_outlined, size: 20),
            title: Text('Not interested', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy_link',
          child: ListTile(
            leading: Icon(Icons.link, size: 20),
            title: Text('Copy link', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'report',
          child: ListTile(
            leading: Icon(Icons.flag_outlined, size: 20),
            title: Text('Report', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'not_interested') {
        _toggleDislike(_index);
      } else if (value == 'copy_link') {
        final link = '${ApiConfig.baseUrl}/reels/${item.id}';
        Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (value == 'report') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. We’ll review this reel.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}

class _ReelCommentData {
  final String id;
  final String body;
  final String createdAt;
  final String? userName;
  final String? avatarUrl;

  _ReelCommentData({
    required this.id,
    required this.body,
    required this.createdAt,
    this.userName,
    this.avatarUrl,
  });
}

class _ReelCommentsSheet extends StatefulWidget {
  final String reelId;
  final int initialCommentCount;
  final ScrollController scrollController;
  final AppApiService apiService;
  final ImageProvider? currentUserAvatar;
  final void Function(int newCount) onCommentCountUpdated;

  const _ReelCommentsSheet({
    required this.reelId,
    required this.initialCommentCount,
    required this.scrollController,
    required this.apiService,
    required this.onCommentCountUpdated,
    this.currentUserAvatar,
  });

  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final TextEditingController _textController = TextEditingController();
  List<_ReelCommentData> _comments = [];
  int _commentCount = 0;
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final result = await widget.apiService.getReelComments(widget.reelId);
      final ok = result['ok'] == true || result['success'] == true;
      if (!ok || !mounted) return;
      final data = result['data'] ?? result;
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final count = (data['comment_count'] is int)
          ? data['comment_count'] as int
          : items.length;
      final list = items.map((m) {
        final user = m['user'] is Map ? m['user'] as Map<String, dynamic> : null;
        return _ReelCommentData(
          id: (m['id'] ?? '').toString(),
          body: (m['body'] ?? '').toString(),
          createdAt: (m['created_at'] ?? '').toString(),
          userName: user != null ? (user['name'] ?? user['user_name'])?.toString() : null,
          avatarUrl: user != null ? (user['avatar_url'] ?? user['media'])?.toString() : null,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _comments = list;
          _commentCount = count;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postComment() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _posting) return;
    setState(() => _posting = true);
    _textController.clear();
    try {
      final result = await widget.apiService.postReelComment(reelId: widget.reelId, body: body);
      final ok = result['ok'] == true || result['success'] == true;
      if (!ok || !mounted) {
        setState(() => _posting = false);
        return;
      }
      final data = result['data'] ?? result;
      final count = data['comment_count'] is int ? data['comment_count'] as int : _commentCount + 1;
      widget.onCommentCountUpdated(count);
      final newItem = data;
      if (newItem is Map<String, dynamic>) {
        final user = newItem['user'] is Map ? newItem['user'] as Map<String, dynamic> : null;
        final c = _ReelCommentData(
          id: (newItem['id'] ?? '').toString(),
          body: (newItem['body'] ?? body).toString(),
          createdAt: (newItem['created_at'] ?? '').toString(),
          userName: user != null ? (user['name'] ?? user['user_name'])?.toString() : null,
          avatarUrl: user != null ? (user['avatar_url'] ?? user['media'])?.toString() : null,
        );
        if (mounted) {
          setState(() {
            _comments = [c, ..._comments];
            _commentCount = count;
            _posting = false;
          });
        }
      } else {
        if (mounted) setState(() => _commentCount = count);
        _loadComments();
        setState(() => _posting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _posting = false);
    }
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet.\nBe the first to comment!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                                      ? NetworkImage(c.avatarUrl!)
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: c.avatarUrl == null || c.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.userName ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.body,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (c.createdAt.isNotEmpty)
                                        Text(
                                          c.createdAt,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.currentUserAvatar,
                    backgroundColor: Colors.grey[300],
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

class _WatchSlide extends StatefulWidget {
  final ReelItem item;
  final bool isActive;
  final VoidCallback onFollowTap;
  final bool isFollowLoading;
  final VoidCallback onProfileTap;
  final VoidCallback onDoubleTapLike;

  const _WatchSlide({
    required this.item,
    required this.isActive,
    required this.onFollowTap,
    required this.isFollowLoading,
    required this.onProfileTap,
    required this.onDoubleTapLike,
  });

  @override
  State<_WatchSlide> createState() => _WatchSlideState();
}

String _resolveVideoUrl(String raw) {
  if (raw.trim().isEmpty) return raw;
  try {
    final uri = Uri.parse(raw);
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      return uri.replace(host: ApiConfig.host).toString();
    }
    return raw;
  } catch (_) {
    return raw;
  }
}

class _WatchSlideState extends State<_WatchSlide>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartScale = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    _heartOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );
    if (widget.isActive) _initVideo();
  }

  @override
  void didUpdateWidget(covariant _WatchSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initVideo();
      } else {
        _disposeVideo();
      }
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    if (_videoController != null) return;
    final url = _resolveVideoUrl(widget.item.previewImage);
    if (url.trim().isEmpty) return;
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {
      _videoController?.dispose();
      _videoController = null;
      if (mounted) setState(() {});
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;
    if (mounted) setState(() {});
  }

  void _onDoubleTap() {
    widget.onDoubleTapLike();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final onFollowTap = widget.onFollowTap;
    final isFollowLoading = widget.isFollowLoading;
    final onProfileTap = widget.onProfileTap;

    Widget mediaContent;
    final controller = _videoController;
    if (controller != null && _videoInitialized && controller.value.isInitialized) {
      mediaContent = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      mediaContent = Image.network(
        item.previewImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: Colors.black87),
      );
    }

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          mediaContent,
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0x88000000)],
              ),
            ),
          ),
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _heartController,
                builder: (context, child) => Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: const Icon(
                      Icons.favorite,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
          left: 14,
          bottom: 72,
          child: SizedBox(
            width: 332,
            height: 78,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(item.profileImage),
                    ),

                    const SizedBox(width: 8),
                    Flexible(
                      child: GestureDetector(
                        onTap: onProfileTap,
                        child: Text(
                          item.normalizedHandle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: isFollowLoading ? null : onFollowTap,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(82, 30),
                        side: BorderSide(
                          color: item.isFollowing
                              ? const Color(0x80FFFFFF)
                              : Colors.white,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        item.isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.descriptionWithTags,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
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

class _WatchTabs extends StatelessWidget {
  const _WatchTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Explore',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'Following',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            'For You',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool isLoading;

  const _ActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? const Color(0xFFFF4D6D) : Colors.white;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
