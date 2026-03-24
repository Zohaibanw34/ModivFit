import 'dart:convert';
import 'dart:io';

import 'package:fitness_app/core/network/api_config.dart';
import 'package:fitness_app/features/auth/services/auth_service.dart';
import 'package:http/http.dart' as http;

class AppApiService {
  final AuthService _authService = AuthService();

  // ── Home ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHome() async {
    return _get(ApiConfig.homeUrl);
  }

  Future<Map<String, dynamic>> getRecommendedMeal() async {
    return _get(ApiConfig.recommendedMealUrl);
  }

  Future<Map<String, dynamic>> getRecommendedMeals() async {
    return _get(ApiConfig.recommendedMealsUrl);
  }

  // ── Profile ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    return _get(ApiConfig.profileUrl);
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    // Backend exposes a dedicated profile update endpoint:
    // POST /api/update_profile
    return _post(ApiConfig.updateProfileUrl, body: fields);
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final token = await _authService.getToken();
    final uri = Uri.parse(ApiConfig.profileImageUrl);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(token));
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _toResult(response);
  }

  // ── Media posts ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadMediaPost({
    required File mediaFile,
    required bool isVideo,
    required String caption,
    required String visibility,
    String? soundPath,
    String? soundName,
    double speed = 1.0,
  }) async {
    final token = await _authService.getToken();
    final endpoints = <String>[
      ApiConfig.postsMediaUrl,
      ApiConfig.profileMediaUrl,
      ApiConfig.api('posts/media'),
      ApiConfig.api('posts'),
      ApiConfig.root('media/posts'),
      ApiConfig.root('profile/media'),
      ApiConfig.root('posts/media'),
      ApiConfig.root('posts'),
    ];
    final tried = <Map<String, dynamic>>[];

    for (final url in endpoints) {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders(token));
      request.fields['caption'] = caption;
      request.fields['visibility'] = visibility.toLowerCase();
      request.fields['type'] = isVideo ? 'video' : 'image';
      request.fields['speed'] = speed.toStringAsFixed(2);
      if (soundName != null && soundName.trim().isNotEmpty) {
        request.fields['sound_name'] = soundName.trim();
      }
      if (soundPath != null && soundPath.trim().isNotEmpty) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath('sound', soundPath),
          );
        } catch (_) {}
      }
      for (final field in <String>[
        isVideo ? 'video' : 'image',
        'media',
        'file',
        'upload',
      ]) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(field, mediaFile.path),
          );
        } catch (_) {}
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final result = _toResult(response);
      if (result['ok'] == true) {
        result['endpoint'] = url;
        return result;
      }
      tried.add({
        'endpoint': url,
        'statusCode': result['statusCode'] as int? ?? 0,
      });
    }

    // Image-only fallback: profile image endpoint
    if (!isVideo) {
      final uri = Uri.parse(ApiConfig.profileImageUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders(token));
      request.fields['caption'] = caption;
      request.fields['visibility'] = visibility.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath('image', mediaFile.path),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final result = _toResult(response);
      if (result['ok'] == true) {
        result['endpoint'] = ApiConfig.profileImageUrl;
        return result;
      }
      tried.add({
        'endpoint': ApiConfig.profileImageUrl,
        'statusCode': result['statusCode'] as int? ?? 0,
      });
    }

    return <String, dynamic>{
      'ok': false,
      'statusCode': 404,
      'data': {
        'message': isVideo
            ? 'Video upload endpoint not found on backend'
            : 'Image upload endpoint not found on backend',
        'tried': tried,
      },
    };
  }

  Future<Map<String, dynamic>> getProfileMedia() async {
    final result = await _get(ApiConfig.profileMediaUrl);
    if (result['ok'] == true) return result;
    return _get(ApiConfig.postsMediaUrl);
  }

  // ── Challenges ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getChallengeCategories() async {
    return _get(ApiConfig.challengeCategoriesUrl);
  }

  Future<Map<String, dynamic>> createChallenge(
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.createChallengeUrl, body: fields);
  }

  Future<Map<String, dynamic>> acceptChallenge({
    required String challengeId,
  }) async {
    final body = <String, dynamic>{
      'challenge_id': challengeId,
    };
    return _post(ApiConfig.acceptChallengeUrl, body: body);
  }

  Future<Map<String, dynamic>> getCurrentChallenge() async {
    return _get(ApiConfig.currentChallengeUrl);
  }

  Future<Map<String, dynamic>> getCurrentChallengeById(String id) async {
    return _get(ApiConfig.currentChallengeByIdUrl(id));
  }

  Future<Map<String, dynamic>> startRandomChallenge({
    Map<String, dynamic>? fields,
  }) async {
    return _post(ApiConfig.startRandomChallengeUrl, body: fields ?? {});
  }

  Future<Map<String, dynamic>> updateChallengeProgress(
    String id,
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.challengeRecordUrl(id), body: fields);
  }

  Future<Map<String, dynamic>> deleteChallenge(String id) async {
    return _delete(ApiConfig.currentChallengeByIdUrl(id));
  }

  Future<Map<String, dynamic>> getChallengeLimits() async {
    return _get(ApiConfig.challengeLimitsUrl);
  }

  Future<Map<String, dynamic>> extendChallengeLimits(
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.challengeLimitsExtendUrl, body: fields);
  }

  Future<Map<String, dynamic>> getChallengeCards() async {
    return _get(ApiConfig.challengeCardsUrl);
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLeaderboard() async {
    return _get(ApiConfig.leaderboardUrl);
  }

  // ── Food Logs ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPublicFoodLogs() async {
    return _get(ApiConfig.allFoodLogsUrl);
  }

  Future<Map<String, dynamic>> getMyFoodLogs() async {
    return _get(ApiConfig.myFoodLogsUrl);
  }

  Future<Map<String, dynamic>> createFoodLog({
    required String message,
    String? title,
    String? type,
    int? calories,
    int? protein,
    int? carbs,
    int? fats,
  }) async {
    final body = <String, dynamic>{
      'description': message,
      'message': message,
      'type': type ?? 'text',
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
    };
    return _post(ApiConfig.createFoodLogUrl, body: body);
  }

  Future<Map<String, dynamic>> toggleFoodLogLike({
    required String foodLogId,
  }) async {
    return _post(
      ApiConfig.likeFoodLogUrl,
      body: <String, dynamic>{
        'food_log_id': foodLogId,
      },
    );
  }

  Future<Map<String, dynamic>> addFoodLogComment({
    required String foodLogId,
    required String message,
  }) async {
    return _post(
      ApiConfig.commentFoodLogUrl,
      body: <String, dynamic>{
        'food_log_id': foodLogId,
        'description': message,
        'body': message,
      },
    );
  }

  // ── Guides ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getGuides({
    String tab = 'for_you',
    String? topic,
  }) async {
    return _getWithQuery(ApiConfig.guidesUrl, <String, String>{
      'tab': tab,
      if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
    });
  }

  Future<Map<String, dynamic>> getGuidePosts({
    String? topic,
    String tab = 'public',
    int perPage = 10,
  }) async {
    return _getWithQuery(ApiConfig.guidesPostsUrl, <String, String>{
      if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
      'tab': tab,
      'per_page': '$perPage',
    });
  }

  Future<Map<String, dynamic>> createGuidePost(
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.guidesPostsUrl, body: fields);
  }

  Future<Map<String, dynamic>> likeGuidePost(String id) async {
    return _post(ApiConfig.guidePostLikeUrl(id), body: {});
  }

  Future<Map<String, dynamic>> replyGuidePost(
    String id,
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.guidePostReplyUrl(id), body: fields);
  }

  // ── Chat ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getChatRooms() async {
    return _get(ApiConfig.chatRoomsUrl);
  }

  Future<Map<String, dynamic>> inviteToChatRoom(
    String roomId,
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.chatRoomInviteUrl(roomId), body: fields);
  }

  Future<Map<String, dynamic>> getChatRoomMessages(String roomId) async {
    return _get(ApiConfig.chatRoomMessagesUrl(roomId));
  }

  Future<Map<String, dynamic>> createChatRoomMessage(
    String roomId,
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.chatRoomMessagesUrl(roomId), body: fields);
  }

  // ── Friends ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> searchFriends(String query) async {
    return _getWithQuery(ApiConfig.friendsSearchUrl, <String, String>{
      'q': query,
    });
  }

  Future<Map<String, dynamic>> getContacts() async {
    return _get(ApiConfig.contactsUrl);
  }

  // ── Notifications ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications() async {
    return _get(ApiConfig.notificationsUrl);
  }

  Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    final result = await _get(ApiConfig.notificationsUnreadCountUrl);
    if (result['ok'] == true) return result;
    return _getWithQuery(ApiConfig.notificationsUrl, <String, String>{
      'unread': '1',
    });
  }

  Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.notificationsUrl, body: fields);
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    return _post(
      ApiConfig.notificationActionUrl(id),
      body: <String, dynamic>{'action': 'read'},
    );
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return _post(ApiConfig.notificationsMarkAllReadUrl, body: {});
  }

  // ── Settings ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSettings() async {
    return _get(ApiConfig.settingsUrl);
  }

  Future<Map<String, dynamic>> updateLanguageSettings(
    Map<String, dynamic> fields,
  ) async {
    return _put(ApiConfig.settingsLanguageUrl, body: fields);
  }

  Future<Map<String, dynamic>> updateThemeSettings(
    Map<String, dynamic> fields,
  ) async {
    return _put(ApiConfig.settingsThemeUrl, body: fields);
  }

  // ── Steps ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStepsSummary({String range = 'week'}) async {
    return _getWithQuery(ApiConfig.stepsSummaryUrl, <String, String>{
      'range': range,
    });
  }

  // ── Subscriptions ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    return _get(ApiConfig.appSubscriptionPlansUrl);
  }

  Future<Map<String, dynamic>> checkoutSubscription(
    Map<String, dynamic> fields,
  ) async {
    return _post(ApiConfig.appSubscriptionCheckoutUrl, body: fields);
  }

  // ── Reels ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReels({String? search, int page = 1}) async {
    String url = search != null && search.trim().isNotEmpty
        ? ApiConfig.reelsSearchUrl(search.trim())
        : ApiConfig.reelsUrl;
    if (page > 1) {
      url = url.contains('?') ? '$url&page=$page' : '$url?page=$page';
    }
    return _get(url);
  }

  Future<Map<String, dynamic>> getReelComments(String reelId) async {
    return _get(ApiConfig.reelCommentsUrl(reelId));
  }

  Future<Map<String, dynamic>> postReelComment({
    required String reelId,
    required String body,
  }) async {
    return _post(
      ApiConfig.reelCommentsUrl(reelId),
      body: <String, dynamic>{'body': body},
    );
  }

  Future<Map<String, dynamic>> incrementReelView(String reelId) async {
    return _post(ApiConfig.reelViewUrl(reelId), body: <String, dynamic>{});
  }

  Future<Map<String, dynamic>> getPublicUserProfile(String userId) async {
    return _get(ApiConfig.userProfilePublicUrl(userId));
  }

  Future<Map<String, dynamic>> uploadReel({
    required File mediaFile,
    String? caption,
    List<String>? hashtags,
    String visibility = 'public',
  }) async {
    final token = await _authService.getToken();
    final uri = Uri.parse(ApiConfig.reelsUrl);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(token));
    request.files.add(
      await http.MultipartFile.fromPath('media', mediaFile.path),
    );
    if (caption != null && caption.trim().isNotEmpty) {
      request.fields['caption'] = caption.trim();
    }
    request.fields['visibility'] = visibility;
    if (hashtags != null && hashtags.isNotEmpty) {
      for (var i = 0; i < hashtags.length; i++) {
        final value = hashtags[i].trim();
        if (value.isEmpty) continue;
        request.fields['hashtags[$i]'] = value;
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _toResult(response);
  }

  Future<Map<String, dynamic>> toggleReelReaction({
    required String reelId,
    required String reactionType,
    required bool isActive,
  }) async {
    final cleaned = reactionType.trim().toLowerCase();
    return _postToFirstAvailable(
      endpoints: <String>[
        ApiConfig.reelReactionByTypeUrl(reelId, cleaned),
        ApiConfig.reelReactionsUrl(reelId),
        ApiConfig.reelsReactionsUrl,
        ApiConfig.root('reels/$reelId/reactions'),
        ApiConfig.root('reels/reactions'),
      ],
      body: <String, dynamic>{
        'reel_id': reelId,
        'reaction': cleaned,
        'type': cleaned,
        'is_active': isActive,
        'active': isActive,
        'value': isActive ? 1 : 0,
      },
    );
  }

  // ── Users / Follow ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> followUser({
    required String userId,
    required bool follow,
  }) async {
    return _postToFirstAvailable(
      endpoints: <String>[
        ApiConfig.followUserUrl(userId),
        ApiConfig.usersFollowUrl,
        ApiConfig.root('users/$userId/follow'),
        ApiConfig.root('users/follow'),
      ],
      body: <String, dynamic>{
        'user_id': userId,
        'follow': follow,
        'is_following': follow,
        'action': follow ? 'follow' : 'unfollow',
      },
    );
  }

  // ── Private HTTP helpers ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String url) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse(url),
      headers: _jsonHeaders(token),
    );
    return _toResult(response);
  }

  Future<Map<String, dynamic>> _post(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse(url),
      headers: _jsonHeaders(token),
      body: jsonEncode(body),
    );
    return _toResult(response);
  }

  Future<Map<String, dynamic>> _put(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse(url),
      headers: _jsonHeaders(token),
      body: jsonEncode(body),
    );
    return _toResult(response);
  }

  Future<Map<String, dynamic>> _delete(String url) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse(url),
      headers: _jsonHeaders(token),
    );
    return _toResult(response);
  }

  Future<Map<String, dynamic>> _getWithQuery(
    String url,
    Map<String, String> query,
  ) async {
    final token = await _authService.getToken();
    final uri = Uri.parse(url).replace(queryParameters: query);
    final response = await http.get(uri, headers: _jsonHeaders(token));
    return _toResult(response);
  }

  Future<Map<String, dynamic>> _postToFirstAvailable({
    required List<String> endpoints,
    required Map<String, dynamic> body,
  }) async {
    final tried = <Map<String, dynamic>>[];

    for (final url in endpoints) {
      final result = await _post(url, body: body);
      if (result['ok'] == true) {
        result['endpoint'] = url;
        return result;
      }
      final statusCode = result['statusCode'] as int? ?? 0;
      tried.add({'endpoint': url, 'statusCode': statusCode});
      if (statusCode >= 500 || statusCode == 401 || statusCode == 403) {
        return <String, dynamic>{...result, 'tried': tried};
      }
    }

    return <String, dynamic>{
      'ok': false,
      'statusCode': tried.isNotEmpty ? tried.last['statusCode'] : 404,
      'data': <String, dynamic>{
        'message': 'No matching endpoint accepted the request',
        'tried': tried,
      },
    };
  }

  Map<String, String> _jsonHeaders(String? token) => <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ..._authHeaders(token),
  };

  Map<String, String> _authHeaders(String? token) {
    if (token == null || token.trim().isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _toResult(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'raw': response.body};
    return <String, dynamic>{
      'ok': response.statusCode >= 200 && response.statusCode < 300,
      'statusCode': response.statusCode,
      'data': data,
    };
  }
}
