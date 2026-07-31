import 'dart:collection';

import '../bitmap/bitmap_surface.dart';

/// Fill-only coloring engine.
///
/// File này phục vụ tính năng fill: tô theo vùng liên thông.
///
/// Thuật toán flood fill dùng cho việc tô vùng trong coloring engine.
///
/// Mục tiêu là chỉ tô các pixel kết nối với điểm bắt đầu và bị giới hạn bởi
/// các đường viền / pixel không thể đi qua.
class FloodFillEngine {
  const FloodFillEngine();

  /// Tô một vùng kết nối bắt đầu từ [startX], [startY] thành [fillArgb].
  ///
  /// Mặc định, vùng tô được xác định bởi các pixel có cùng màu với pixel bắt đầu
  /// và không bị chặn bởi các pixel có màu khác (ví dụ đường viền đen).
  void fillRegion({
    required BitmapSurface surface,
    required int startX,
    required int startY,
    required int fillArgb,
    Set<int>? boundaryColors,
  }) {
    if (!surface.buffer.contains(startX, startY)) {
      return;
    }

    final targetColor = surface.getPixel(startX, startY);

    if (targetColor == fillArgb) {
      return;
    }

    final boundary = boundaryColors ?? const <int>{0xFF000000};

    final queue = Queue<_Point>();
    queue.add(_Point(startX, startY));
    final visited = <int>{};

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final index = point.y * surface.width + point.x;

      if (!visited.add(index)) {
        continue;
      }

      final pixel = surface.getPixel(point.x, point.y);

      if (!_shouldFill(pixel, targetColor, fillArgb, boundary)) {
        continue;
      }

      surface.setPixel(point.x, point.y, fillArgb);

      if (point.x > 0) {
        queue.add(_Point(point.x - 1, point.y));
      }
      if (point.x + 1 < surface.width) {
        queue.add(_Point(point.x + 1, point.y));
      }
      if (point.y > 0) {
        queue.add(_Point(point.x, point.y - 1));
      }
      if (point.y + 1 < surface.height) {
        queue.add(_Point(point.x, point.y + 1));
      }
    }
  }

  bool _shouldFill(
    int pixel,
    int targetColor,
    int fillArgb,
    Set<int> boundaryColors,
  ) {
    if (pixel == fillArgb) {
      return false;
    }

    if (pixel != targetColor) {
      return false;
    }

    if (boundaryColors.contains(pixel)) {
      return false;
    }

    return true;
  }
}

class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;
}
