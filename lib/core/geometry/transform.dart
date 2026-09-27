// File transform.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa Ma trận biến đổi 2D (2D Affine Transformation Matrix).
// Dùng để thực hiện các phép toán Zoom, Pan, Rotate/Scale lên tọa độ của Point, Path, Loop và Region trên Canvas.

import 'point.dart';

/* Lớp Transform2D đại diện cho một ma trận ma quái 3x3 trong không gian 2D:
      x'    a c tx     x
      y' =  b d ty  *  y
      1     0 0 1      1
  a: Hệ số co giãn theo trục X (Scale X) / Thành phần Cosin khi xoay. Mặc định = 1.0.
  d: Hệ số co giãn theo trục Y (Scale Y) / Thành phần Cosin khi xoay. Mặc định = 1.0.
  b, c: Hệ số biến dạng nghiêng (Shear) / Thành phần Sin khi xoay. Mặc định = 0.0.
  tx, ty: Độ dời vị trí (Translation Offset) theo trục X và Y. Mặc định = 0.0.
      x' = a \cdot x + c \cdot y + tx
      y' = b \cdot x + d \cdot y + ty
*/

/// Lớp xử lý ma trận biến đổi không gian 2D
class Transform2D {
  /// a: Scale X, b: Shear Y, c: Shear X, d: Scale Y
  /// tx: Dịch chuyển X, ty: Dịch chuyển Y
  final double a, b, c, d, tx, ty;

  /// Khởi tạo ma trận đơn vị (Identity Matrix) mặc định (giữ nguyên hình dạng, không biến đổi)
  const Transform2D({
    this.a = 1.0, this.b = 0.0,
    this.c = 0.0, this.d = 1.0,
    this.tx = 0.0, this.ty = 0.0,
  });

  /// Chuyển đổi một điểm [p] sang vị trí tọa độ mới dựa trên ma trận biến đổi hiện tại
  Point transform(Point p) {
    return Point(
      a * p.x + c * p.y + tx,
      b * p.x + d * p.y + ty,
    );
  }

  /// Áp dụng phép phóng to/thu nhỏ theo hệ số [sx] (ngang) và [sy] (dọc)
  Transform2D scale(double sx, double sy) {
    return Transform2D(
      a: a * sx, b: b * sx,
      c: c * sy, d: d * sy,
      tx: tx, ty: ty,
    );
  }

  /// Áp dụng phép dịch chuyển vị trí (Pan Canvas) thêm một khoảng [dx] và [dy]
  Transform2D translate(double dx, double dy) {
    return Transform2D(
      a: a, b: b,
      c: c, d: d,
      tx: tx + dx, ty: ty + dy,
    );
  }
}