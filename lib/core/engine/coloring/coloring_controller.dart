import 'dart:ui';

import '../bitmap/bitmap_stack.dart';
import '../brush/brush_engine.dart';
import '../flood_fill/flood_fill_engine.dart';

/// Shared coloring controller for both brush and fill features.
///
/// File này phục vụ cả 2 tính năng tô màu: brush và fill.
///
/// File này phục vụ cả 2 tính năng tô màu: brush và fill.
class ColoringController {
  ColoringController({
    FloodFillEngine? floodFillEngine,
    BrushEngine? brushEngine,
  }) : _floodFillEngine = floodFillEngine ?? const FloodFillEngine(),
       _brushEngine = brushEngine ?? const BrushEngine();

  final FloodFillEngine _floodFillEngine;
  final BrushEngine _brushEngine;

  BitmapStack? _stack;

  BitmapStack? get stack => _stack;

  void attachStack(BitmapStack stack) {
    _stack = stack;
  }

  void detachStack() {
    _stack = null;
  }

  bool fillAt({
    required int x,
    required int y,
    required Color color,
    int? tolerance,
  }) {
    final stack = _stack;
    if (stack == null) {
      return false;
    }

    final layer = stack.activeLayer;
    if (layer == null || !layer.editable) {
      return false;
    }

    final surface = layer.surface;
    final fillArgb = color.toARGB32();
    final targetColor = surface.tryGetPixel(x, y);

    if (targetColor == null || targetColor == fillArgb) {
      return false;
    }

    _floodFillEngine.fillRegion(
      surface: surface,
      startX: x,
      startY: y,
      fillArgb: fillArgb,
      boundaryColors: {0xFF000000},
    );

    layer.invalidateCache();
    return true;
  }

  bool paintBrush({
    required List<Offset> points,
    required Color color,
    double radius = 2.0,
  }) {
    final stack = _stack;
    if (stack == null) {
      return false;
    }

    final layer = stack.activeLayer;
    if (layer == null || !layer.editable) {
      return false;
    }

    _brushEngine.paintStroke(
      surface: layer.surface,
      points: points,
      fillArgb: color.toARGB32(),
      radius: radius,
      boundaryColors: {0xFF000000},
    );

    layer.invalidateCache();
    return true;
  }

  void clear() {
    _stack?.clearEditableLayers();
  }
}
