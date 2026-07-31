import 'package:flutter/material.dart';

class SmallDot extends StatelessWidget {
  final Color color;

  const SmallDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}