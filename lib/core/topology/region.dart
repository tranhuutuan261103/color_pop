// File region.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa cấu trúc hình học (Topology) của một vùng có thể tô màu hoặc một nét vẽ.
// Sử dụng mô hình Outer Boundary + Holes để đại diện cho các hình đa giác phức tạp.

import 'dart:ui';
import '../geometry/bounding_box.dart';
import 'loop.dart';

/// Đại diện cho một vùng màu (Region) được trích xuất từ ảnh gốc.
class Region {
  // ID định danh duy nhất của Region trong Document
  final int id;

  // Đường vòng khép kín định hình ranh giới bên ngoài của vùng
  final Loop outerBoundary;

  // Danh sách các đường vòng bên trong đại diện cho các vùng "rỗng/thủng" (VD: lỗ giữa hình bánh donut)
  final List<Loop> holes;

  // Danh sách ID của các Region tiếp giáp xung quanh (Dùng cho cấu trúc đồ thị / thuật toán loang màu)
  final List<int> neighborIds;

  // Màu sắc hiện tại/mặc định của vùng
  final Color color;

  // Khung chữ nhật bao quanh vùng (AABB), dùng để cache và tối ưu tốc độ tìm kiếm/Hit Test
  final BoundingBox bounds;

  // Mức độ tin cậy của thuật toán trích xuất đối với vùng này (0.0 -> 1.0)
  final double confidence;

  // Đánh dấu xem đây là nét vẽ chi tiết (Stroke) hay là vùng trống cần tô màu (Boundary Region)
  final bool isStroke;

  const Region({
    required this.id,
    required this.outerBoundary,
    required this.holes,
    required this.neighborIds,
    required this.color,
    required this.bounds,
    required this.confidence,
    this.isStroke = false,
  });
}