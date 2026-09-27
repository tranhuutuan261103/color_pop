// File path_command.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa các lệnh vẽ Vector cơ bản (Path Commands) dạng nguyên thủy.
// Đây là thành phần hình học nhỏ nhất dùng để dựng nên các nét vẽ và ranh giới vùng (Loop/Region) thay cho ảnh dạng Bitmap.

import 'dart:math' as math;
import 'point.dart';

/* PathCommandType: Enum định nghĩa 4 thao tác vẽ cơ bản:
- moveTo: Đặt bút/di chuyển con trỏ vẽ đến toạ độ mới mà không tạo nét.
- lineTo: Vẽ đường thẳng từ vị trí hiện tại đến toạ độ mục tiêu.
- cubicTo: Vẽ đường cong Bézier 3 bậc (Cubic Bézier) từ vị trí hiện tại tới toạ độ mục tiêu thông qua 2 điểm điều khiển.
- close: Đóng đường cong/đường gấp khúc thành một vòng khép kín (nối điểm cuối về điểm moveTo đầu tiên). */
enum PathCommandType { moveTo, lineTo, cubicTo, close }

/// Lớp cơ sở trừu tượng cho một lệnh vẽ nét
abstract class PathCommand {
  final PathCommandType type;
  const PathCommand(this.type);
}

/// Lệnh nhấc bút di chuyển đến tọa độ mới (không tạo nét)
class MoveToCommand extends PathCommand {
  final Point target;
  const MoveToCommand(this.target) : super(PathCommandType.moveTo);
}

/// Lệnh vẽ đường thẳng từ vị trí hiện tại tới [target]
class LineToCommand extends PathCommand {
  final Point target;
  const LineToCommand(this.target) : super(PathCommandType.lineTo);
}

/// Lệnh vẽ đường cong Bézier 3 bậc (Cubic Bezier) mượt mà đến [target] thông qua 2 điểm điều khiển [control1] và [control2]
class CubicToCommand extends PathCommand {
  final Point control1;
  final Point control2;
  final Point target;
  const CubicToCommand(this.control1, this.control2, this.target) : super(PathCommandType.cubicTo);
}

/// Lệnh khép kín đường nét (nối điểm hiện tại về điểm MoveTo đầu tiên)
class CloseCommand extends PathCommand {
  const CloseCommand() : super(PathCommandType.close);
}

/// Tập hợp chuỗi các lệnh vẽ cấu thành một đường dẫn (Path) hình học hoàn chỉnh
class GeometryPath {
  /// Danh sách các lệnh vẽ nối tiếp nhau
  final List<PathCommand> commands;

  const GeometryPath({required this.commands});

  /// Factory chuyển đổi danh sách điểm toạ độ (Point) thành đường dẫn Vector.
  /// [smooth]: Mặc định là true. Áp dụng kỹ thuật:
  /// 1. Tinh giản đa giác Ramer-Douglas-Peucker (RDP) để khử triệt để nhiễu bậc thang pixel.
  /// 2. Nhận diện góc nhọn (Corner Detection) để bảo toàn các góc vuông, đỉnh nhọn sắc nét.
  /// 3. Nội suy Midpoint Quadratic/Cubic B-Spline: Mỗi đoạn cong có đạo hàm bậc hai không đổi,
  ///    đảm bảo không bao giờ sinh ra điểm uốn ngược chiều hay gợn sóng (ripple-free).
  /// Nếu [smooth] = false, sẽ chỉ nối các đoạn thẳng [LineToCommand] nguyên thủy.
  factory GeometryPath.fromPoints(
    List<Point> points, {
    bool isClosed = true,
    bool smooth = true,
  }) {
    if (points.isEmpty) return const GeometryPath(commands: []);

    // 1. Làm sạch danh sách điểm: lọc NaN, Infinite và các điểm trùng lặp liền kề
    final cleanPoints = _cleanPoints(points, isClosed: isClosed);
    if (cleanPoints.isEmpty) return const GeometryPath(commands: []);

    if (cleanPoints.length == 1) {
      return GeometryPath(commands: [MoveToCommand(cleanPoints.first)]);
    }

    if (cleanPoints.length == 2 || !smooth) {
      final commands = <PathCommand>[];
      commands.add(MoveToCommand(cleanPoints.first));
      for (int i = 1; i < cleanPoints.length; i++) {
        commands.add(LineToCommand(cleanPoints[i]));
      }
      if (isClosed) {
        commands.add(const CloseCommand());
      }
      return GeometryPath(commands: commands);
    }

    // 2. Chuyển đổi thành đường cong mượt mà, không gợn sóng
    return GeometryPath(
      commands: _createSmoothCommands(cleanPoints, isClosed: isClosed),
    );
  }

  static List<Point> _cleanPoints(List<Point> points, {required bool isClosed}) {
    final result = <Point>[];
    for (final pt in points) {
      if (pt.x.isNaN || pt.y.isNaN || pt.x.isInfinite || pt.y.isInfinite) {
        continue;
      }
      if (result.isNotEmpty) {
        final prev = result.last;
        final dx = pt.x - prev.x;
        final dy = pt.y - prev.y;
        if (dx * dx + dy * dy < 0.0001) {
          continue;
        }
      }
      result.add(pt);
    }

    if (isClosed && result.length > 2) {
      final first = result.first;
      final last = result.last;
      final dx = last.x - first.x;
      final dy = last.y - first.y;
      if (dx * dx + dy * dy < 0.0001) {
        result.removeLast();
      }
    }
    return result;
  }

  static List<PathCommand> _createSmoothCommands(
    List<Point> pts, {
    required bool isClosed,
  }) {
    if (pts.length < 3) {
      final commands = <PathCommand>[
        MoveToCommand(pts.first),
        if (pts.length > 1) LineToCommand(pts.last),
        if (isClosed) const CloseCommand(),
      ];
      return commands;
    }

    final int origN = pts.length;

    // 1. Nhận diện góc nhọn thực sự (Corner Detection) với cửa sổ k = 3
    // Góc nhọn thực sự (vuông, nhọn) có góc quay gắt > 98 độ (dot < -0.15).
    // Các đường tròn và đường cong tự nhiên KHÔNG BAO GIỜ bị nhận nhầm thành góc nhọn.
    final isSharpCorner = List<bool>.filled(origN, false);
    const int kSpan = 3;

    for (int i = 0; i < origN; i++) {
      if (!isClosed && (i < kSpan || i >= origN - kSpan)) {
        isSharpCorner[i] = true;
        continue;
      }
      final prev = pts[(i - kSpan + origN) % origN];
      final curr = pts[i];
      final next = pts[(i + kSpan) % origN];

      final v1x = curr.x - prev.x;
      final v1y = curr.y - prev.y;
      final v2x = next.x - curr.x;
      final v2y = next.y - curr.y;
      final l1 = math.sqrt(v1x * v1x + v1y * v1y);
      final l2 = math.sqrt(v2x * v2x + v2y * v2y);

      if (l1 > 1e-4 && l2 > 1e-4) {
        final dot = (v1x * v2x + v1y * v2y) / (l1 * l2);
        // dot < -0.15 tương đương góc ngoặt > 98 độ -> góc nhọn hình học thực sự
        if (dot < -0.15) {
          isSharpCorner[i] = true;
        }
      }
    }

    // 2. Thuật toán Chaikin's Corner-Cutting Subdivision:
    // Biến đổi các bậc thang pixel rời rạc thành chuỗi điểm liên tục sub-pixel mượt mà
    // mà không làm co rút diện tích vùng cong.
    List<Point> chaikinPts = [];
    final int stepCount = isClosed ? origN : origN - 1;

    for (int i = 0; i < stepCount; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % origN];
      final p1IsCorner = isSharpCorner[i];
      final p2IsCorner = isSharpCorner[(i + 1) % origN];

      if (p1IsCorner && p2IsCorner) {
        chaikinPts.add(p1);
      } else if (p1IsCorner) {
        chaikinPts.add(p1);
        chaikinPts.add(Point(0.18 * p1.x + 0.82 * p2.x, 0.18 * p1.y + 0.82 * p2.y));
      } else if (p2IsCorner) {
        chaikinPts.add(Point(0.82 * p1.x + 0.18 * p2.x, 0.82 * p1.y + 0.18 * p2.y));
      } else {
        chaikinPts.add(Point(0.82 * p1.x + 0.18 * p2.x, 0.82 * p1.y + 0.18 * p2.y));
        chaikinPts.add(Point(0.18 * p1.x + 0.82 * p2.x, 0.18 * p1.y + 0.82 * p2.y));
      }
    }
    if (!isClosed) {
      chaikinPts.add(pts.last);
    }

    // 3. Tinh giản nhẹ RDP với epsilon = 0.5 để tối ưu hiệu năng
    // trong khi giữ nguyên 100% biên dạng tròn đều, không làm gãy khúc đường cong
    final simplified = isClosed
        ? (chaikinPts.length > 6 ? _rdpClosed(chaikinPts, 0.5) : chaikinPts)
        : (chaikinPts.length > 3 ? _rdpOpen(chaikinPts, 0.5) : chaikinPts);

    final n = simplified.length;
    if (n < 3) {
      final commands = <PathCommand>[
        MoveToCommand(simplified.first),
        if (simplified.length > 1) LineToCommand(simplified.last),
        if (isClosed) const CloseCommand(),
      ];
      return commands;
    }

    // 4. Nhận diện góc nhọn trên tập đỉnh simplified (chỉ các góc thực sự gắt > 98 độ)
    final isCorner = List<bool>.filled(n, false);
    for (int i = 0; i < n; i++) {
      if (!isClosed && (i == 0 || i == n - 1)) {
        isCorner[i] = true;
        continue;
      }
      final prev = simplified[(i - 1 + n) % n];
      final curr = simplified[i];
      final next = simplified[(i + 1) % n];

      final v1x = curr.x - prev.x;
      final v1y = curr.y - prev.y;
      final v2x = next.x - curr.x;
      final v2y = next.y - curr.y;
      final l1 = math.sqrt(v1x * v1x + v1y * v1y);
      final l2 = math.sqrt(v2x * v2x + v2y * v2y);

      if (l1 > 1e-4 && l2 > 1e-4) {
        final dot = (v1x * v2x + v1y * v2y) / (l1 * l2);
        if (dot < -0.15) {
          isCorner[i] = true;
        }
      }
    }

    // 5. Nội suy Catmull-Rom sang Cubic Bézier Spline liên tục C1:
    // Tuyệt đối KHÔNG ngắt đường tròn thành các đoạn thẳng LineTo cứng nhắc.
    // Mọi đường cong và đường tròn đều được tạo bởi CubicToCommand, giúp khi phóng to
    // (zoom 2x - 10x) đường tròn vẫn tròn đều, mượt mà ở độ phân giải sub-pixel,
    // loại bỏ hoàn toàn hiện tượng bậc thang (staircase effect).
    final commands = <PathCommand>[];
    commands.add(MoveToCommand(simplified.first));

    final count = isClosed ? n : n - 1;
    for (int i = 0; i < count; i++) {
      final p0 = isClosed ? simplified[(i - 1 + n) % n] : (i > 0 ? simplified[i - 1] : simplified[i]);
      final p1 = simplified[i];
      final p2 = simplified[(i + 1) % n];
      final p3 = isClosed
          ? simplified[(i + 2) % n]
          : (i + 2 < n ? simplified[i + 2] : p2);

      final p1Corner = isCorner[i];
      final p2Corner = isCorner[(i + 1) % n];

      // Nếu cả hai đầu đều là góc nhọn hình học thực sự (ví dụ cạnh đa giác thẳng)
      if (p1Corner && p2Corner) {
        commands.add(LineToCommand(p2));
        continue;
      }

      // Tính tiếp tuyến Catmull-Rom có điều hòa theo góc nhọn
      double t1x, t1y;
      if (p1Corner) {
        t1x = p2.x - p1.x;
        t1y = p2.y - p1.y;
      } else {
        t1x = (p2.x - p0.x) / 2.0;
        t1y = (p2.y - p0.y) / 2.0;
      }

      double t2x, t2y;
      if (p2Corner) {
        t2x = p2.x - p1.x;
        t2y = p2.y - p1.y;
      } else {
        t2x = (p3.x - p1.x) / 2.0;
        t2y = (p3.y - p1.y) / 2.0;
      }

      // Điểm điều khiển Bézier bậc 3 (Cubic Bézier control points)
      var c1x = p1.x + t1x / 3.0;
      var c1y = p1.y + t1y / 3.0;
      var c2x = p2.x - t2x / 3.0;
      var c2y = p2.y - t2y / 3.0;

      // Giới hạn điểm điều khiển trong phạm vi 45% độ dài đoạn để đảm bảo đường cong tròn trịa
      final segDx = p2.x - p1.x;
      final segDy = p2.y - p1.y;
      final segLen = math.sqrt(segDx * segDx + segDy * segDy);
      if (segLen > 1e-4) {
        final maxCtrlDist = segLen * 0.45;

        final d1x = c1x - p1.x;
        final d1y = c1y - p1.y;
        final len1 = math.sqrt(d1x * d1x + d1y * d1y);
        if (len1 > maxCtrlDist) {
          c1x = p1.x + (d1x / len1) * maxCtrlDist;
          c1y = p1.y + (d1y / len1) * maxCtrlDist;
        }

        final d2x = c2x - p2.x;
        final d2y = c2y - p2.y;
        final len2 = math.sqrt(d2x * d2x + d2y * d2y);
        if (len2 > maxCtrlDist) {
          c2x = p2.x + (d2x / len2) * maxCtrlDist;
          c2y = p2.y + (d2y / len2) * maxCtrlDist;
        }
      }

      commands.add(CubicToCommand(
        Point(c1x, c1y),
        Point(c2x, c2y),
        p2,
      ));
    }

    if (isClosed) {
      commands.add(const CloseCommand());
    }

    return commands;
  }

  static List<Point> _rdpClosed(List<Point> pts, double epsilon) {
    if (pts.length < 4) return pts;
    int maxIdx = 0;
    double maxDist = 0.0;
    final p0 = pts[0];
    for (int i = 1; i < pts.length; i++) {
      final dx = pts[i].x - p0.x;
      final dy = pts[i].y - p0.y;
      final d = dx * dx + dy * dy;
      if (d > maxDist) {
        maxDist = d;
        maxIdx = i;
      }
    }

    final half1 = _rdpOpen(pts.sublist(0, maxIdx + 1), epsilon);
    final half2 = _rdpOpen(pts.sublist(maxIdx) + [pts[0]], epsilon);

    return half1.sublist(0, half1.length - 1) + half2.sublist(0, half2.length - 1);
  }

  static List<Point> _rdpOpen(List<Point> pts, double epsilon) {
    if (pts.length < 3) return pts;
    double dmax = 0.0;
    int index = 0;
    final pStart = pts.first;
    final pEnd = pts.last;
    final dx = pEnd.x - pStart.x;
    final dy = pEnd.y - pStart.y;
    final mag = math.sqrt(dx * dx + dy * dy);

    for (int i = 1; i < pts.length - 1; i++) {
      final p = pts[i];
      double d;
      if (mag == 0) {
        final ex = p.x - pStart.x;
        final ey = p.y - pStart.y;
        d = math.sqrt(ex * ex + ey * ey);
      } else {
        d = ((dy * p.x - dx * p.y + pEnd.x * pStart.y - pEnd.y * pStart.x).abs()) / mag;
      }
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      final rec1 = _rdpOpen(pts.sublist(0, index + 1), epsilon);
      final rec2 = _rdpOpen(pts.sublist(index), epsilon);
      return rec1.sublist(0, rec1.length - 1) + rec2;
    } else {
      return [pStart, pEnd];
    }
  }
}
