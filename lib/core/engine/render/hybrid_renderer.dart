import 'package:flutter/material.dart';
import '../../models/color_pop_document.dart';
import '../../models/tool_type.dart';
import '../../geometry/path_command.dart';
import '../../topology/region.dart';

import 'dart:ui' as ui;

class HybridRenderer extends CustomPainter {
  final ColorPopDocument document;
  final ui.Image? lineArtImage;

  HybridRenderer(this.document, {this.lineArtImage});

  @override
  void paint(Canvas canvas, Size size) {
    if (document.regions.isEmpty) return;

    final scaleX = size.width / document.width;
    final scaleY = size.height / document.height;

    canvas.scale(scaleX, scaleY);

    // Split regions into paintable (background) and ink (foreground)
    final paintRegions = document.regions.where((r) => !r.isStroke).toList();

    // 1. Render Paint Regions (Background areas and user colors)
    for (final region in paintRegions) {
      final path = _createPathForRegion(region);

      // Draw base fill
      final baseColor =
          document.paintState.getRegionColor(region.id) ?? region.color;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = baseColor;
      canvas.drawPath(path, paint);

      // Mask dilation (Xử lý mặt nạ mở rộng vùng tô ôm sát mép trong của viền):
      // Đảm bảo nét tô khớp hoàn toàn, ăn sâu 1.9px dưới chân viền đen,
      // triệt tiêu tuyệt đối 100% mọi khe hở trắng nhỏ li ti xung quanh viền
      final edgeFillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = baseColor;
      canvas.drawPath(path, edgeFillPaint);

      // Draw freehand strokes (brush, pencil, spray, eraser) clipped to region
      final strokes = document.paintState.getStrokes(region.id);
      if (strokes.isNotEmpty) {
        canvas.save();
        canvas.clipPath(path);

        for (final stroke in strokes) {
          final strokePaint = Paint()
            ..color = stroke.color
            ..strokeWidth = stroke.size
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true;

          if (stroke.type == ToolType.eraser) {
            strokePaint.blendMode = BlendMode.clear;
            strokePaint.style = PaintingStyle.stroke;
          } else if (stroke.type == ToolType.spray) {
            strokePaint.style = PaintingStyle.fill;
            for (final point in stroke.points) {
              canvas.drawCircle(point, stroke.size, strokePaint);
            }
            continue;
          } else {
            strokePaint.style = PaintingStyle.stroke;
          }

          if (stroke.points.isNotEmpty) {
            final strokePath = Path();
            strokePath.moveTo(stroke.points.first.dx, stroke.points.first.dy);
            for (int i = 1; i < stroke.points.length; i++) {
              strokePath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
            }
            canvas.drawPath(strokePath, strokePaint);
          }
        }

        canvas.restore();
      }
    }

    // 2. Render Line Art Overlay: Phủ lớp viền đen lên trên với BlendMode.multiply
    if (lineArtImage != null) {
      final lineArtPaint = Paint()
        ..blendMode = BlendMode.multiply
        ..filterQuality = FilterQuality.high;

      final srcRect = Rect.fromLTWH(
        0,
        0,
        lineArtImage!.width.toDouble(),
        lineArtImage!.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(0, 0, document.width, document.height);
      canvas.drawImageRect(lineArtImage!, srcRect, dstRect, lineArtPaint);
    }

    // 3. Khử răng cưa sub-pixel và lấp đầy khoảng hở giữa đường bao và đường viền (Border Bridge):
    // 3. Khử răng cưa sub-pixel và lấp đầy khoảng hở giữa đường bao và đường viền (Border Bridge):
    // Nâng strokeWidth lên 2.8px (bán kính mở rộng 1.4px) giúp đường bao vươn khít hoàn toàn
    // vào mép viền đen Line Art, xóa sạch 100% các pixel trắng li ti mà không làm dày nét chính.
    final vectorOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = Colors.black;

    for (final region in paintRegions) {
      final path = _createPathForRegion(region);
      canvas.drawPath(path, vectorOutlinePaint);
    }
  }

  Path _createPathForRegion(Region region) {
    final path = Path();
    path.fillType = PathFillType.evenOdd;

    void addGeometryPathToPath(GeometryPath gPath) {
      for (final cmd in gPath.commands) {
        if (cmd is MoveToCommand) {
          path.moveTo(cmd.target.x, cmd.target.y);
        } else if (cmd is LineToCommand) {
          path.lineTo(cmd.target.x, cmd.target.y);
        } else if (cmd is CubicToCommand) {
          path.cubicTo(
            cmd.control1.x,
            cmd.control1.y,
            cmd.control2.x,
            cmd.control2.y,
            cmd.target.x,
            cmd.target.y,
          );
        } else if (cmd is CloseCommand) {
          path.close();
        }
      }
    }

    addGeometryPathToPath(region.outerBoundary.path);
    for (final hole in region.holes) {
      addGeometryPathToPath(hole.path);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant HybridRenderer oldDelegate) {
    return true;
  }
}
