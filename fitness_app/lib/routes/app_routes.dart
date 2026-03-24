import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/create_account_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/set_new_password_screen.dart';

import '../features/auth/screens/verification_screen.dart';
import '../features/auth/screens/success_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/change_password_flow_screen.dart';
import '../features/settings/screens/profile_setting.dart';
import '../features/settings/screens/subscription.dart';
import '../features/settings/screens/subscription_options_screen.dart';
import '../features/settings/screens/change_fitness_level.dart';
import '../features/settings/help.dart';
import '../features/settings/screens/language_prefrences.dart';
import '../features/settings/screens/change_theme.dart';

import '../features/auth/screens/onboarding/onboarding_start_screen.dart';
import '../features/auth/screens/onboarding/gender_screen.dart';
import '../features/auth/screens/onboarding/goal_screen.dart';
import '../features/auth/screens/onboarding/fitness_level_screen.dart';
import '../features/auth/screens/onboarding/age_screen.dart';
import '../features/auth/screens/onboarding/height_screen.dart';
import '../features/auth/screens/onboarding/weight_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/food_log_screen.dart';
import '../features/home/screens/challenges_screen.dart';
import '../features/home/screens/random_challenge_screen.dart';
import '../features/home/screens/challenges_feed_screen.dart';
import '../features/home/screens/leaderboard_screen.dart';
import '../features/home/screens/guides_screen.dart';
import '../features/home/screens/invite_friend_screen.dart';
import '../features/home/screens/notifications_screen.dart';
import '../features/home/screens/profile_screen.dart';
import '../features/home/screens/add_media_screen.dart';
import '../features/home/screens/reels_home_screen.dart';
import '../features/home/screens/recommended_meals_screen.dart';
import '../features/home/screens/user_profile_detail_screen.dart';
import '../features/home/screens/add_challenge_post_screen.dart';
import '../features/home/screens/challenge_post_detail_screen.dart';
import '../features/home/screens/record_challenge_screen.dart';
import '../features/home/screens/steps_screen.dart';

import 'package:fitness_app/core/constants/otp_purpose.dart';
import 'package:fitness_app/core/constants/success_purpose.dart';

class AppRoutes {
  // base routes
  static const String splash = '/';
  static const String createAccount = '/create-account';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String setNewPassword = '/set-new-password';

  // flow based routes
  static const String verification = '/verification';
  static const String success = '/success';

  // onboarding routes
  static const String onboardingReady = '/onboarding-ready';
  static const String gender = '/gender';
  static const String goal = '/goal';
  static const String fitnessLevel = '/fitness-level';
  static const String age = '/age';
  static const String height = '/height';
  static const String weight = '/weight';
  static const String home = '/home';
  static const String foodLog = '/food-log';
  static const String challenges = '/challenges';
  static const String randomChallenge = '/random-challenge';
  static const String chatChallenges = '/chat-challenges';
  static const String recordChallenge = '/record-challenge';
  static const String steps = '/steps';
  static const String addChallengePost = '/add-challenge-post';
  static const String challengePostDetail = '/challenge-post-detail';
  static const String leaderboard = '/leaderboard';
  static const String guides = '/guides';
  static const String settings = '/settings';
  static const String profileSettings = '/profile-settings';
  static const String subscription = '/subscription';
  static const String subscriptionOptions = '/subscription-options';
  static const String changeFitnessLevel = '/change-fitness-level';
  static const String help = '/help';
  static const String languagePreferences = '/language-preferences';
  static const String changeTheme = '/change-theme';
  static const String changePassword = '/change-password';
  static const String addAction = '/add';
  static const String notifications = '/notifications';
  static const String inviteFriend = '/invite-friend';
  static const String profile = '/profile';
  static const String reelsHome = '/reels-home';
  static const String recommendedMeals = '/recommended-meals';
  static const String userProfileDetail = '/user-profile-detail';

  // GetX pages
  static final List<GetPage<dynamic>> pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: createAccount, page: () => const CreateAccountScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(
      name: setNewPassword,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return SetNewPasswordScreen(
          purpose: args['purpose'] as OtpPurpose,
          email: (args['email'] ?? '').toString(),
          otp: (args['otp'] ?? '').toString(),
        );
      },
    ),
    GetPage(name: onboardingReady, page: () => const AreYouReadyScreen()),
    GetPage(name: gender, page: () => const GenderScreen()),
    GetPage(name: goal, page: () => const GoalScreen()),
    GetPage(name: fitnessLevel, page: () => const FitnessLevelScreen()),
    GetPage(name: age, page: () => const AgeScreen()),
    GetPage(name: height, page: () => const HeightScreen()),
    GetPage(name: weight, page: () => const WeightScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: foodLog, page: () => const FoodLogScreen()),
    GetPage(name: challenges, page: () => const ChallengesFeedScreen()),
    GetPage(name: randomChallenge, page: () => const RandomChallengeScreen()),
    GetPage(name: chatChallenges, page: () => const ChallengesScreen()),
    GetPage(
      name: recordChallenge,
      page: () => const RecordChallengeScreen(),
    ),
    GetPage(name: addChallengePost, page: () => const AddChallengePostScreen()),
    GetPage(
      name: challengePostDetail,
      page: () => const ChallengePostDetailScreen(),
    ),
    GetPage(name: leaderboard, page: () => const LeaderboardScreen()),
    GetPage(name: guides, page: () => const GuidesScreen()),
    GetPage(name: inviteFriend, page: () => const InviteFriendScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: reelsHome, page: () => const ReelsHomeScreen()),
    GetPage(name: recommendedMeals, page: () => const RecommendedMealsScreen()),
    GetPage(
      name: userProfileDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return UserProfileDetailScreen(
          userId: (args['userId'] ?? '').toString(),
          userName: args['userName']?.toString(),
          userHandle: args['userHandle']?.toString(),
          avatarUrl: args['avatarUrl']?.toString(),
        );
      },
    ),
    GetPage(name: steps, page: () => const StepsScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: profileSettings, page: () => const ProfileSettingScreen()),
    GetPage(name: subscription, page: () => const SubscriptionScreen()),
    GetPage(
      name: subscriptionOptions,
      page: () => const SubscriptionOptionsScreen(),
    ),
    GetPage(
      name: changeFitnessLevel,
      page: () => const ChangeFitnessLevelScreen(),
    ),
    GetPage(name: help, page: () => const HelpScreen()),
    GetPage(
      name: languagePreferences,
      page: () => const LanguagePreferencesScreen(),
    ),
    GetPage(name: changeTheme, page: () => const ChangeThemeScreen()),
    GetPage(name: changePassword, page: () => const ChangePasswordFlowScreen()),
    GetPage(name: addAction, page: () => const AddMediaScreen()),
    GetPage(name: notifications, page: () => const NotificationsScreen()),
    GetPage(
      name: verification,
      page: () {
        final args = Get.arguments;
        if (args is Map<String, dynamic>) {
          return VerificationScreen(
            purpose: args['purpose'] as OtpPurpose,
            email: args['email'] as String?,
            expectedOtp: args['expectedOtp']?.toString(),
          );
        }

        return VerificationScreen(purpose: args as OtpPurpose);
      },
    ),
    GetPage(
      name: success,
      page: () {
        final purpose = Get.arguments as SuccessPurpose;
        return SuccessScreen(purpose: purpose);
      },
    ),
  ];

  static final GetPage<dynamic> unknownRoute = GetPage(
    name: '/not-found',
    page: () => const Scaffold(body: Center(child: Text('Route not found'))),
  );
}
