import 'package:flutter/material.dart';

class FoodLogComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPost;

  const FoodLogComposer({
    super.key,
    required this.controller,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 353.88,
      height: 67.12,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "What's in your mind",
                border: InputBorder.none,
                isCollapsed: true,
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54.1,
            height: 31.33,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: onPost,
              child: const Text(
                'Post',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
