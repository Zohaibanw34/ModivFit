import 'package:flutter/material.dart';

class PrimaryNextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const PrimaryNextButton({
    super.key,
    required this.onPressed,
    this.label = "Next",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
