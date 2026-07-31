import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import 'bitmap_buffer.dart';
import 'bitmap_surface.dart';

/// Chuyển đổi giữa BitmapSurface và các định dạng khác.
///
/// Không render.
/// Không chỉnh sửa bitmap.
class BitmapConverter {
  const BitmapConverter();

  /// Tạo BitmapSurface từ ui.Image.
  Future<BitmapSurface> fromImage(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception('Unable to read image bytes.');
    }

    final rgba = byteData.buffer.asUint8List();

    final pixels = Uint32List(image.width * image.height);

    final rgbaData = ByteData.sublistView(rgba);

    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = rgbaData.getUint32(i * 4, Endian.little);
    }

    return BitmapSurface(
      buffer: BitmapBuffer(
        width: image.width,
        height: image.height,
        pixels: pixels,
      ),
    );
  }

  /// Tạo mask đường viền từ ảnh grayscale.
  ///
  /// Mỗi pixel đen / rất tối sẽ được đánh dấu là outline (1),
  /// các pixel còn lại là vùng có thể tô (0).
  Uint8List buildOutlineMask({
    required img.Image image,
    int threshold = 150,
    int expansion = 1,
  }) {
    final width = image.width;
    final height = image.height;
    final mask = Uint8List(width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = ((pixel.r + pixel.g + pixel.b) / 3).round();

        if (x == 0 || y == 0 || x == width - 1 || y == height - 1) {
          mask[y * width + x] = 1;
          continue;
        }

        if (luminance <= threshold) {
          mask[y * width + x] = 1;
          continue;
        }

        var neighborOutline = false;
        for (var dy = -expansion; dy <= expansion; dy++) {
          for (var dx = -expansion; dx <= expansion; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
              continue;
            }
            final neighbor = image.getPixel(nx, ny);
            final neighborLuminance =
                ((neighbor.r + neighbor.g + neighbor.b) / 3).round();
            if (neighborLuminance <= threshold) {
              neighborOutline = true;
              break;
            }
          }
          if (neighborOutline) break;
        }

        mask[y * width + x] = neighborOutline ? 1 : 0;
      }
    }

    return mask;
  }

  /// Chuyển BitmapSurface thành RGBA bytes.
  Uint8List toRgbaBytes(BitmapSurface surface) {
    return surface.pixels.buffer.asUint8List();
  }

  /// Chuyển BitmapSurface thành Uint32List.
  Uint32List toPixels(BitmapSurface surface) {
    return Uint32List.fromList(surface.pixels);
  }

  /// Clone BitmapSurface.
  BitmapSurface clone(BitmapSurface surface) {
    return surface.clone();
  }

  /// Sao chép bitmap.
  void copy(BitmapSurface source, BitmapSurface destination) {
    if (source.width != destination.width ||
        source.height != destination.height) {
      throw ArgumentError('Source and destination size mismatch.');
    }

    destination.pixels.setAll(0, source.pixels);
    destination.markDirty(
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    );
  }
}
