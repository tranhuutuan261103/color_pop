import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'bitmap_layer.dart';
import 'bitmap_stack.dart';

Uint8List encodeArgbPixelsToBgra(Uint32List pixels) {
  final bytes = Uint8List(pixels.length * 4);

  for (var i = 0; i < pixels.length; i++) {
    final argb = pixels[i];
    final offset = i * 4;

    bytes[offset] = (argb & 0xFF).toUnsigned(8);
    bytes[offset + 1] = ((argb >> 8) & 0xFF).toUnsigned(8);
    bytes[offset + 2] = ((argb >> 16) & 0xFF).toUnsigned(8);
    bytes[offset + 3] = ((argb >> 24) & 0xFF).toUnsigned(8);
  }

  return bytes;
}

/// Render BitmapSurface thành ui.Image.
///
/// BitmapRenderer chỉ chịu trách nhiệm render.
/// Không thay đổi dữ liệu bitmap.
class BitmapRenderer {
  const BitmapRenderer();

  /// Render một layer.
  Future<ui.Image> renderLayer(BitmapLayer layer) async {
    if (layer.cache.matchesVersion(layer.surface.version)) {
      return layer.cache.image!;
    }

    final image = await _createImage(
      layer.surface.pixels,
      layer.width,
      layer.height,
    );

    layer.cache.update(image: image, version: layer.surface.version);

    layer.surface.clearDirtyRegion();

    return image;
  }

  /// Render nhiều layer.
  ///
  /// Hiện tại chỉ trả về layer đầu tiên.
  /// Sau này sẽ merge bằng Canvas.
  Future<List<ui.Image>> renderLayers(BitmapStack stack) async {
    final images = <ui.Image>[];

    for (final layer in stack.renderLayers) {
      images.add(await renderLayer(layer));
    }

    return images;
  }

  /// Làm mới cache của toàn bộ stack.
  Future<void> invalidate(BitmapStack stack) async {
    for (final layer in stack.layers) {
      await layer.cache.clear();
    }
  }

  //---------------------------------------------------------------------------
  // Private
  //---------------------------------------------------------------------------

  Future<ui.Image> _createImage(
    Uint32List pixels,
    int width,
    int height,
  ) async {
    final bytes = encodeArgbPixelsToBgra(pixels);

    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(bytes),
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.bgra8888,
    );

    final codec = await descriptor.instantiateCodec();

    final frame = await codec.getNextFrame();

    return frame.image;
  }
}
