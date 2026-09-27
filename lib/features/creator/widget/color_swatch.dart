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
              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
              : (isWhite ? Border.all(color: Theme.of(context).dividerColor, width: 1) : null),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
              ),
          ],
        ),
      ),
    );
  }
}