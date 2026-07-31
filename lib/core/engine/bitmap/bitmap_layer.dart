import 'dart:ui';

import 'bitmap_cache.dart';
import 'bitmap_layer_type.dart';
import 'bitmap_surface.dart';

/// Một layer trong Bitmap Engine.
///
/// Layer chỉ quản lý trạng thái.
/// Pixel được lưu trong BitmapSurface.
class BitmapLayer {
  BitmapLayer({
    required this.id,
    required this.type,
    required this.surface,
    bool? visible,
    bool? locked,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
  })  : visible = visible ?? type.visibleByDefault,
        locked = locked ?? !type.editable;

  /// ID duy nhất.
  final int id;

  /// Loại layer.
  final BitmapLayerType type;

  /// Bitmap của layer.
  final BitmapSurface surface;

  /// Cache render.
  final BitmapCache cache = BitmapCache();

  /// Có hiển thị hay không.
  bool visible;

  /// Có cho phép chỉnh sửa không.
  bool locked;

  /// Độ trong suốt.
  double opacity;

  /// Chế độ hòa trộn.
  BlendMode blendMode;

  int get width => surface.width;

  int get height => surface.height;

  String get name => type.displayName;

  bool get editable => type.editable && !locked;

  int get zIndex => type.zIndex;

  /// Cache còn hợp lệ.
  bool get hasValidCache =>
      cache.matchesVersion(surface.version);

  void toggleVisible() {
    visible = !visible;
  }

  void toggleLocked() {
    locked = !locked;
  }

  void setOpacity(double value) {
    opacity = value.clamp(0.0, 1.0);
  }

  void setBlendMode(BlendMode mode) {
    blendMode = mode;
  }

  /// Xóa bitmap của layer.
  void clear() {
    if (!editable) return;

    surface.clear();

    cache.invalidate();
  }

  /// Đánh dấu cần render lại.
  void invalidateCache() {
    cache.invalidate();
  }

  /// Clone layer.
  ///
  /// Không clone cache vì cache sẽ được render lại.
  BitmapLayer clone({
    int? id,
    BitmapLayerType? type,
  }) {
    return BitmapLayer(
      id: id ?? this.id,
      type: type ?? this.type,
      surface: surface.clone(),
      visible: visible,
      locked: locked,
      opacity: opacity,
      blendMode: blendMode,
    );
  }

  @override
  String toString() {
    return '''
BitmapLayer(
  id: $id,
  type: ${type.displayName},
  size: ${width}x$height,
  visible: $visible,
  locked: $locked,
  opacity: $opacity,
  blendMode: $blendMode,
  version: ${surface.version},
  cache: ${cache.isValid}
)
''';
  }
}