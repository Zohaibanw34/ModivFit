import 'dart:math' as math;

import 'package:fitness_app/features/home/controllers/challenges_feed_controller.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChallengesFeedScreen extends StatefulWidget {
  const ChallengesFeedScreen({super.key});

  @override
  State<ChallengesFeedScreen> createState() => _ChallengesFeedScreenState();
}

class _ChallengesFeedScreenState extends State<ChallengesFeedScreen> {
  int _tabIndex = 0;
  late final ChallengesFeedController _controller;
  late final HomeProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ChallengesFeedController>()
        ? Get.find<ChallengesFeedController>()
        : Get.put(ChallengesFeedController(), permanent: true);
    _profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);
  }

  Future<void> _openReplyDialog(String postId) async {
    final inputController = TextEditingController();
    final reply = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Write your reply'),
            onSubmitted: (_) => Navigator.of(context).pop(inputController.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(inputController.text),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );

    final text = reply?.trim();
    if (text == null || text.isEmpty) return;
    _controller.addReply(postId, text);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Challenges',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 2,
      constrainBody: false,
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentMaxWidth = width >= 1024 ? 760.0 : 520.0;
            final sidePadding = width >= 768 ? 24.0 : 18.0;
            final tabWidth = math.min(
              345.0,
              contentMaxWidth - (sidePadding * 2),
            );

            return GetBuilder<ChallengesFeedController>(
              builder: (controller) {
                final posts = _tabIndex == 0
                    ? controller.publicPosts
                    : controller.myPosts;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: 94 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: sidePadding,
                                ),
                                child: SizedBox(
                                  width: tabWidth,
                                  height: 40,
                                  child: _ChallengeTabs(
                                    selectedIndex: _tabIndex,
                                    onTap: (index) {
                                      setState(() {
                                        _tabIndex = index;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: sidePadding,
                                ),
                                child: posts.isEmpty
                                    ? _EmptyMyPostState(
                                        showHint: _tabIndex == 1,
                                      )
                                    : Column(
                                        children: List.generate(posts.length, (
                                          index,
                                        ) {
                                          final post = posts[index];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: index == posts.length - 1
                                                  ? 0
                                                  : 12,
                                            ),
                                            child: _ChallengeCard(
                                              post: post,
                                              profileController:
                                                  _profileController,
                                              onOpenDetail: () => Get.toNamed(
                                                AppRoutes.challengePostDetail,
                                                arguments: post.id,
                                              ),
                                              onLikeTap: () =>
                                                  controller.likePost(post.id),
                                              onDislikeTap: () => controller
                                                  .dislikePost(post.id),
                                              onReplyTap: () =>
                                                  _openReplyDialog(post.id),
                                              onAcceptTap: () => controller
                                                  .acceptPost(post.id),
                                            ),
                                          );
                                        }),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        if (_tabIndex == 1)
                          Positioned(
                            right: sidePadding,
                            bottom: 18 + MediaQuery.of(context).padding.bottom,
                            child: InkWell(
                              onTap: () =>
                                  Get.toNamed(AppRoutes.addChallengePost),
                              borderRadius: BorderRadius.circular(19),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ChallengeTabs({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Row(
        children: List.generate(2, (index) {
          final isSelected = selectedIndex == index;
          final label = index == 0 ? 'Public' : 'My Post';
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengePost post;
  final HomeProfileController profileController;
  final VoidCallback onOpenDetail;
  final VoidCallback onLikeTap;
  final VoidCallback onDislikeTap;
  final VoidCallback onReplyTap;
  final VoidCallback onAcceptTap;

  const _ChallengeCard({
    required this.post,
    required this.profileController,
    required this.onOpenDetail,
    required this.onLikeTap,
    required this.onDislikeTap,
    required this.onReplyTap,
    required this.onAcceptTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpenDetail,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PostAvatar(post: post, profileController: profileController),
                  const SizedBox(width: 8),
                  Text(
                    post.author,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.timeAgo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Category: ${post.category}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF81C784),
                    ),
                  ),
                  Text(
                    'Fitness Level: ${post.fitnessLevel}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF81C784),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                post.target,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${post.likes} Likes',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8F99AA),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onReplyTap,
                    child: const Row(
                      children: [
                        Icon(
                          Icons.reply_outlined,
                          size: 12,
                          color: Color(0xFF8F99AA),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8F99AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onAcceptTap,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: Color(0xFF8F99AA),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.accepted ? 'Accepted' : 'Accept',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8F99AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onLikeTap,
                    child: Icon(
                      post.isLiked
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: post.isLiked
                          ? Colors.black
                          : const Color(0xFF8F99AA),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onDislikeTap,
                    child: Icon(
                      post.isDisliked
                          ? Icons.thumb_down_alt
                          : Icons.thumb_down_alt_outlined,
                      size: 16,
                      color: post.isDisliked
                          ? Colors.black
                          : const Color(0xFF8F99AA),
                    ),
                  ),
                ],
              ), //
              if (post.replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...post.replies.map(
                  (reply) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '- $reply',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostAvatar extends StatelessWidget {
  final ChallengePost post;
  final HomeProfileController profileController;

  const _PostAvatar({required this.post, required this.profileController});

  @override
  Widget build(BuildContext context) {
    if (post.isMine) {
      return Obx(
        () => CircleAvatar(
          radius: 12,
          backgroundImage: profileController.avatarProvider,
          backgroundColor: const Color(0xFFEAEAEA),
          child: profileController.avatarProvider == null
              ? const Icon(Icons.person, size: 14, color: Colors.black54)
              : null,
        ),
      );
    }

    if (post.avatarUrl != null && post.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(post.avatarUrl!),
        backgroundColor: const Color(0xFFEAEAEA),
      );
    }

    return const CircleAvatar(
      radius: 12,
      backgroundColor: Color(0xFFEAEAEA),
      child: Icon(Icons.person, size: 14, color: Colors.black54),
    );
  }
}

class _EmptyMyPostState extends StatelessWidget {
  final bool showHint;

  const _EmptyMyPostState({required this.showHint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(
        showHint
            ? 'No challenge posted yet. Tap + to add your first challenge.'
            : 'No public post found.',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
