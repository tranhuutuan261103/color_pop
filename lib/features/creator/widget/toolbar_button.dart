import 'package:flutter/material.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;

  const ToolbarButton({
    super.key,
    required this.icon,
    this.iconColor = Colors.black54,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}