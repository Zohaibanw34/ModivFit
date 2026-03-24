import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';

class FollowListScreen extends StatefulWidget {
  final String type;

  const FollowListScreen({super.key, required this.type});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final AppApiService _apiService = AppApiService();
  bool _isLoading = true;
  String? _error;
  List<_FollowUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getContacts();
      if (result['ok'] == true) {
        final raw = result['data'];
        if (raw is List) {
          _users = raw
              .whereType<Map<String, dynamic>>()
              .map((item) => _FollowUser(
                    name: (item['name'] ?? item['display_name'] ?? 'User')
                        .toString(),
                    username: (item['username'] ?? item['handle'] ?? '').toString(),
                    avatarUrl: (item['avatar_url'] ?? item['profile_image_url'])
                        ?.toString(),
                  ))
              .toList(growable: false);
        } else {
          _users = [];
        }
      } else {
        _users = [];
        _error = 'Unable to fetch ';
      }
    } catch (_) {
      _error = 'Connection failed';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.type,
      showAppBar: true,
      showBackButton: true,
      currentIndex: -1,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_error!, textAlign: TextAlign.center),
                  )
                : _users.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No  yet. Start interacting with others to build your list.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              backgroundColor: const Color(0xFFEAEAEA),
                              child: user.avatarUrl == null
                                  ? const Icon(Icons.person_outlined)
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.username.isEmpty
                                ? 'No username'
                                : user.username),
                          );
                        },
                      ),
      ),
    );
  }
}

class _FollowUser {
  final String name;
  final String username;
  final String? avatarUrl;

  _FollowUser({
    required this.name,
    required this.username,
    this.avatarUrl,
  });
}
