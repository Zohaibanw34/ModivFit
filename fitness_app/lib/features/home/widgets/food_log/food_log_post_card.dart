import 'package:flutter/material.dart';

import 'package:fitness_app/features/home/widgets/food_log/food_log_actions.dart';
import 'package:fitness_app/features/home/widgets/food_log/public_profile_avatar.dart';

class FoodLogPostCard extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String timeAgo;
  final String message;
  final int likes;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDislikeTap;

  const FoodLogPostCard({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.timeAgo,
    required this.message,
    required this.likes,
    this.onLikeTap,
    this.onReplyTap,
    this.onDislikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 353.71,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PublicProfileAvatar(
            avatarUrl: avatarUrl,
            name: name,
            timeAgo: timeAgo,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 353.71,
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF2A2A2A),
                fontSize: 30 / 2,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 353.71,
            height: 24.1,
            child: Row(
              children: [
                FoodLogLikeButton(likes: likes, onTap: onLikeTap),
                const SizedBox(width: 12),
                FoodLogReplyButton(onTap: onReplyTap),
                const Spacer(),
                FoodLogLikeIconButton(onTap: onLikeTap),
                const SizedBox(width: 10),
                FoodLogDislikeButton(onTap: onDislikeTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
