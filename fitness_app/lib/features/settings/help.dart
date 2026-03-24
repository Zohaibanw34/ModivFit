import 'package:flutter/material.dart';

import 'package:fitness_app/layout/main_layout.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqItems = <({String title, String answer})>[
      (
        title: 'How do I manage my notifications?',
        answer:
            'Open Settings and customize the notification options based on your preference.',
      ),
      (
        title: 'How do I start a guided yoga session?',
        answer:
            'Go to Guides, choose a yoga program, and tap start to begin your guided session.',
      ),
      (
        title: 'How do I join a support group?',
        answer:
            'Open the community tab and select a public group or accept an invite to join.',
      ),
      (
        title: 'How do I manage my fitness plan?',
        answer:
            'Use the Challenges and Home tabs to update your goals, workouts, and daily progress.',
      ),
    ];

    return MainLayout(
      title: 'Help',
      showAppBar: true,
      showBackButton: true,
      showBottomNav: false,
      currentIndex: 5,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'search for help',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...faqItems.map(
            (item) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEDEDED)),
              ),
              child: ExpansionTile(
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    item.answer,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
