import 'package:flutter/material.dart';

class PublicProfileAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String timeAgo;

  const PublicProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 353.71,
      child: Row(
        children: [
          Container(
            width: 34.42,
            height: 34.42,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFEAEAEA),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person, size: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
