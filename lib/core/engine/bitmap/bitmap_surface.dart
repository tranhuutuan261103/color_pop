import 'dart:typed_data';
import 'dart:ui';

import 'bitmap_buffer.dart';
import 'dirty_region.dart';

/// BitmapSurface quản lý dữ liệu bitmap của một layer.
///
/// Surface không biết gì về UI.
/// Nó chỉ quản lý:
///
/// - Pixel Buffer
/// - Dirty Region
/// - Version
///
/// Renderer sẽ đọc Surface để tạo ui.Image.
class BitmapSurface {
  BitmapSurface({
    required this.buffer,
  });

  /// Buffer chứa toàn bộ pixel.
  final BitmapBuffer buffer;

  /// Theo dõi vùng thay đổi.
  final DirtyRegion dirtyRegion = DirtyRegion();

  /// Version của bitmap.
  ///
  /// Mỗi lần pixel thay đổi sẽ tăng lên.
  int _version = 0;

  int get version => _version;

  int get width => buffer.width;

  int get height => buffer.height;

  Uint32List get pixels => buffer.pixels;

  bool get hasDirtyRegion => dirtyRegion.isDirty;

  Rect? get dirtyBounds => dirtyRegion.bounds;

  //---------------------------------------------------------------------------
  // Read
  //---------------------------------------------------------------------------

  int getPixel(int x, int y) {
    return buffer.getPixel(x, y);
  }

  int? tryGetPixel(int x, int y) {
    return buffer.tryGetPixel(x, y);
  }

  //---------------------------------------------------------------------------
  // Write
  //---------------------------------------------------------------------------

  bool setPixel(
    int x,
    int y,
    int argb,
  ) {
    if (!buffer.contains(x, y)) {
      return false;
    }

    final index = buffer.toIndex(x, y);

    if (buffer.pixels[index] == argb) {
      return false;
    }

    buffer.pixels[index] = argb;

    dirtyRegion.markPixel(x, y);

    _version++;

    return true;
  }

  bool setPixelByIndex(
    int index,
    int argb,
  ) {
    if (index < 0 || index >= buffer.length) {
      return false;
    }

    if (buffer.pixels[index] == argb) {
      return false;
    }

    buffer.pixels[index] = argb;

    dirtyRegion.markPixel(
      buffer.xFromIndex(index),
      buffer.yFromIndex(index),
    );

    _version++;

    return true;
  }

  int setPixels(
    Iterable<int> indexes,
    int argb,
  ) {
    int changed = 0;

    for (final index in indexes) {
      if (setPixelByIndex(index, argb)) {
        changed++;
      }
    }

    return changed;
  }

  //---------------------------------------------------------------------------
  // Fill
  //---------------------------------------------------------------------------

  void fill(int argb) {
    buffer.fill(argb);

    dirtyRegion.markRect(
      Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        height.toDouble(),
      ),
    );

    _version++;
  }

  void clear() {
    fill(0x00000000);
  }

  //---------------------------------------------------------------------------
  // Dirty Region
  //---------------------------------------------------------------------------

  void markDirty(Rect rect) {
    dirtyRegion.markRect(rect);
  }

  void clearDirtyRegion() {
    dirtyRegion.clear();
  }

  //---------------------------------------------------------------------------
  // Clone
  //---------------------------------------------------------------------------

  BitmapSurface clone() {
    return BitmapSurface(
      buffer: buffer.clone(),
    ).._version = _version;
  }

  @override
  String toString() {
    return '''
BitmapSurface(
  size: ${width}x$height,
  version: $_version,
  dirty: ${dirtyRegion.isDirty}
)
''';
  }
}