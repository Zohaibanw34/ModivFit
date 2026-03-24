<?php

use App\Http\Controllers\Api\ChallengeController;
use App\Http\Controllers\Api\CompatController;
use App\Http\Controllers\Api\FoodLogController;
use App\Http\Controllers\Api\FrontendAdapterController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\LegacyController;
use App\Http\Controllers\Api\NotificationsController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\ReelController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

// Health
Route::get('health', [LegacyController::class, 'health']);

// Public auth (canonical)
Route::post('login', [UserController::class, 'login']);
Route::post('register', [UserController::class, 'register']);
Route::post('send_otp', [UserController::class, 'verifyEmail']);
Route::post('validate_otp', [UserController::class, 'validateOtp']);
Route::post('update_password', [UserController::class, 'updatePassword']);

// Public auth (frontend uses /api/auth/*)
Route::post('auth/login', [UserController::class, 'login']);
Route::post('auth/signin', [UserController::class, 'login']);
Route::post('auth/signup', [UserController::class, 'register']);
Route::post('auth/forgot-password', [UserController::class, 'verifyEmail']);
Route::post('auth/send-change-password-otp', [UserController::class, 'verifyEmail']);
Route::post('auth/verify-signup-otp', [UserController::class, 'validateOtp']);
Route::post('auth/verify-forgot-otp', [UserController::class, 'validateOtp']);
Route::post('auth/verify-change-password-otp', [UserController::class, 'validateOtp']);
Route::post('auth/reset-password', [UserController::class, 'updatePassword']);
Route::post('auth/change-password', [UserController::class, 'updatePassword']);
Route::post('auth/confirm-password', [UserController::class, 'updatePassword']);

// Current user
Route::get('user', [UserController::class, 'loginUsingToken'])->middleware('auth:sanctum');

// Protected routes (FunFit flow)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('like_accepted_challenge', [CompatController::class, 'likeAcceptedChallenge']);
    Route::post('like_challenge', [ChallengeController::class, 'like']);
    Route::post('comment', [ChallengeController::class, 'comment']);
    Route::post('like_comment', [CompatController::class, 'likeComment']);
    Route::post('sub_comment', [FoodLogController::class, 'comment']);
    Route::post('like_sub_comment', [CompatController::class, 'likeSubComment']);

    Route::post('create_food_log', [FoodLogController::class, 'store']);
    Route::post('like_food_log', [FoodLogController::class, 'like']);
    Route::post('delete_food_log', [FoodLogController::class, 'deleteLog']);
    Route::post('comment_food_log', [FoodLogController::class, 'comment']);
    Route::post('like_food_log_comment', [CompatController::class, 'likeComment']);

    Route::get('my_food_logs', [FoodLogController::class, 'indexMine']);
    Route::get('all_food_logs', [FoodLogController::class, 'indexPublic']);

    Route::post('leaderboard', [UserController::class, 'leaderBoard']);
    Route::post('update_subscription', [SubscriptionController::class, 'select']);

    Route::post('create_challenge', [ChallengeController::class, 'store']);
    Route::post('accept_challenge', [ChallengeController::class, 'accept']);
    Route::post('social_detail', [UserController::class, 'social']);
    Route::post('accept_challenge_upload', [CompatController::class, 'acceptChallengeUpload']);
    Route::get('my_challenges', [ChallengeController::class, 'index']);
    Route::get('all_challenges', [ChallengeController::class, 'show']);

    Route::get('token_login', [UserController::class, 'loginUsingToken']);
    Route::get('logout', [UserController::class, 'logout']);

    Route::post('update_profile', [UserController::class, 'updateProfile']);
    Route::post('follow', [CompatController::class, 'follow']);
    Route::post('update_profile_img', [UserController::class, 'uploadProfileImg']);

    Route::post('get_shorts', [CompatController::class, 'getShorts']);
    Route::post('search_videos', [CompatController::class, 'searchVideos']);
    Route::post('test2', [LegacyController::class, 'handle'])->defaults('endpoint', 'test2');
    Route::post('update_fcm', [UserController::class, 'fcmUpdate']);
    Route::get('user_profile', [UserController::class, 'profile']);

    Route::get('get_contacts', [CompatController::class, 'chatRooms']);
    Route::post('send_message', [CompatController::class, 'createChatMessage']);

    Route::post('add_recipe', [CompatController::class, 'addRecipe']);
    Route::post('get_recipes', [CompatController::class, 'getRecipes']);
    Route::post('add_steps', [CompatController::class, 'addSteps']);
    Route::post('report', [CompatController::class, 'report']);
    Route::post('view_user_profile', [CompatController::class, 'viewUserProfile']);

    Route::get('notifications', [NotificationsController::class, 'index']);
    Route::get('notifications/unread-count', [NotificationsController::class, 'unreadCount']);
    Route::post('fitness_record', [CompatController::class, 'stepsSummary']);
    Route::post('update_fitness_level', [UserController::class, 'updateFitnessLevel']);

    // Extra: challenges list/current, leaderboard GET, subscription get
    Route::get('challenges', [ChallengeController::class, 'index']);
    Route::get('challenges/current', [ChallengeController::class, 'current']);
    Route::get('leaderboard', [LeaderboardController::class, 'index']);
    Route::get('subscription', [SubscriptionController::class, 'get']);
    Route::get('subscriptions', [SubscriptionController::class, 'get']);
    Route::get('subscriptions/plans', [SubscriptionController::class, 'plans']);
    Route::post('subscriptions/checkout', [SubscriptionController::class, 'checkout']);
    Route::post('subscription/select', [SubscriptionController::class, 'select']);
    Route::post('subscriptions/select', [SubscriptionController::class, 'select']);
    Route::post('subscription/plan', [SubscriptionController::class, 'select']);
    Route::post('subscriptions/plan', [SubscriptionController::class, 'select']);

    Route::post('notifications/{id}/read', [NotificationsController::class, 'read']);
    Route::post('notifications/{id}/action', [NotificationsController::class, 'action']);
    Route::post('notifications/read-all', [NotificationsController::class, 'readAll']);
    Route::post('notifications/mark-all-read', [NotificationsController::class, 'markAllRead']);

    // Routes matching frontend ApiConfig (so no frontend API is missing)
    Route::post('onboarding/save', [FrontendAdapterController::class, 'onboardingSave']);
    Route::get('onboarding/get', [FrontendAdapterController::class, 'onboardingGet']);
    Route::get('home', [FrontendAdapterController::class, 'home']);
    Route::get('profile', [UserController::class, 'profile']);
    Route::post('profile', [UserController::class, 'updateProfile']);
    Route::post('profile/image', [UserController::class, 'uploadProfileImg']);
    Route::get('profile/media', [FrontendAdapterController::class, 'profileMedia']);
    Route::get('challenges/categories', [FrontendAdapterController::class, 'challengeCategories']);
    Route::post('challenges/start-random', [FrontendAdapterController::class, 'startRandomChallenge']);
    Route::get('challenges/limits', [FrontendAdapterController::class, 'challengeLimits']);
    Route::post('challenges/limits/extend', [FrontendAdapterController::class, 'challengeLimitsExtend']);
    Route::get('challenges/cards', [FrontendAdapterController::class, 'challengeCards']);
    Route::post('challenges/accept', [ChallengeController::class, 'accept']);
    Route::get('challenges/{id}', [FrontendAdapterController::class, 'challengeById']);
    Route::get('challenges/{id}/progress', [FrontendAdapterController::class, 'challengeProgress']);
    Route::post('challenges/{id}/progress', [FrontendAdapterController::class, 'challengeProgress']);
    Route::post('challenges/{id}/record', [FrontendAdapterController::class, 'challengeRecord']);
    Route::post('posts/media', [FrontendAdapterController::class, 'postsMedia']);
    Route::get('chat/rooms', [FrontendAdapterController::class, 'chatRooms']);
    Route::post('chat/rooms/{roomId}/invite', [FrontendAdapterController::class, 'chatRoomInvite']);
    Route::get('chat/rooms/{roomId}/messages', [FrontendAdapterController::class, 'chatRoomMessages']);
    Route::post('chat/rooms/{roomId}/messages', [FrontendAdapterController::class, 'chatRoomMessages']);
    Route::get('friends/search', [FrontendAdapterController::class, 'friendsSearch']);
    Route::get('users/{userId}', [UserController::class, 'showPublic']);
    Route::post('users/follow', [FrontendAdapterController::class, 'usersFollow']);
    Route::post('users/{userId}/follow', [FrontendAdapterController::class, 'followUser']);
    Route::get('settings', [FrontendAdapterController::class, 'settings']);
    Route::put('settings', [FrontendAdapterController::class, 'settings']);
    Route::put('settings/language', [FrontendAdapterController::class, 'settingsLanguage']);
    Route::put('settings/theme', [FrontendAdapterController::class, 'settingsTheme']);
    Route::get('steps/summary', [FrontendAdapterController::class, 'stepsSummary']);
    Route::get('guides', [FrontendAdapterController::class, 'guides']);
    Route::get('guides/posts', [FrontendAdapterController::class, 'guidesPosts']);
    Route::post('guides/posts/{id}/like', [FrontendAdapterController::class, 'guidePostLike']);
    Route::post('guides/posts/{id}/reply', [FrontendAdapterController::class, 'guidePostReply']);
    Route::post('reels/reactions', [FrontendAdapterController::class, 'reelsReactions']);
    Route::post('reels/{reelId}/reactions', [FrontendAdapterController::class, 'reelReactions']);
    Route::post('reels/{reelId}/reactions/{type}', [FrontendAdapterController::class, 'reelReactionByType']);

    // Reels feed & creation (GET reels?search= for search)
    Route::get('reels', [ReelController::class, 'index']);
    Route::post('reels/{id}/view', [ReelController::class, 'view']);
    Route::get('reels/{id}/comments', [ReelController::class, 'comments']);
    Route::post('reels/{id}/comments', [ReelController::class, 'storeComment']);
    Route::get('reels/{id}', [ReelController::class, 'show']);
    Route::post('reels', [ReelController::class, 'store']);

    // Recommended meals for home & Meals screen
    Route::get('recommended_meal', [FrontendAdapterController::class, 'recommendedMeal']);
    Route::get('recommended_meals', [FrontendAdapterController::class, 'recommendedMeals']);
});

// Test
Route::get('test', [LegacyController::class, 'handle'])->defaults('endpoint', 'test');
Route::post('test_modal', [SubscriptionController::class, 'select']);
Route::post('chat_check', [CompatController::class, 'chatRooms']);
Route::post('test_chat', [CompatController::class, 'createChatMessage']);
