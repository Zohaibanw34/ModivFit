import 'package:flutter/material.dart';

import 'package:fitness_app/core/utils/app_responsive.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';

enum _GenderFilter { all, men, women }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _GenderFilter _filter = _GenderFilter.all;
  final AppApiService _apiService = AppApiService();
  final List<_LeaderboardUser> _allUsers = <_LeaderboardUser>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getLeaderboard();
      if (result['ok'] != true) {
        setState(() {
          _error = 'Unable to load leaderboard';
          _isLoading = false;
        });
        return;
      }
      final data = result['data'];
      final users = _extractList(data)
          .map((e) => _LeaderboardUser.fromMap(e))
          .toList(growable: false);
      setState(() {
        _allUsers
          ..clear()
          ..addAll(users);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to connect to server';
        _isLoading = false;
      });
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
      final nested = raw['data'];
      if (nested is List) {
        return nested
            .where((e) => e is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final sorted = [...filtered]..sort((a, b) => b.points.compareTo(a.points));
    final podiumMaxWidth = AppResponsive.isDesktop(context)
        ? 520.0
        : (AppResponsive.isTablet(context) ? 420.0 : 350.0);

    final top1 = sorted.isNotEmpty ? sorted[0] : null;
    final top2 = sorted.length > 1 ? sorted[1] : null;
    final top3 = sorted.length > 2 ? sorted[2] : null;
    final rest = sorted.length > 3 ? sorted.sublist(3) : <_LeaderboardUser>[];

    return MainLayout(
      title: 'Leaderboard',
      showAppBar: true,
      showAvatar: true,
      currentIndex: 3,
      body: Container(
        width: double.infinity,
        color: const Color(0xFFF5F5F5),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 18,
                          left: 0,
                          right: 0,
                          bottom: 16,
                        ),
                        child: Column(
                          children: [
                            _FilterTabs(
                              selected: _filter,
                              onChanged: (value) =>
                                  setState(() => _filter = value),
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: podiumMaxWidth),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (top2 != null)
                                    _TopUserCard(
                                      user: top2,
                                      rank: 2,
                                      avatarSize: 74,
                                      pointsColor: const Color(0xFF18B4B1),
                                    )
                                  else
                                    const SizedBox(width: 106),
                                  const SizedBox(width: 6),
                                  if (top1 != null)
                                    _TopUserCard(
                                      user: top1,
                                      rank: 1,
                                      avatarSize: 84,
                                      pointsColor: const Color(0xFF18B4B1),
                                    )
                                  else
                                    const SizedBox(width: 114),
                                  const SizedBox(width: 6),
                                  if (top3 != null)
                                    _TopUserCard(
                                      user: top3,
                                      rank: 3,
                                      avatarSize: 74,
                                      pointsColor: const Color(0xFF18B4B1),
                                    )
                                  else
                                    const SizedBox(width: 106),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 260),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F2EA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.separated(
                                itemCount: rest.length,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final user = rest[index];
                                  final rank = index + 4;
                                  return _RankRow(user: user, rank: rank);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  List<_LeaderboardUser> get _filteredUsers {
    switch (_filter) {
      case _GenderFilter.all:
        return _allUsers;
      case _GenderFilter.men:
        return _allUsers.where((u) => u.gender == _GenderFilter.men).toList();
      case _GenderFilter.women:
        return _allUsers.where((u) => u.gender == _GenderFilter.women).toList();
    }
  }
}

class _FilterTabs extends StatelessWidget {
  final _GenderFilter selected;
  final ValueChanged<_GenderFilter> onChanged;

  const _FilterTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppResponsive.isDesktop(context)
        ? 420.0
        : (AppResponsive.isTablet(context) ? 380.0 : 345.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          _FilterTabItem(
            label: 'All',
            selected: selected == _GenderFilter.all,
            onTap: () => onChanged(_GenderFilter.all),
          ),
          _FilterTabItem(
            label: 'Men',
            selected: selected == _GenderFilter.men,
            onTap: () => onChanged(_GenderFilter.men),
          ),
          _FilterTabItem(
            label: 'Women',
            selected: selected == _GenderFilter.women,
            onTap: () => onChanged(_GenderFilter.women),
          ),
        ],
      ),
    );
  }
}

class _FilterTabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTabItem({
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopUserCard extends StatelessWidget {
  final _LeaderboardUser user;
  final int rank;
  final double avatarSize;
  final Color pointsColor;

  const _TopUserCard({
    required this.user,
    required this.rank,
    required this.avatarSize,
    required this.pointsColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFEAEAEA),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${user.name} ${user.badge}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            '? ${user.points} pts',
            style: TextStyle(fontSize: 12, color: pointsColor),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final _LeaderboardUser user;
  final int rank;

  const _RankRow({required this.user, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = user.isCurrentUser;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isCurrentUser ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 10,
            backgroundImage: NetworkImage(user.avatarUrl),
            backgroundColor: const Color(0xFFEAEAEA),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${user.name} ${user.badge}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
          Text(
            '${user.points} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isCurrentUser ? Colors.white : const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardUser {
  final String name;
  final int points;
  final String avatarUrl;
  final _GenderFilter gender;
  final String badge;
  final bool isCurrentUser;

  const _LeaderboardUser({
    required this.name,
    required this.points,
    required this.avatarUrl,
    required this.gender,
    required this.badge,
    this.isCurrentUser = false,
  });

  factory _LeaderboardUser.fromMap(Map<String, dynamic> map) {
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
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    _GenderFilter _genderFrom(dynamic value) {
      final text = value?.toString().toLowerCase() ?? '';
      if (text.startsWith('m')) return _GenderFilter.men;
      if (text.startsWith('w') || text.startsWith('f')) {
        return _GenderFilter.women;
      }
      return _GenderFilter.all;
    }

    final name = _string(['name', 'username', 'user_name']);
    final points = _int(['points', 'score', 'total_points']);
    final avatar = _string(
      ['avatar_url', 'avatar', 'image_url', 'profile_image_url'],
    );
    final genderValue = map['gender'] ?? map['sex'];
    final badge = _string(['badge', 'title', 'level']);
    final isCurrent =
        map['is_current_user'] == true || map['me'] == true;

    return _LeaderboardUser(
      name: name.isNotEmpty ? name : 'User',
      points: points,
      avatarUrl: avatar.isNotEmpty
          ? avatar
          : 'https://i.pravatar.cc/120?img=12',
      gender: _genderFrom(genderValue),
      badge: badge,
      isCurrentUser: isCurrent,
    );
  }
}
