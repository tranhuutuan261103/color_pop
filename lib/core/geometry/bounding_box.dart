// File bounding_box.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa khung chữ nhật bao quanh (Axis-Aligned Bounding Box - AABB).
// Dùng để cache ranh giới không gian cho Loop, Region và Spatial Index, giúp tối ưu hiệu năng culling và hit-testing.

import 'point.dart';

/// Khung chữ nhật giới hạn vị trí không gian của một đối tượng hình học
class BoundingBox {
  /// Tọa độ trục hoành nhỏ nhất (Cạnh trái)
  final double minX;

  /// Tọa độ trục tung nhỏ nhất (Cạnh trên)
  final double minY;

  /// Tọa độ trục hoành lớn nhất (Cạnh phải)
  final double maxX;

  /// Tọa độ trục tung lớn nhất (Cạnh dưới)
  final double maxY;

  const BoundingBox({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  /// Factory tính toán và tạo BoundingBox nhỏ nhất bao trọn một danh sách các điểm [points]
  factory BoundingBox.fromPoints(List<Point> points) {
    if (points.isEmpty) {
      return const BoundingBox(minX: 0, minY: 0, maxX: 0, maxY: 0);
    }
    
    double minX = points.first.x;
    double minY = points.first.y;
    double maxX = points.first.x;
    double maxY = points.first.y;

    // Duyệt qua tất cả các điểm để quét tìm cực trị min/max
    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return BoundingBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  /// Chiều rộng logic của khung
  double get width => maxX - minX;

  /// Chiều cao logic của khung
  double get height => maxY - minY;
  
  /// Kiểm tra nhanh tọa độ một [point] có nằm bên trong khung này hay không (Check O(1) phục vụ hit test)
  bool contains(Point point) {
    return point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY;
  }

  /// Tạo BoundingBox mở rộng thêm một khoảng [margin] về 4 phía
  BoundingBox expand(double margin) {
    return BoundingBox(
      minX: minX - margin,
      minY: minY - margin,
      maxX: maxX + margin,
      maxY: maxY + margin,
    );
  }
  
  /// Kiểm tra khung này có va chạm / đè lên một BoundingBox [other] khác hay không (Dùng cho Viewport Culling)
  bool intersects(BoundingBox other) {
    return !(maxX < other.minX || minX > other.maxX || maxY < other.minY || minY > other.maxY);
  }

  /// Kiểm tra tính hợp lệ về mặt dữ liệu hình học (Không chứa số vô cùng, số hỏng NaN và min <= max)
  bool isValid() {
    if (minX.isNaN || minY.isNaN || maxX.isNaN || maxY.isNaN) return false;
    if (minX.isInfinite || minY.isInfinite || maxX.isInfinite || maxY.isInfinite) return false;
    return minX <= maxX && minY <= maxY;
  }
}