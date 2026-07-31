import 'dart:math' as math;
import 'dart:ui';

import '../bitmap/bitmap_surface.dart';

/// Brush-only coloring engine.
///
/// File này phục vụ tính năng brush: vẽ nét cọ trực tiếp lên bitmap.
///
/// File này phục vụ tính năng brush: vẽ nét cọ trực tiếp lên bitmap.
class BrushEngine {
  const BrushEngine();

  void paintStroke({
    required BitmapSurface surface,
    required List<Offset> points,
    required int fillArgb,
    double radius = 2.0,
    Set<int>? boundaryColors,
  }) {
    if (points.isEmpty) {
      return;
    }

    final boundary = boundaryColors ?? const <int>{0xFF000000};
    final brushRadius = radius.round().clamp(1, 4);

    for (final point in points) {
      final centerX = point.dx.round();
      final centerY = point.dy.round();

      for (var dy = -brushRadius; dy <= brushRadius; dy++) {
        for (var dx = -brushRadius; dx <= brushRadius; dx++) {
          final x = centerX + dx;
          final y = centerY + dy;
          if (!surface.buffer.contains(x, y)) {
            continue;
          }

          final distance = math.sqrt(dx * dx + dy * dy);
          if (distance > brushRadius) {
            continue;
          }

          final pixel = surface.getPixel(x, y);
          if (boundary.contains(pixel)) {
            continue;
          }

          surface.setPixel(x, y, fillArgb);
        }
      }
    }
  }
}
