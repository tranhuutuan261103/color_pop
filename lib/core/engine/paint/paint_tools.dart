import 'dart:ui';
import 'dart:math';
import '../../models/paint_state.dart';
import '../../models/tool_type.dart';

abstract class PaintTool {
  void onPointerDown(Offset position, int regionId, PaintState state);
  void onPointerMove(Offset position, int regionId, PaintState state);
  void onPointerUp(PaintState state);
}

class FillTool implements PaintTool {
  final Color color;
  FillTool(this.color);

  @override
  void onPointerDown(Offset position, int regionId, PaintState state) {
    // 1. Tô màu nền mới
    state.setRegionColor(regionId, color);
    
    // 2. Xóa sạch các nét cọ/chì cũ trên vùng này để lớp màu mới phẳng hoàn toàn
    state.clearStrokesInRegion(regionId);
  }

  @override
  void onPointerMove(Offset position, int regionId, PaintState state) {}

  @override
  void onPointerUp(PaintState state) {}
}

class EraserTool implements PaintTool {
  final double size;
  List<Offset> _currentPoints = [];
  int? _currentRegionId;

  EraserTool(this.size);

  @override
  void onPointerDown(Offset position, int regionId, PaintState state) {
    _currentPoints = [position];
    _currentRegionId = regionId;
  }

  @override
  void onPointerMove(Offset position, int regionId, PaintState state) {
    if (_currentRegionId == regionId) {
      _currentPoints.add(position);
    }
  }

  @override
  void onPointerUp(PaintState state) {
    if (_currentRegionId != null && _currentPoints.isNotEmpty) {
      state.addStroke(_currentRegionId!, FreehandStroke(
        points: List.from(_currentPoints),
        color: const Color(0x00000000), // Transparent
        size: size,
        type: ToolType.eraser,
      ));
    }
    _currentPoints.clear();
    _currentRegionId = null;
  }
}

class BrushTool implements PaintTool {
  final Color color;
  final double size;
  List<Offset> _currentPoints = [];
  int? _currentRegionId;

  BrushTool(this.color, this.size);

  @override
  void onPointerDown(Offset position, int regionId, PaintState state) {
    _currentPoints = [position];
    _currentRegionId = regionId;
  }

  @override
  void onPointerMove(Offset position, int regionId, PaintState state) {
    if (_currentRegionId == regionId) {
      _currentPoints.add(position);
    }
  }

  @override
  void onPointerUp(PaintState state) {
    if (_currentRegionId != null && _currentPoints.isNotEmpty) {
      state.addStroke(_currentRegionId!, FreehandStroke(
        points: List.from(_currentPoints),
        color: color,
        size: size,
        type: ToolType.brush,
      ));
    }
    _currentPoints.clear();
    _currentRegionId = null;
  }
}

class PencilTool implements PaintTool {
  final Color color;
  final double size;
  List<Offset> _currentPoints = [];
  int? _currentRegionId;

  PencilTool(this.color, this.size);

  @override
  void onPointerDown(Offset position, int regionId, PaintState state) {
    _currentPoints = [position];
    _currentRegionId = regionId;
  }

  @override
  void onPointerMove(Offset position, int regionId, PaintState state) {
    if (_currentRegionId == regionId) {
      _currentPoints.add(position);
    }
  }

  @override
  void onPointerUp(PaintState state) {
    if (_currentRegionId != null && _currentPoints.isNotEmpty) {
      state.addStroke(_currentRegionId!, FreehandStroke(
        points: List.from(_currentPoints),
        color: color,
        size: size * 0.5, // Pencil is usually thinner and harder
        type: ToolType.pencil,
      ));
    }
    _currentPoints.clear();
    _currentRegionId = null;
  }
}

class SprayTool implements PaintTool {
  final Color color;
  final double size;
  List<Offset> _currentPoints = [];
  int? _currentRegionId;
  final Random _random = Random();

  SprayTool(this.color, this.size);

  @override
  void onPointerDown(Offset position, int regionId, PaintState state) {
    _currentPoints = [_generateSprayPoint(position)];
    _currentRegionId = regionId;
  }

  @override
  void onPointerMove(Offset position, int regionId, PaintState state) {
    if (_currentRegionId == regionId) {
      for (int i = 0; i < 5; i++) { // Generate multiple particles per move
        _currentPoints.add(_generateSprayPoint(position));
      }
    }
  }

  @override
  void onPointerUp(PaintState state) {
    if (_currentRegionId != null && _currentPoints.isNotEmpty) {
      state.addStroke(_currentRegionId!, FreehandStroke(
        points: List.from(_currentPoints),
        color: color.withOpacity(0.5), // Spray has lighter opacity
        size: size * 0.2, // Spray particles are small
        type: ToolType.spray,
      ));
    }
    _currentPoints.clear();
    _currentRegionId = null;
  }

  Offset _generateSprayPoint(Offset center) {
    final radius = size * _random.nextDouble();
    final angle = _random.nextDouble() * 2 * pi;
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }
}