import 'package:flutter/material.dart';
import '../../models/color_pop_document.dart';
import '../../models/tool_type.dart';
import '../../geometry/path_command.dart';
import '../../topology/region.dart';

import 'dart:ui' as ui;

class HybridRenderer extends CustomPainter {
  final ColorPopDocument document;
  final ui.Image? lineArtImage;
  final bool showVectorOutline;

  HybridRenderer(
    this.document, {
    this.lineArtImage,
    this.showVectorOutline = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (document.regions.isEmpty) return;

    final scaleX = size.width / document.width;
    final scaleY = size.height / document.height;

    canvas.scale(scaleX, scaleY);

    // Split regions into paintable (background) and ink (foreground)
    final paintRegions = document.regions.where((r) => !r.isStroke).toList();

    // 0. Nền ĐEN cơ sở cho toàn bộ hệ thống đường viền (Solid Black Inking Base):
    // Biến toàn bộ khoảng hở và vùng viền stroke giữa các vùng tô màu thành MÀU ĐEN ĐẶC.
    // Khi các vùng tô màu (Paint Regions) vẽ đè lên trên, khoảng viền xung quanh ảnh
    // sẽ là màu đen thuần nhất, triệt tiêu 100% viền trắng không thể tô được!
    final blackBasePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, document.width, document.height),
      blackBasePaint,
    );

    // 1. Render Paint Regions (Background areas and user colors)
    for (final region in paintRegions) {
      final path = _createPathForRegion(region);

      final userColor = document.paintState.getRegionColor(region.id);
      final baseColor = userColor ?? region.color;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = baseColor;
      canvas.drawPath(path, paint);

      // Mask dilation: Nếu người dùng đã tô màu vùng này, mở rộng nhẹ màu tô (3.0px)
      // để màu ăn sâu dưới chân viền đen, triệt tiêu hoàn toàn khe hở giữa màu tô và viền.
      if (userColor != null) {
        final edgeFillPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true
          ..color = userColor;
        canvas.drawPath(path, edgeFillPaint);
      }

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

    // 2. Lớp đệm viền vector (Viền của viền / Border Bridge):
    // Vẽ đệm kín các mép bao vector, nằm NGAY DƯỚI lớp viền ảnh gốc (Line Art).
    // Khi lớp viền Line Art phủ lên trên cùng, nó sẽ ép chặt toàn bộ viền vector vào đúng khuôn viền ảnh,
    // triệt tiêu tuyệt đối mọi pixel trắng li ti mà không bị lòi nét ra ngoài.
    if (showVectorOutline) {
      final vectorOutlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = Colors.black;

      for (final region in paintRegions) {
        final path = _createPathForRegion(region);
        canvas.drawPath(path, vectorOutlinePaint);
      }
    }

    // 3. Render Line Art Overlay: Phủ lớp viền ảnh gốc lên TRÊN CÙNG với BlendMode.multiply
    // Giúp ép chặt và khóa gọn hoàn toàn đường viền vector vào dáng viền thật của ảnh
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
    return oldDelegate.document != document ||
        oldDelegate.lineArtImage != lineArtImage ||
        oldDelegate.showVectorOutline != showVectorOutline;
  }
}
