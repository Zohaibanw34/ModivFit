import 'package:flutter/material.dart';

class FoodLogLikeButton extends StatelessWidget {
  final int likes;
  final VoidCallback? onTap;

  const FoodLogLikeButton({super.key, required this.likes, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        '$likes Likes',
        style: const TextStyle(
          color: Color(0xFF7B8194),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FoodLogReplyButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FoodLogReplyButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.reply_outlined, size: 14, color: Color(0xFF7B8194)),
          SizedBox(width: 4),
          Text(
            'Reply',
            style: TextStyle(
              color: Color(0xFF7B8194),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FoodLogDislikeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FoodLogDislikeButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.thumb_down_alt_outlined,
        size: 17,
        color: Color(0xFF8D93A8),
      ),
    );
  }
}

class FoodLogLikeIconButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FoodLogLikeIconButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.thumb_up_alt_outlined,
        size: 17,
        color: Color(0xFF8D93A8),
      ),
    );
  }
}
