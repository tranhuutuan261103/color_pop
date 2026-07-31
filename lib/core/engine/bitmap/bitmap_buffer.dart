import 'dart:typed_data';

/// Lưu trữ bitmap dưới dạng ARGB 32-bit.
///
/// Mỗi phần tử trong [pixels] là một màu:
/// 0xAARRGGBB
///
/// Ví dụ:
/// 0xFFFFFFFF = Trắng
/// 0xFF000000 = Đen
/// 0xFFFF0000 = Đỏ
class BitmapBuffer {
  final int width;
  final int height;

  /// Mảng pixel 1 chiều.
  ///
  /// index = y * width + x
  final Uint32List pixels;

  BitmapBuffer({
    required this.width,
    required this.height,
    Uint32List? pixels,
  }) : pixels = pixels ?? Uint32List(width * height);

  /// Tổng số pixel.
  int get length => pixels.length;

  /// Kiểm tra tọa độ hợp lệ.
  bool contains(int x, int y) {
    return x >= 0 &&
        x < width &&
        y >= 0 &&
        y < height;
  }

  /// Chuyển (x,y) -> index.
  int toIndex(int x, int y) {
    return y * width + x;
  }

  /// Chuyển index -> x.
  int xFromIndex(int index) {
    return index % width;
  }

  /// Chuyển index -> y.
  int yFromIndex(int index) {
    return index ~/ width;
  }

  /// Lấy màu tại pixel.
  int getPixel(int x, int y) {
    if (!contains(x, y)) {
      throw RangeError('Pixel ($x,$y) nằm ngoài bitmap.');
    }

    return pixels[toIndex(x, y)];
  }

  /// Ghi màu.
  void setPixel(int x, int y, int argb) {
    if (!contains(x, y)) {
      return;
    }

    pixels[toIndex(x, y)] = argb;
  }

  /// Đọc theo index.
  int getPixelByIndex(int index) {
    return pixels[index];
  }

  /// Ghi theo index.
  void setPixelByIndex(int index, int argb) {
    pixels[index] = argb;
  }

  /// Đổ toàn bộ bitmap thành một màu.
  void fill(int argb) {
    pixels.fillRange(0, pixels.length, argb);
  }

  /// Sao chép bitmap.
  BitmapBuffer clone() {
    return BitmapBuffer(
      width: width,
      height: height,
      pixels: Uint32List.fromList(pixels),
    );
  }

  /// Chỉ copy dữ liệu pixel.
  Uint32List clonePixels() {
    return Uint32List.fromList(pixels);
  }

  /// Xóa bitmap (Transparent).
  void clear() {
    fill(0x00000000);
  }

  /// Đọc pixel nhưng không throw exception.
  int? tryGetPixel(int x, int y) {
    if (!contains(x, y)) return null;
    return pixels[toIndex(x, y)];
  }

  /// Kiểm tra bitmap có rỗng.
  bool get isEmpty => width == 0 || height == 0;

  @override
  String toString() {
    return 'BitmapBuffer(${width}x$height)';
  }
}