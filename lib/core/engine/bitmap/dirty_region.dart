import 'dart:ui';

class DirtyRegion {
  Rect? _bounds;

  Rect? get bounds => _bounds;

  bool get isDirty => _bounds != null;

  void markPixel(int x, int y) {
    markRect(Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      1,
      1,
    ));
  }

  void markRect(Rect rect) {
    if (_bounds == null) {
      _bounds = rect;
    } else {
      _bounds = _bounds!.expandToInclude(rect);
    }
  }

  void clear() {
    _bounds = null;
  }
}