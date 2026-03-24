import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class RandomChallenge {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String duration;
  final double progress;
  final int timeLimitMinutes;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String category;

  const RandomChallenge({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.duration,
    required this.progress,
    required this.timeLimitMinutes,
    this.imageUrl,
    this.imageBytes,
    this.category = 'General',
  });

  ImageProvider? get imageProvider {
    if (imageBytes != null) {
      return MemoryImage(imageBytes!);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return NetworkImage(imageUrl!);
    }
    return null;
  }
}
