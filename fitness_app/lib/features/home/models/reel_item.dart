class ReelItem {
  final String id;
  final String userId;
  final String userName;
  final String userHandle;
  final String profileImage;
  final String previewImage;
  final String ageText;
  final DateTime createdAt;
  final String description;
  final List<String> hashtags;
  final int likeCount;
  final int dislikeCount;
  final int favoriteCount;
  final int commentCount;
  final bool isLiked;
  final bool isDisliked;
  final bool isFavorite;
  final bool isFollowing;
  final int creatorFollowerCount;
  final int viewerFollowingCount;

  const ReelItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userHandle,
    required this.profileImage,
    required this.previewImage,
    required this.ageText,
    required this.createdAt,
    this.description = '',
    this.hashtags = const <String>[],
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.isFavorite = false,
    this.isFollowing = false,
    this.creatorFollowerCount = 0,
    this.viewerFollowingCount = 0,
  });

  String get normalizedHandle {
    final trimmed = userHandle.trim();
    if (trimmed.isEmpty) return '@${userName.replaceAll(' ', '_').toLowerCase()}';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  String get descriptionWithTags {
    final tags = hashtags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .join(' ');
    if (description.trim().isEmpty) return tags;
    if (tags.isEmpty) return description.trim();
    return '${description.trim()} $tags';
  }

  ReelItem copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userHandle,
    String? profileImage,
    String? previewImage,
    String? ageText,
    DateTime? createdAt,
    String? description,
    List<String>? hashtags,
    int? likeCount,
    int? dislikeCount,
    int? favoriteCount,
    int? commentCount,
    bool? isLiked,
    bool? isDisliked,
    bool? isFavorite,
    bool? isFollowing,
    int? creatorFollowerCount,
    int? viewerFollowingCount,
  }) {
    return ReelItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      profileImage: profileImage ?? this.profileImage,
      previewImage: previewImage ?? this.previewImage,
      ageText: ageText ?? this.ageText,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      hashtags: hashtags ?? this.hashtags,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isFavorite: isFavorite ?? this.isFavorite,
      isFollowing: isFollowing ?? this.isFollowing,
      creatorFollowerCount: creatorFollowerCount ?? this.creatorFollowerCount,
      viewerFollowingCount: viewerFollowingCount ?? this.viewerFollowingCount,
    );
  }
}
