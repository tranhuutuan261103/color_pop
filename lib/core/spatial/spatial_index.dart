import 'dart:ui';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/color_pop_document.dart';
import '../topology/region.dart';
import '../geometry/path_command.dart' as geometry;
import '../geometry/point.dart' as pt;
import '../geometry/path_command.dart' as cmd;

class SpatialIndex {
  final ColorPopDocument document;

  // Cache bounds and flutter Paths for fast hit-testing
  final Map<int, Path> _regionPaths = {};
  int _maskWidth = 0;
  int _maskHeight = 0;
  Uint8List? _luminanceMap;

  SpatialIndex(this.document, {Uint8List? boundaryBytes}) {
    _buildIndex();
    if (boundaryBytes != null) {
      final mask = img.decodeImage(boundaryBytes);
      if (mask != null) {
        _maskWidth = mask.width;
        _maskHeight = mask.height;
        final total = _maskWidth * _maskHeight;
        final lumMap = Uint8List(total);
        for (int y = 0; y < _maskHeight; y++) {
          for (int x = 0; x < _maskWidth; x++) {
            final pixel = mask.getPixel(x, y);
            final lum = ((pixel.r * 299 + pixel.g * 587 + pixel.b * 114) / 1000).round();
            lumMap[y * _maskWidth + x] = lum.clamp(0, 255);
          }
        }
        _luminanceMap = lumMap;
      }
    }
  }

  void _buildIndex() {
    for (final region in document.regions) {
      _regionPaths[region.id] = _createRegionPath(region);
    }
  }

  Path _createRegionPath(Region region) {
    final path = Path()..fillType = PathFillType.evenOdd;

    void addGeometryPath(geometry.GeometryPath geometryPath) {
      for (final command in geometryPath.commands) {
        if (command is cmd.MoveToCommand) {
          path.moveTo(command.target.x, command.target.y);
        } else if (command is cmd.LineToCommand) {
          path.lineTo(command.target.x, command.target.y);
        } else if (command is cmd.CubicToCommand) {
          path.cubicTo(
            command.control1.x,
            command.control1.y,
            command.control2.x,
            command.control2.y,
            command.target.x,
            command.target.y,
          );
        } else if (command is cmd.CloseCommand) {
          path.close();
        }
      }
    }

    addGeometryPath(region.outerBoundary.path);
    for (final hole in region.holes) {
      addGeometryPath(hole.path);
    }
    return path;
  }

  Region? getRegionAtPoint(Offset point) {
    final geomPoint = pt.Point(point.dx, point.dy);

    // Reverse iterate so top regions (drawn last) are hit first
    for (final region in document.regions.reversed) {
      if (!region.bounds.contains(geomPoint)) continue;

      final flutterPath = _regionPaths[region.id];
      if (flutterPath != null && flutterPath.contains(point)) {
        return region;
      }
    }
    return null;
  }

  /// Tìm Region gần nhất xung quanh một điểm (hỗ trợ khi chạm ngón tay sát viền)
  Region? getNearestRegion(Offset point, {double maxDistance = 12.0}) {
    final direct = getRegionAtPoint(point);
    if (direct != null && !direct.isStroke) return direct;

    const offsets = [
      Offset(2, 0), Offset(-2, 0), Offset(0, 2), Offset(0, -2),
      Offset(4, 0), Offset(-4, 0), Offset(0, 4), Offset(0, -4),
      Offset(6, 6), Offset(-6, 6), Offset(6, -6), Offset(-6, -6),
      Offset(8, 0), Offset(-8, 0), Offset(0, 8), Offset(0, -8),
      Offset(12, 0), Offset(-12, 0), Offset(0, 12), Offset(0, -12),
    ];

    for (final off in offsets) {
      if (off.distance > maxDistance) continue;
      final candidate = getRegionAtPoint(point + off);
      if (candidate != null && !candidate.isStroke) {
        return candidate;
      }
    }
    return null;
  }

  /// Kiểm tra xem một điểm trong hệ tọa độ document có nằm trên pixel viền đen không
  bool isBlack(Offset point, {int threshold = 75}) {
    if (_luminanceMap == null || _maskWidth == 0 || _maskHeight == 0) {
      return false;
    }
    final x = (point.dx / document.width * _maskWidth).floor().clamp(0, _maskWidth - 1);
    final y = (point.dy / document.height * _maskHeight).floor().clamp(0, _maskHeight - 1);
    return _luminanceMap![y * _maskWidth + x] < threshold;
  }

  /// Kiểm tra xem đoạn kéo từ from đến to có cắt ngang qua bất kỳ pixel viền đen nào không
  bool segmentCrossesLine(Offset from, Offset to, {int threshold = 75}) {
    if (_luminanceMap == null || _maskWidth == 0 || _maskHeight == 0) {
      return false;
    }
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.5) {
      return isBlack(to, threshold: threshold);
    }
    final steps = math.max(1, dist.ceil());
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final px = from.dx + dx * t;
      final py = from.dy + dy * t;
      final x = (px / document.width * _maskWidth).floor().clamp(0, _maskWidth - 1);
      final y = (py / document.height * _maskHeight).floor().clamp(0, _maskHeight - 1);
      if (_luminanceMap![y * _maskWidth + x] < threshold) {
        return true;
      }
    }
    return false;
  }

  /// Tìm điểm an toàn cuối cùng trên đoạn [from -> to] trước khi chạm viền đen hoặc ra ngoài vùng
  Offset? findLastSafePoint(Offset from, Offset to, int regionId) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.5) return from;

    double low = 0.0;
    double high = 1.0;
    Offset lastSafe = from;

    // Binary search 6 bước (độ chính xác ~1/64 của đoạn dịch chuyển)
    for (int step = 0; step < 6; step++) {
      final mid = (low + high) / 2.0;
      final p = Offset(from.dx + dx * mid, from.dy + dy * mid);
      final onBlack = isBlack(p);
      final crossed = segmentCrossesLine(from, p);
      final inside = isInsideRegion(regionId, p, tolerance: 2.0);

      if (!onBlack && !crossed && inside) {
        lastSafe = p;
        low = mid;
      } else {
        high = mid;
      }
    }
    return lastSafe;
  }

  bool isInsideRegion(int regionId, Offset point, {double tolerance = 2.0}) {
    final region = document.regions.where((item) => item.id == regionId);
    if (region.isEmpty) return false;
    final target = region.first;
    final ptX = point.dx;
    final ptY = point.dy;
    if (ptX < target.bounds.minX - tolerance ||
        ptX > target.bounds.maxX + tolerance ||
        ptY < target.bounds.minY - tolerance ||
        ptY > target.bounds.maxY + tolerance) {
      return false;
    }
    final path = _regionPaths[regionId];
    if (path == null) return false;
    if (path.contains(point)) return true;

    // Kiểm tra mẫu lân cận nhỏ với tolerance để tránh rớt điểm do sai số số thực trên biên
    if (tolerance > 0) {
      if (path.contains(Offset(point.dx + tolerance, point.dy)) ||
          path.contains(Offset(point.dx - tolerance, point.dy)) ||
          path.contains(Offset(point.dx, point.dy + tolerance)) ||
          path.contains(Offset(point.dx, point.dy - tolerance))) {
        return true;
      }
    }
    return false;
  }

  // Lấy Path giới hạn làm Clipping Mask cho Lớp Động
  Path? getRegionPath(int regionId) {
    return _regionPaths[regionId];
  }
}
