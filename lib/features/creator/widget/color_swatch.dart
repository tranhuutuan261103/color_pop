import 'package:flutter/material.dart';

class ColorSwatchWidget extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final bool isWhite;
  final VoidCallback onTap;

  const ColorSwatchWidget({
    super.key,
    required this.color,
    required this.isSelected,
    this.isWhite = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : (isWhite ? Border.all(color: Colors.grey[300]!, width: 1) : null),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.5),
                spreadRadius: 2,
                blurRadius: 4,
              ),
          ],
        ),
      ),
    );
  }
}