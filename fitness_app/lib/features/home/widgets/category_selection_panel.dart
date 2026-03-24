import 'package:flutter/material.dart';

const List<String> kChallengeCategories = [
  'Weightlifting',
  'Calisthenics',
  'Cardio-Based',
  'Hybrid Training',
  'Recovery & Mobility',
];

class CategorySelectionPanel extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelectionPanel({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 344,
      height: 300,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: kChallengeCategories.map((category) {
          final isSelected = category == selectedCategory;
          return SizedBox(
            width: 300,
            height: 44,
            child: ElevatedButton(
              onPressed: () => onCategorySelected(category),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isSelected ? Colors.black : Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                category,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
