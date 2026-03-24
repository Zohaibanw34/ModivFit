class ApiConfig {
  static const String _hostOverride = String.fromEnvironment('API_HOST');
  /// PC LAN IP (from ipconfig Wi‑Fi). Override with --dart-define=API_HOST=<ip> if it changes.
  static const String _defaultLanHost = '192.168.2.101';
  static const String _port = '8000';

  static String get _host {
    if (_hostOverride.trim().isNotEmpty) return _hostOverride.trim();
    return _defaultLanHost;
  }

  /// Current API host (for rewriting localhost/127.0.0.1 URLs so images/videos load on device).
  static String get host => _host;

  static String get baseUrl => 'http://$_host:$_port';
  static String get authBaseUrl => 'http://$_host:$_port/api/auth';

  /// ModivFit API metadata (mirrors the README reference provided by the backend).
  /// Base URL: http://<host>:8000/api
  /// Auth: Bearer token (Laravel Sanctum) via `Authorization: Bearer <token>`.
  /// Content types: `application/json` for JSON, `multipart/form-data` for uploads.
  static const String apiReferenceSummary = '''
Base: http://<host>:8000/api
Auth: Bearer token (Laravel Sanctum)
Content-Type: application/json (JSON payloads) / multipart/form-data (uploads)
Response shape: { "success": bool, "message": String, "token"?: String, "user"?: Map, "data"?: Map }
User object fields include: id, name, email, user_name/username, bio, fitness_level, points, media, avatar_url, phone, country, gender, date_of_birth
''';
  static const List<String> userObjectFields = [
    'id',
    'name',
    'email',
    'user_name',
    'username',
    'bio',
    'fitness_level',
    'points',
    'media',
    'avatar_url',
    'phone',
    'country',
    'gender',
    'date_of_birth',
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────
  static String api(String path) => _join([baseUrl, 'api', path]);
  static String root(String path) => _join([baseUrl, path]);
  static String auth(String path) => _join([authBaseUrl, path]);

  // -- Public (no auth) endpoints --
  static String get loginUrl => api('login');
  static String get registerUrl => api('register');
  static String get logoutUrl => api('logout');
  static String get sendOtpUrl => api('send_otp');
  static String get validateOtpUrl => api('validate_otp');
  static String get tokenLoginUrl => api('token_login');
  static String get testUrl => api('test');
  static String get test2Url => api('test2');
  static String get testChatUrl => api('test_chat');
  static String get testModalUrl => api('test_modal');

  // -- Auth (/api/auth/) endpoints --

  static String get authRootUrl => '$authBaseUrl/';
  static String forgotPassword() => auth('forgot-password');
  static String get authSignupUrl => auth('signup');
  static String get authSigninUrl => auth('signin');
  static String get authLoginUrl => auth('login');
  static String get authVerifySignupOtpUrl => auth('verify-signup-otp');
  static String get authForgotPasswordUrl => auth('forgot-password');
  static String get authVerifyForgotOtpUrl => auth('verify-forgot-otp');
  static String get authVerifyChangePasswordOtpUrl =>
      auth('verify-change-password-otp');
  static String get authResetPasswordUrl => auth('reset-password');
  static String get authSendChangePasswordOtpUrl =>
      auth('send-change-password-otp');
  static String get authChangePasswordUrl => auth('change-password');
  static String get authConfirmPasswordUrl => auth('confirm-password');

  // ── Onboarding ───────────────────────────────────────────────────────────
  static String onboarding(String path) =>
      _join([baseUrl, 'api', 'onboarding', path]);
  static String get onboardingSaveUrl => onboarding('save');
  static String get onboardingGetUrl => onboarding('get');

  // ── Home  ─────────────────────────────────────────────────────────────────
  static String get homeUrl => api('home');
  static String get healthUrl => api('health');
  static String get recommendedMealUrl => api('recommended_meal');
  static String get recommendedMealsUrl => api('recommended_meals');

  // ── Profile ──────────────────────────────────────────────────────────────
  static String get profileUrl => api('profile');
  static String get profileImageUrl => api('profile/image');
  static String get profileMediaUrl => api('profile/media'); // IGNORE --

  // ── Challenges ───────────────────────────────────────────────────────────
  static String get challengesUrl => api('challenges');
  static String get challengeCategoriesUrl => api('challenges/categories');
  static String get currentChallengeUrl => api('challenges/current');
  static String get startRandomChallengeUrl => api('challenges/start-random');
  static String get challengeLimitsUrl => api('challenges/limits');
  static String get challengeLimitsExtendUrl => api('challenges/limits/extend');
  static String get challengeCardsUrl => api('challenges/cards');
  static String currentChallengeByIdUrl(String id) => api('challenges/$id');
  static String challengeByIdUrl(String id) => api('challenges/$id');
  static String challengeProgressUrl(String id) =>
      api('challenges/$id/progress');
  static String challengeRecordUrl(String id) => api('challenges/$id/record');

  // ── Media / Posts ────────────────────────────────────────────────────────
  static String get postsMediaUrl => api('posts/media');

  // ── Reels  ────────────────────────────────────────────────────────────────
  static String get reelsUrl => api('reels');
  static String reelsSearchUrl(String query) =>
      '${api('reels')}?search=${Uri.encodeQueryComponent(query)}';
  static String get reelsReactionsUrl => api('reels/reactions');
  static String reelReactionsUrl(String reelId) =>
      api('reels/$reelId/reactions');
  static String reelReactionByTypeUrl(String reelId, String type) =>
      api('reels/$reelId/reactions/$type');
  static String reelCommentsUrl(String reelId) => api('reels/$reelId/comments');
  static String reelViewUrl(String reelId) => api('reels/$reelId/view');
  static String userProfilePublicUrl(String userId) => api('users/$userId');

  // ── Guides ───────────────────────────────────────────────────────────────
  static String get guidesUrl => api('guides');
  static String get guidesPostsUrl => api('guides/posts');
  static String guidePostLikeUrl(String id) => api('guides/posts/$id/like');
  static String guidePostReplyUrl(String id) => api('guides/posts/$id/reply');

  // ── Chat ─────────────────────────────────────────────────────────────────
  static String get chatRoomsUrl => api('chat/rooms');
  static String chatRoomInviteUrl(String roomId) =>
      api('chat/rooms/$roomId/invite');
  static String chatRoomMessagesUrl(String roomId) =>
      api('chat/rooms/$roomId/messages');

  // ── Friends ───────────────────────────────────────────────────────────────
  static String get friendsSearchUrl => api('friends/search');

  // ── Users / Follow ────────────────────────────────────────────────────────
  static String get usersFollowUrl => api('users/follow');
  static String followUserUrl(String userId) => api('users/$userId/follow');

  // -- Contacts --
  static String get contactsUrl => api('get_contacts');

  // ── Notifications ────────────────────────────────────────────────────────
  static String get notificationsUrl => api('notifications');
  static String get notificationsUnreadCountUrl =>
      api('notifications/unread-count');
  static String notificationReadUrl(String id) => api('notifications/$id/read');
  static String notificationActionUrl(String id) =>
      api('notifications/$id/action');
  static String get notificationsReadAllUrl => api('notifications/read-all');
  static String get notificationsMarkAllReadUrl =>
      api('notifications/mark-all-read');

  // ── Settings ─────────────────────────────────────────────────────────────
  static String get settingsUrl => api('settings');
  static String get settingsLanguageUrl => api('settings/language');
  static String get settingsThemeUrl => api('settings/theme');

  // ── Steps ────────────────────────────────────────────────────────────────
  static String get stepsSummaryUrl => api('steps/summary');

  // ── Subscriptions ────────────────────────────────────────────────────────
  static String get subscriptionSelectUrl => api('subscription/select');
  static String get subscriptionsSelectUrl => api('subscriptions/select');
  static String get subscriptionUrl => api('subscription');
  static String get subscriptionsUrl => api('subscriptions');
  static String get subscriptionPlanUrl => api('subscription/plan');
  static String get subscriptionsPlanUrl => api('subscriptions/plan');
  static String get appSubscriptionPlansUrl => api('subscriptions/plans');
  static String get appSubscriptionCheckoutUrl => api('subscriptions/checkout');

  // Additional backend endpoints (matches provided API) 127.0.0.1:8000/api
  static String get acceptChallengeUrl => api('challenges/accept');
  static String get acceptChallengeUploadUrl => api('accept_challenge_upload');
  static String get addRecipeUrl => api('add_recipe');
  static String get addStepsUrl => api('add_steps');
  static String get allChallengesUrl => api('all_challenges');
  static String get allFoodLogsUrl => api('all_food_logs');
  static String get chatCheckUrl => api('chat_check');
  static String get commentUrl => api('comment');
  static String get commentFoodLogUrl => api('comment_food_log');
  static String get createChallengeUrl => api('create_challenge');
  static String get createFoodLogUrl => api('create_food_log');
  static String get deleteFoodLogUrl => api('delete_food_log');
  static String get fitnessRecordUrl => api('fitness_record');
  static String get followUrl => api('follow');
  static String get recipesUrl => api('get_recipes');
  static String get shortsUrl => api('get_shorts');
  static String get leaderboardUrl => api('leaderboard');
  static String get likeAcceptedChallengeUrl => api('like_accepted_challenge');
  static String get likeChallengeUrl => api('like_challenge');
  static String get likeCommentUrl => api('like_comment');
  static String get likeFoodLogUrl => api('like_food_log');
  static String get likeFoodLogCommentUrl => api('like_food_log_comment');
  static String get likeSubCommentUrl => api('like_sub_comment');
  static String get myChallengesUrl => api('my_challenges');

  static String get myFoodLogsUrl => api('my_food_logs');

  static String get reportUrl => api('report');
  static String get searchVideosUrl => api('search_videos');
  static String get sendMessageUrl => api('send_message');
  static String get socialDetailUrl => api('social_detail');
  static String get subCommentUrl => api('sub_comment');
  static String get updateFcmUrl => api('update_fcm');
  static String get updateFitnessLevelUrl => api('update_fitness_level');
  static String get updatePasswordUrl => api('update_password');
  static String get updateProfileUrl => api('update_profile');
  static String get updateProfileImageUrl => api('update_profile_img');
  static String get updateSubscriptionUrl => api('update_subscription');
  static String get userUrl => api('user');
  static String get userProfileUrl => api('user_profile');
  static String get viewUserProfileUrl => api('view_user_profile');

  // ── Private helper ───────────────────────────────────────────────────────
  static String _join(List<String> parts) {
    final cleaned = parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => p.replaceAll(RegExp(r'^/+|/+$'), ''))
        .toList();

    return cleaned.isEmpty
        ? ''
        : cleaned.first +
              (cleaned.length > 1 ? '/${cleaned.skip(1).join('/')}' : '');
  }

  static Future<List<Map<String, dynamic>>> waitForAll(
    Iterable<Future<Map<String, dynamic>>> calls,
  ) {
    return Future.wait(calls);
  }
}
