import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/features/home/services/app_api_service.dart';

class ChallengePost {
  final String id;
  final String author;
  final String timeAgo;
  final String title;
  final String target;
  final String category;
  final String fitnessLevel;
  final String description;
  final bool isMine;
  final String? avatarUrl;
  final Uint8List? imageBytes;
  final String? backendId;
  int likes;
  bool isLiked;
  bool isDisliked;
  bool accepted;
  final List<String> replies;

  ChallengePost({
    required this.id,
    required this.author,
    required this.timeAgo,
    required this.title,
    required this.target,
    required this.category,
    required this.fitnessLevel,
    required this.description,
    required this.isMine,
    this.avatarUrl,
    this.imageBytes,
    this.backendId,
    required this.likes,
    this.isLiked = false,
    this.isDisliked = false,
    required this.accepted,
    required this.replies,
  });

  factory ChallengePost.fromMap(
    Map<String, dynamic> map, {
    bool isMine = false,
  }) {
    Map<String, dynamic> _pickNestedMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      return <String, dynamic>{};
    }

    // Many backends nest author info inside `user` or `author` objects.
    final userMap = _pickNestedMap(map['user']);
    final authorMap = _pickNestedMap(map['author']);

    // Prefer the plain `id` field from the backend challenge JSON,
    // then fall back to other possible keys.
    final remoteId = _firstStringValue(map, [
      'id',
      'challenge_id',
      'backend_id',
      '_id',
      'post_id',
    ]) ??
        _firstStringValue(userMap, ['challenge_id', 'id']) ??
        _firstStringValue(authorMap, ['challenge_id', 'id']);
    final localId = remoteId != null
        ? 'server_$remoteId'
        : 'server_${map.hashCode.toString()}';
    final author = _firstStringValue(map, [
          'author',
          'name',
          'created_by',
          'username',
          'user_name',
        ]) ??
        _firstStringValue(userMap, ['name', 'full_name', 'username', 'user_name']) ??
        _firstStringValue(authorMap, ['name', 'full_name', 'username', 'user_name']) ??
        'Unknown User';
    final timeAgo = _firstStringValue(map, [
          'time_ago',
          'timeAgo',
          'created_at',
          'timestamp',
          'time',
        ]) ??
        'Just now';
    final title = _firstStringValue(map, [
          'title',
          'name',
          'label',
        ]) ??
        'Untitled Challenge';
    final target = _firstStringValue(map, [
      'target',
      'goal',
      'benchmark',
    ]);
    final category = _firstStringValue(map, ['category']) ?? 'Medium';
    final fitnessLevel =
        _firstStringValue(map, ['fitness_level', 'level', 'difficulty']) ??
            'Beginner';
    final description = _firstStringValue(map, [
          'description',
          'details',
          'body',
        ]) ??
        '';
    final avatarUrl = _firstStringValue(map, [
          'avatar_url',
          'avatarUrl',
          'avatar',
          'author_avatar',
        ]) ??
        _firstStringValue(userMap, [
          'avatar_url',
          'avatar',
          'profile_image_url',
          'image_url',
        ]) ??
        _firstStringValue(authorMap, [
          'avatar_url',
          'avatar',
          'profile_image_url',
          'image_url',
        ]);
    final likes = _firstIntValue(map, [
          'likes',
          'likes_count',
          'like_count',
          'points',
        ]) ??
        0;
    final accepted = map['accepted'] == true ||
        map['status']?.toString().toLowerCase() == 'accepted';
    final replies = _extractReplies(map);

    return ChallengePost(
      id: localId,
      author: author,
      timeAgo: timeAgo,
      title: title,
      target: target ?? '',
      category: category,
      fitnessLevel: fitnessLevel,
      description: description,
      isMine: isMine,
      avatarUrl: avatarUrl,
      imageBytes: null,
      backendId: remoteId,
      likes: likes,
      accepted: accepted,
      replies: replies,
    );
  }

  static String? _firstStringValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _firstIntValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static List<String> _extractReplies(Map<String, dynamic> map) {
    final dynamic rawReplies =
        map['replies'] ?? map['comments'] ?? map['comments_data'];
    if (rawReplies is List) {
      return rawReplies
          .map((reply) => reply?.toString().trim() ?? '')
          .where((reply) => reply.isNotEmpty)
          .toList(growable: false);
    }
    if (rawReplies is String && rawReplies.isNotEmpty) {
      return [rawReplies];
    }
    return const <String>[];
  }
}

class ChallengesFeedController extends GetxController {
  int _counter = 3;

  final List<ChallengePost> _publicPosts = [
    ChallengePost(
      id: 'public_1',
      author: 'Maude Hall',
      timeAgo: '14 min',
      title: 'Push-Up Challenge',
      target: 'Do 100 push-ups in 1 minute',
      category: 'Medium',
      fitnessLevel: 'Beginner',
      description:
          'Do 100 push-ups with proper form in under one minute. Keep your core tight and elbows controlled.',
      isMine: false,
      avatarUrl: 'https://i.pravatar.cc/120?img=24',
      likes: 2,
      accepted: false,
      replies: [],
    ),
    ChallengePost(
      id: 'public_2',
      author: 'Chris Fox',
      timeAgo: '8 min',
      title: 'Plank Hold Challenge',
      target: 'Hold plank for 3 minutes',
      category: 'Medium',
      fitnessLevel: 'Intermediate',
      description:
          'Maintain a straight body line from head to heels and hold a forearm plank for three minutes.',
      isMine: false,
      avatarUrl: 'https://i.pravatar.cc/120?img=12',
      likes: 4,
      accepted: false,
      replies: [],
    ),
  ];

  final List<ChallengePost> _myPosts = [];

  final AppApiService _apiService = AppApiService();
  late final HomeProfileController _profileController;

  List<ChallengePost> get publicPosts => List.unmodifiable(_publicPosts);
  List<ChallengePost> get myPosts => List.unmodifiable(_myPosts);

  @override
  void onInit() {
    super.onInit();
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
    _loadPublicChallenges();
  }

  ChallengePost? findById(String id) {
    for (final post in [..._myPosts, ..._publicPosts]) {
      if (post.id == id) return post;
    }
    return null;
  }

  void addMyPost({
    required String title,
    required String target,
    required String category,
    required String fitnessLevel,
    required String description,
    Uint8List? imageBytes,
    String? backendId,
  }) {
    _counter += 1;
    _myPosts.insert(
      0,
      ChallengePost(
        id: 'my_$_counter',
        author: 'You',
        timeAgo: 'Just now',
        title: title,
        target: target,
        category: category,
        fitnessLevel: fitnessLevel,
        description: description,
        isMine: true,
        imageBytes: imageBytes,
        likes: 0,
        accepted: false,
        replies: [],
        backendId: backendId,
      ),
    );
    _publicPosts.insert(
      0,
      ChallengePost(
        id: 'public_user_$_counter',
        author: 'You',
        timeAgo: 'Just now',
        title: title,
        target: target,
        category: category,
        fitnessLevel: fitnessLevel,
        description: description,
        isMine: false,
        imageBytes: imageBytes,
        likes: 0,
        accepted: false,
        replies: [],
        backendId: backendId,
      ),
    );
    update();
  }

  void likePost(String id) {
    final post = findById(id);
    if (post == null) return;
    if (post.isLiked) {
      post.isLiked = false;
      if (post.likes > 0) post.likes -= 1;
    } else {
      post.isLiked = true;
      post.likes += 1;
      if (post.isDisliked) {
        post.isDisliked = false;
      }
    }
    update();
  }

  void dislikePost(String id) {
    final post = findById(id);
    if (post == null) return;
    if (post.isDisliked) {
      post.isDisliked = false;
    } else {
      post.isDisliked = true;
      if (post.isLiked) {
        post.isLiked = false;
        if (post.likes > 0) post.likes -= 1;
      }
    }
    update();
  }

  Future<void> acceptPost(String id) async {
    final post = findById(id);
    if (post == null || post.accepted) return;

    // Don't call backend for your own challenge; just show a hint.
    if (post.isMine) {
      Get.snackbar(
        'Challenge',
        'You cannot accept your own challenge. Try a public challenge from other users.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Backend requires integer challenge_id: use backendId directly if it's numeric.
    final rawChallengeId = (post.backendId ?? '').toString().trim();
    if (rawChallengeId.isEmpty || int.tryParse(rawChallengeId) == null) {
      Get.snackbar(
        'Challenge',
        'Accept failed: missing valid challenge id from server.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final result = await _apiService.acceptChallenge(
      challengeId: rawChallengeId,
    );
    if (result['ok'] == true) {
      post.accepted = true;
      Get.snackbar('Challenge', 'Accepted challenge on the server');
    } else {
      final message = result['data'] is Map<String, dynamic>
          ? (result['data'] as Map<String, dynamic>)['message']
          : null;
      final title = message?.toString().isNotEmpty == true
          ? message!.toString()
          : 'Accept failed';
      Get.snackbar(
        'Challenge',
        '$title (${result['statusCode']})',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    update();
  }

  void addReply(String id, String reply) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return;

    final post = findById(id);
    if (post == null) return;
    post.replies.add(trimmed);
    update();
  }

  Future<void> _loadPublicChallenges() async {
    final result = await _apiService.getChallengeCards();
    if (result['ok'] != true) return;
    final extracted = _extractChallengeList(result['data']);
    if (extracted.isEmpty) return;
    final posts = extracted.map((item) => ChallengePost.fromMap(item)).toList();
    if (posts.isEmpty) return;
    _publicPosts
      ..clear()
      ..addAll(posts);
    update();
  }

  List<Map<String, dynamic>> _extractChallengeList(dynamic raw) {
    if (raw is List) {
      return _coerceToMapList(raw);
    }
    if (raw is Map<String, dynamic>) {
      final nested = _firstListValue(raw, [
        'data',
        'items',
        'results',
        'challenges',
        'posts',
      ]);
      if (nested != null && nested.isNotEmpty) {
        return _coerceToMapList(nested);
      }
      for (final value in raw.values) {
        if (value is List && value.isNotEmpty) {
          return _coerceToMapList(value);
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _coerceToMapList(List<dynamic> list) {
    return list
        .where((item) => item is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<dynamic>? _firstListValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return null;
  }
}
