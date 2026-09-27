// File point.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa đối tượng Điểm (Point 2D) nguyên thủy.
// Là đơn vị cấu thành cơ bản nhất của tất cả các tọa độ nét vẽ, ranh giới hình học và khung giới hạn.

class Point {
  /// Tọa độ trục hoành (X)
  final double x;

  /// Tọa độ trục tung (Y)
  final double y;

  const Point(this.x, this.y);

  /// Phép cộng Vector: Dùng để dịch chuyển tọa độ điểm (Pan/Translate)
  Point operator +(Point other) => Point(x + other.x, y + other.y);

  /// Phép trừ Vector: Dùng để tính khoảng cách/độ lệch offset giữa 2 điểm
  Point operator -(Point other) => Point(x - other.x, y - other.y);

  /// Phép nhân với hệ số: Dùng để phóng to (Scale Up) tọa độ theo tỷ lệ Canvas
  Point operator *(double scalar) => Point(x * scalar, y * scalar);

  /// Phép chia với hệ số: Dùng để thu nhỏ (Scale Down) tọa độ theo tỷ lệ Canvas
  Point operator /(double scalar) => Point(x / scalar, y / scalar);

  /// So sánh giá trị tọa độ x, y thay vì so sánh tham chiếu địa chỉ ô nhớ
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  /// Mã băm duy nhất dựa trên tọa độ x và y (Phục vụ cho Set/Map)
  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Point($x, $y)';
}