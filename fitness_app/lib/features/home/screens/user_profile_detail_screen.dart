import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/models/reel_item.dart';
import 'package:fitness_app/features/home/screens/reels_watch_screen.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';

class UserProfileDetailScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userHandle;
  final String? avatarUrl;

  const UserProfileDetailScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userHandle,
    this.avatarUrl,
  });

  @override
  State<UserProfileDetailScreen> createState() =>
      _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  final AppApiService _apiService = AppApiService();
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _reels = [];
  bool _isFollowing = false;
  bool _loading = true;
  String? _error;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getPublicUserProfile(widget.userId);
      final ok = result['ok'] == true || result['success'] == true;
      if (!ok) {
        setState(() {
          _error = 'Unable to load profile';
          _loading = false;
        });
        return;
      }
      final data = result['data'] ?? result;
      final user = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : null;
      final reels = (data['reels'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final isFollowing = data['is_following'] == true;
      if (mounted) {
        setState(() {
          _user = user;
          _reels = reels;
          _isFollowing = isFollowing;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to connect';
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    try {
      final result = await _apiService.followUser(
        userId: widget.userId,
        follow: !_isFollowing,
      );
      final ok = result['ok'] == true || result['success'] == true;
      if (ok && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followLoading = false;
        });
      } else {
        setState(() => _followLoading = false);
      }
    } catch (_) {
      setState(() => _followLoading = false);
    }
  }

  List<ReelItem> _reelsToItems() {
    final name = _user?['name']?.toString() ?? widget.userName ?? 'User';
    final handle = _user?['user_name']?.toString() ?? widget.userHandle ?? '';
    final avatar = _user?['avatar_url'] ?? _user?['media'] ?? widget.avatarUrl ?? '';
    return _reels.map((r) {
      return ReelItem(
        id: (r['id'] ?? '').toString(),
        userId: widget.userId,
        userName: name,
        userHandle: handle,
        profileImage: avatar.isNotEmpty ? avatar.toString() : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        previewImage: (r['media_url'] ?? '').toString(),
        ageText: '',
        createdAt: DateTime.now(),
        description: (r['caption'] ?? '').toString(),
        likeCount: (r['like_count'] is int) ? r['like_count'] as int : 0,
        commentCount: (r['comment_count'] is int) ? r['comment_count'] as int : 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MainLayout(
        title: widget.userName ?? 'Profile',
        showBackButton: true,
        showBottomNav: false,
        currentIndex: -1,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return MainLayout(
        title: widget.userName ?? 'Profile',
        showBackButton: true,
        showBottomNav: false,
        currentIndex: -1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final name = _user?['name']?.toString() ?? widget.userName ?? 'User';
    final handle = _user?['user_name']?.toString() ?? widget.userHandle ?? '';
    final bio = _user?['bio']?.toString() ?? '';
    final avatar = _user?['avatar_url'] ?? _user?['media'] ?? widget.avatarUrl;

    return MainLayout(
      title: name,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: -1,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: avatar != null && avatar.toString().isNotEmpty
                  ? NetworkImage(avatar.toString())
                  : null,
              backgroundColor: Colors.grey[300],
              child: avatar == null || avatar.toString().isEmpty
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              handle.isNotEmpty ? (handle.startsWith('@') ? handle : '@$handle') : '@${name.replaceAll(' ', '_').toLowerCase()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: OutlinedButton(
                onPressed: _followLoading ? null : _toggleFollow,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isFollowing ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                ),
                child: _followLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _reels.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No reels yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _reels.length,
                    itemBuilder: (_, i) {
                      final reel = _reels[i];
                      final mediaUrl = (reel['media_url'] ?? '').toString();
                      final items = _reelsToItems();
                      return InkWell(
                        onTap: () {
                          if (items.isNotEmpty) {
                            Get.to(
                              () => ReelsWatchScreen(
                                items: items,
                                initialIndex: i.clamp(0, items.length - 1),
                              ),
                            );
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.videocam_off),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
