import 'package:flutter/material.dart';

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}