import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/features/home/widgets/empty_error_view.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/routes/app_routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationViewModel {
  final String id;
  final bool isRead;
  final String createdAt;
  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final String? actionType;
  final String? actionId;

  const _NotificationViewModel({
    required this.id,
    required this.isRead,
    required this.createdAt,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.actionType,
    this.actionId,
  });
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppApiService _apiService = AppApiService();
  bool _isLoading = true;
  bool _isBusy = false;
  int _unreadCount = 0;
  String? _error;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getNotifications(),
        _apiService.getUnreadNotificationsCount(),
      ]);

      final listResult = results[0];
      final unreadResult = results[1];

      if (listResult['ok'] != true && listResult['success'] != true) {
        setState(() {
          _error = 'Notifications load failed';
          _isLoading = false;
        });
        return;
      }

      final notificationData = _extractData(listResult['data']);
      final unreadData = _extractData(unreadResult['data']);

      final rawList =
          notificationData['notifications'] ?? notificationData['items'];
      final list = rawList is List ? rawList : <dynamic>[];

      final countValue = unreadData['unread_count'] ?? unreadData['count'] ?? 0;
      final unreadCount = countValue is num
          ? countValue.toInt()
          : int.tryParse(countValue.toString()) ?? 0;

      setState(() {
        _items = list
            .whereType<Map>()
            .map((e) {
              return e.map((key, value) => MapEntry(key.toString(), value));
            })
            .toList(growable: false);
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to connect to server';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _isBusy = true);
    try {
      await _apiService.markAllNotificationsAsRead();
      await _loadNotifications();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _markOneRead(String id) async {
    setState(() => _isBusy = true);
    try {
      await _apiService.markNotificationAsRead(id);
      await _loadNotifications();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is! Map<String, dynamic>) return <String, dynamic>{};
    final nested = raw['data'];
    if (nested is Map<String, dynamic>) return nested;
    return raw;
  }

  _NotificationViewModel _buildNotificationViewModel(
    Map<String, dynamic> raw,
  ) {
    final id = (raw['id'] ?? raw['notification_id'] ?? '').toString();
    final createdAt = (raw['created_at'] ?? raw['createdAt'] ?? '').toString();
    final isRead = raw['read'] == true || raw['is_read'] == true;
    final type = (raw['type'] ?? raw['notification_type'] ?? '')
        .toString()
        .toLowerCase();
    final data = _extractData(raw);
    final sender = _extractSender(data, raw);
    final challengeName = _extractChallengeName(data, raw);
    final actionMeta = _buildActionMeta(type, data);
    final icon = _iconForType(type);

    final title = sender.isNotEmpty ? sender : (raw['title'] ?? 'Notification').toString();
    final subtitle = challengeName.isNotEmpty
        ? challengeName
        : actionMeta.isNotEmpty
            ? actionMeta
            : (data['message'] ?? raw['body'] ?? raw['description'] ?? raw['message'] ?? '').toString();
    final meta = actionMeta;
    final actionType = (raw['action_type'] ?? raw['actionType'] ?? data['action_type'] ?? '').toString();
    final actionId = (raw['action_id'] ?? raw['actionId'] ?? data['action_id'] ?? '').toString();

    return _NotificationViewModel(
      id: id,
      isRead: isRead,
      createdAt: createdAt,
      icon: icon,
      title: title,
      subtitle: subtitle,
      meta: meta,
      actionType: actionType.isEmpty ? null : actionType,
      actionId: actionId.isEmpty ? null : actionId,
    );
  }

  void _onNotificationTap(_NotificationViewModel view) {
    if (view.actionType != null && view.actionId != null && view.actionId!.isNotEmpty) {
      switch (view.actionType!) {
        case 'reel':
          Get.toNamed(AppRoutes.reelsHome, arguments: {'openWatchView': true, 'reelId': view.actionId});
          break;
        case 'challenge':
          Get.toNamed(AppRoutes.randomChallenge);
          break;
        case 'user':
          Get.toNamed(AppRoutes.userProfileDetail, arguments: {'userId': view.actionId});
          break;
      }
    }
  }

  String _extractSender(
    Map<String, dynamic> data,
    Map<String, dynamic> raw,
  ) {
    final candidates = <dynamic>[
      data['sender'],
      data['from'],
      data['user'],
      raw['sender'],
      raw['author'],
      raw['from'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _extractChallengeName(
    Map<String, dynamic> data,
    Map<String, dynamic> raw,
  ) {
    final candidates = <dynamic>[
      data['challenge_name'],
      data['challenge'] is Map<String, dynamic>
          ? (data['challenge'] as Map<String, dynamic>)['title']
          : null,
      data['challenge_title'],
      data['title'],
      raw['challenge_name'],
      raw['title'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _buildActionMeta(String type, Map<String, dynamic> data) {
    if (type.contains('invite') || data['action'] == 'invite') {
      return 'invited you';
    }
    if (type.contains('message') || data['action'] == 'message') {
      return 'sent you a message';
    }
    if (type.contains('challenge') || data['action'] == 'challenge_post') {
      return 'posted a challenge';
    }
    if (type.contains('follow') || data['action'] == 'follow') {
      return 'started following you';
    }
    if (type.contains('accept')) {
      return 'accepted your challenge';
    }
    if (type.contains('comment')) {
      return 'commented on your post';
    }
    return data['message']?.toString().trim() ?? '';
  }

  IconData _iconForType(String type) {
    if (type.contains('invite')) return Icons.person_add;
    if (type.contains('message')) return Icons.message_outlined;
    if (type.contains('challenge')) return Icons.fitness_center;
    if (type.contains('follow')) return Icons.person_add_alt_1;
    if (type.contains('accept')) return Icons.check_circle_outline;
    return Icons.notifications_none;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notification',
      showAppBar: true,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: 0,
      body: Container(
        width: double.infinity,
        color: const Color(0xFFF5F5F5),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? EmptyErrorView.serverError(onRetry: _loadNotifications)
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                  children: [
                    Row(
                      children: [
                        const Text(
                          'All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: const Color(0xFFE9EDF3),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6A7588),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _isBusy ? null : _markAllRead,
                          child: const Text('Mark all as read'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: EmptyErrorView.empty(
                          message: 'No notifications yet',
                          detail: 'When you get likes, comments or reminders they’ll show here.',
                        ),
                      ),
                    ..._items.map((item) {
                      final view = _buildNotificationViewModel(item);
                      return InkWell(
                        onTap: () => _onNotificationTap(view),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD9DEE5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  view.icon,
                                  size: 20,
                                  color: view.isRead
                                      ? const Color(0xFF9AA2B7)
                                      : Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        view.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: view.isRead
                                              ? const Color(0xFF8B92A1)
                                              : Colors.black,
                                        ),
                                      ),
                                      if (view.subtitle.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            view.subtitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4F5665),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (view.meta.isNotEmpty)
                                            Text(
                                              view.meta,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9AA2B7),
                                              ),
                                            ),
                                          if (view.meta.isNotEmpty &&
                                              view.createdAt.isNotEmpty)
                                            const SizedBox(width: 8),
                                          if (view.createdAt.isNotEmpty)
                                            Text(
                                              view.createdAt,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF8B92A1),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: (_isBusy || view.isRead || view.id.isEmpty)
                                    ? null
                                    : () => _markOneRead(view.id),
                                child: Text(view.isRead ? 'Read' : 'Mark as read'),
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
