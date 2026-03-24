import 'package:flutter/material.dart';

class FoodLogTabSwitcher extends StatelessWidget {
  final bool isPublicSelected;
  final VoidCallback onPublicTap;
  final VoidCallback onMyPostTap;

  const FoodLogTabSwitcher({
    super.key,
    required this.isPublicSelected,
    required this.onPublicTap,
    required this.onMyPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 345,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TabItem(
            label: 'Public',
            selected: isPublicSelected,
            onTap: onPublicTap,
          ),
          _TabItem(
            label: 'My Post',
            selected: !isPublicSelected,
            onTap: onMyPostTap,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
