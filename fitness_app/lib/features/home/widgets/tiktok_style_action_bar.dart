import 'package:flutter/material.dart';

/// TikTok-style vertical action bar: like, comment, save, share.
/// Use on full-screen reel or media post viewers.
class TikTokStyleActionBar extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onLike;
  final int commentCount;
  final VoidCallback? onComment;
  final bool isSaved;
  final int saveCount;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final bool likeLoading;
  final Widget? topChild;
  final Widget? bottomChild;

  const TikTokStyleActionBar({
    super.key,
    this.isLiked = false,
    this.likeCount = 0,
    this.onLike,
    this.commentCount = 0,
    this.onComment,
    this.isSaved = false,
    this.saveCount = 0,
    this.onSave,
    this.onShare,
    this.likeLoading = false,
    this.topChild,
    this.bottomChild,
  });

  static String formatCount(int value) {
    if (value >= 1000000) {
      final shortened = (value / 1000000).toStringAsFixed(
        value % 1000000 == 0 ? 0 : 1,
      );
      return '${shortened}M';
    }
    if (value >= 1000) {
      final shortened = (value / 1000).toStringAsFixed(
        value % 1000 == 0 ? 0 : 1,
      );
      return '${shortened}K';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (topChild != null) topChild!,
          _ActionItem(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: formatCount(likeCount),
            active: isLiked,
            loading: likeLoading,
            onTap: onLike,
          ),
          _ActionItem(
            icon: Icons.chat_bubble_outline,
            label: formatCount(commentCount),
            onTap: onComment,
          ),
          _ActionItem(
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: formatCount(saveCount),
            active: isSaved,
            onTap: onSave,
          ),
          _ActionItem(
            icon: Icons.send_outlined,
            label: 'Share',
            onTap: onShare,
          ),
          if (bottomChild != null) bottomChild!,
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFFF4D6D) : Colors.white;
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
