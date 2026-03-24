import 'package:fitness_app/features/home/controllers/challenges_feed_controller.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/layout/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChallengePostDetailScreen extends StatelessWidget {
  const ChallengePostDetailScreen({super.key});

  Future<void> _openReplyDialog(
    BuildContext context,
    ChallengesFeedController controller,
    String postId,
  ) async {
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
    controller.addReply(postId, text);
  }

  @override
  Widget build(BuildContext context) {
    final postId = Get.arguments as String?;
    final controller = Get.find<ChallengesFeedController>();
    final profileController = Get.isRegistered<HomeProfileController>()
        ? Get.find<HomeProfileController>()
        : Get.put(HomeProfileController(), permanent: true);

    return MainLayout(
      title: 'Challenge Detail',
      showAppBar: true,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: 2,
      body: GetBuilder<ChallengesFeedController>(
        builder: (_) {
          if (postId == null) {
            return const Center(child: Text('Challenge not found'));
          }

          final post = controller.findById(postId);
          if (post == null) {
            return const Center(child: Text('Challenge not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _DetailAvatar(
                        post: post,
                        profileController: profileController,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9A9A9A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Category: ${post.category} | Fitness Level: ${post.fitnessLevel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF81C784),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (post.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        post.imageBytes!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(post.target, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    post.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A4A4A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${post.likes} Likes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6F6F6F),
                        ),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () =>
                            _openReplyDialog(context, controller, post.id),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6F6F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // accept button only for the post author there is connect api to accept the post
                      InkWell(
                        onTap: () => controller.acceptPost(post.id),
                        child: Text(
                          post.accepted ? 'Accepted' : 'Accept',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6F6F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => controller.likePost(post.id),
                        child: Icon(
                          post.isLiked
                              ? Icons.thumb_up_alt
                              : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: post.isLiked
                              ? Colors.black
                              : const Color(0xFF8C97AA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => controller.dislikePost(post.id),
                        child: Icon(
                          post.isDisliked
                              ? Icons.thumb_down_alt
                              : Icons.thumb_down_alt_outlined,
                          size: 18,
                          color: post.isDisliked
                              ? Colors.black
                              : const Color(0xFF8C97AA),
                        ),
                      ),
                    ],
                  ),
                  if (post.replies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    ...post.replies.map(
                      (reply) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
          );
        },
      ),
    );
  }
}

class _DetailAvatar extends StatelessWidget {
  final ChallengePost post;
  final HomeProfileController profileController;

  const _DetailAvatar({required this.post, required this.profileController});

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
