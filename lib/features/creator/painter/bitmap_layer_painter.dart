import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BitmapLayerPainter extends CustomPainter {
  const BitmapLayerPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant BitmapLayerPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}