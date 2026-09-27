// File loop.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa một đường viền vòng lặp khép kín (Loop / Contour).
// Được sử dụng làm ranh giới bao ngoài (Outer boundary) hoặc đường rỗng bên trong (Hole) của một Region.

import '../geometry/path_command.dart';
import '../geometry/bounding_box.dart';

/// Đại diện cho một tập hợp các đường viền đóng kín (vòng lặp).
/// Có thể dùng làm outer boundary hoặc hole.
class Loop {
  // ID định danh duy nhất của đường vòng này
  final int id;

  // Đường đi hình học chi tiết chứa các lệnh vẽ (Line, Curve, Bezier...)
  final GeometryPath path;

  // Khung chữ nhật bao quanh riêng cho vòng lặp này, dùng để tối ưu tính toán không gian
  final BoundingBox bounds;

  const Loop({
    required this.id,
    required this.path,
    required this.bounds,
  });
}