import 'dart:ui' as ui;

/// Cache kết quả render của một BitmapLayer.
///
/// BitmapRenderer sẽ sử dụng cache này để tránh render lại
/// nếu bitmap chưa thay đổi.
class BitmapCache {
  /// ui.Image đã render.
  ui.Image? image;

  /// Version của BitmapSurface khi render.
  int version = -1;

  /// Lần render cuối.
  DateTime? lastRenderTime;

  /// Có cache hợp lệ hay không.
  bool get isValid => image != null;

  /// Đánh dấu cache lỗi thời.
  void invalidate() {
    version = -1;
  }

  /// Xóa cache.
  Future<void> clear() async {
    image?.dispose();
    image = null;
    version = -1;
    lastRenderTime = null;
  }

  /// Lưu cache mới.
  void update({
    required ui.Image image,
    required int version,
  }) {
    this.image?.dispose();

    this.image = image;
    this.version = version;
    lastRenderTime = DateTime.now();
  }

  /// Kiểm tra cache có còn dùng được không.
  bool matchesVersion(int currentVersion) {
    return image != null && version == currentVersion;
  }

  @override
  String toString() {
    return '''
BitmapCache(
  valid: $isValid,
  version: $version,
  rendered: $lastRenderTime
)
''';
  }
}