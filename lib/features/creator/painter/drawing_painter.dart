import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_path.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;

  DrawingPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final path in paths) {
      final paint = Paint()
        ..color = path.isEraser ? Colors.transparent : path.color
        ..strokeWidth = path.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = path.isEraser ? BlendMode.clear : BlendMode.srcOver;

      if (path.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, [path.points.first], paint);
      } else if (path.points.length > 1) {
        final pathObj = Path();
        pathObj.moveTo(path.points.first.dx, path.points.first.dy);
        for (int i = 1; i < path.points.length; i++) {
          pathObj.lineTo(path.points[i].dx, path.points[i].dy);
        }
        canvas.drawPath(pathObj, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}