import 'dart:ui';

/// Chứa toàn bộ thông tin cần thiết để render.
///
/// RenderContext không chứa dữ liệu bitmap.
/// Nó chỉ mô tả cách BitmapRenderer sẽ hiển thị bitmap.
class RenderContext {
  const RenderContext({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offset = Offset.zero,
    this.devicePixelRatio = 1.0,
    this.backgroundColor = const Color(0x00000000),
    this.clipRect,
    this.showGrid = false,
    this.antialias = true,
  });

  /// Mức zoom.
  final double scale;

  /// Góc xoay (radian).
  final double rotation;

  /// Dịch chuyển canvas.
  final Offset offset;

  /// Device Pixel Ratio.
  ///
  /// Ví dụ:
  /// Android: 2~3
  /// iPhone: 3
  final double devicePixelRatio;

  /// Màu nền khi render.
  final Color backgroundColor;

  /// Chỉ render vùng này.
  ///
  /// null = render toàn bộ.
  final Rect? clipRect;

  /// Hiển thị lưới.
  final bool showGrid;

  /// Bật Anti Alias.
  final bool antialias;

  /// Có đang zoom không.
  bool get isZoomed => scale != 1.0;

  /// Có đang dịch chuyển không.
  bool get isTranslated => offset != Offset.zero;

  /// Có đang xoay không.
  bool get isRotated => rotation != 0.0;

  /// Có dùng clip không.
  bool get hasClip => clipRect != null;

  /// Tạo bản sao với một số thuộc tính thay đổi.
  RenderContext copyWith({
    double? scale,
    double? rotation,
    Offset? offset,
    double? devicePixelRatio,
    Color? backgroundColor,
    Rect? clipRect,
    bool? showGrid,
    bool? antialias,
  }) {
    return RenderContext(
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offset: offset ?? this.offset,
      devicePixelRatio:
          devicePixelRatio ?? this.devicePixelRatio,
      backgroundColor:
          backgroundColor ?? this.backgroundColor,
      clipRect: clipRect ?? this.clipRect,
      showGrid: showGrid ?? this.showGrid,
      antialias: antialias ?? this.antialias,
    );
  }

  @override
  String toString() {
    return '''
RenderContext(
  scale: $scale,
  rotation: $rotation,
  offset: $offset,
  dpr: $devicePixelRatio,
  clip: $clipRect,
  antialias: $antialias
)
''';
  }
}