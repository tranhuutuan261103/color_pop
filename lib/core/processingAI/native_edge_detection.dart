// File native_edge_detection.dart

import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class NativeEdgeDetection {
  /// Áp dụng bộ lọc Sobel để trích xuất viền.
  /// Phù hợp cho ảnh chụp thật: trích ra các cạnh mạnh nhất của vật thể.
  static Future<Uint8List?> applySobel(Uint8List imageBytes) async {
    return compute(_sobelComputeNative, imageBytes);
  }

  /// Áp dụng bộ lọc Canny để trích xuất viền.
  /// Tốt nhất cho ảnh chụp thật: chỉ lấy đường biên vật thể, bỏ qua vùng tối/bóng.
  static Future<Uint8List?> applyCanny(Uint8List imageBytes) async {
    return compute(_cannyComputeNative, imageBytes);
  }

  /// Áp dụng thuật toán "Nét vẽ tự nhiên" (Sketch).
  /// Tốt nhất cho ảnh vẽ tay/scan sách tô màu: giữ nét đậm nhạt tự nhiên.
  static Future<Uint8List?> applySketch(Uint8List imageBytes) async {
    return compute(_sketchComputeNative, imageBytes);
  }

  // =========================================================================
  // SOBEL - Cải tiến: Blur mạnh + Ngưỡng cao + Xóa nhiễu
  // =========================================================================
  static Uint8List? _sobelComputeNative(Uint8List bytes) {
    try {
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) return null;
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // 1. Blur MẠNH (kernel 7): xóa texture bề mặt (vân da, vải, cỏ...)
      //    Chỉ giữ lại sự thay đổi cường độ sáng lớn (viền vật thể)
      final blurred = cv.medianBlur(gray, 7);

      // 2. Tính gradient Sobel theo 2 hướng
      final gradX = cv.sobel(blurred, cv.MatType.CV_16S, 1, 0, ksize: 3);
      final gradY = cv.sobel(blurred, cv.MatType.CV_16S, 0, 1, ksize: 3);
      final absGradX = cv.convertScaleAbs(gradX);
      final absGradY = cv.convertScaleAbs(gradY);
      final sobel = cv.addWeighted(absGradX, 0.5, absGradY, 0.5, 0);

      // 3. Ngưỡng CAO (100 thay vì 50): chỉ giữ cạnh thật sự mạnh
      //    Gradient yếu từ bóng đổ, chuyển màu nhẹ sẽ bị loại bỏ
      final thresholded = cv.threshold(sobel, 100, 255, cv.THRESH_BINARY);

      // 4. MORPH_OPEN: ăn mòn rồi giãn nở → xóa sạch các đốm nhiễu nhỏ lẻ
      //    mà không ảnh hưởng đến các đường viền chính
      final openKernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
      final cleaned = cv.morphologyEx(thresholded.$2, cv.MORPH_OPEN, openKernel);

      // 5. Đảo màu → Nền TRẮNG, Viền ĐEN (chuẩn đầu vào cho Engine)
      final inverted = cv.bitwiseNOT(cleaned);

      final encoded = cv.imencode('.png', inverted);
      return encoded.$2;
    } catch (e) {
      debugPrint("Error in Native Sobel compute: $e");
      return null;
    }
  }

  // =========================================================================
  // CANNY THỰC SỰ - Dùng cv.canny(), KHÔNG dùng adaptiveThreshold
  // =========================================================================
  static Uint8List? _cannyComputeNative(Uint8List bytes) {
    try {
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) return null;
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // 1. Blur vừa phải (kernel 5): xóa nhiễu nhưng giữ chi tiết hơn
      final blurred = cv.medianBlur(gray, 5);

      // 2. Canny với ngưỡng vừa phải: bắt được nhiều cạnh hơn, ít đứt đoạn
      final edges = cv.canny(blurred, 75, 150);

      // 3. Nối đứt đoạn bằng MORPH_CLOSE (kernel 5×5 lớn hơn trước)
      final closeKernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closedEdges = cv.morphologyEx(edges, cv.MORPH_CLOSE, closeKernel);

      // 4. Làm dày viền vừa phải bằng dilate nhỏ (2×2)
      //    Đủ để người dùng nhìn rõ viền và tô màu không bị lem
      final dilateKernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
      final thickenedEdges = cv.dilate(closedEdges, dilateKernel);

      // 5. Đảo màu → Nền TRẮNG, Viền ĐEN
      final inverted = cv.bitwiseNOT(thickenedEdges);

      final encoded = cv.imencode('.png', inverted);
      return encoded.$2;
    } catch (e) {
      debugPrint("Error in Native Canny compute: $e");
      return null;
    }
  }

  // =========================================================================
  // SKETCH - Giữ nguyên Adaptive Threshold (dành cho ảnh vẽ tay/scan)
  // =========================================================================
  static Uint8List? _sketchComputeNative(Uint8List bytes) {
    try {
      final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) return null;
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // 1. Làm mờ nhẹ bằng Median Blur để khử nhiễu nhỏ
      final blurred = cv.medianBlur(gray, 7);

      // 2. Adaptive Threshold: tốt cho ảnh vẽ tay/scan sách tô màu
      //    (KHÔNG phù hợp cho ảnh chụp thật → dùng Canny/Sobel thay thế)
      final edges = cv.adaptiveThreshold(
        blurred,
        255,
        cv.ADAPTIVE_THRESH_MEAN_C,
        cv.THRESH_BINARY_INV,
        9,
        4,
      );

      // 3. Nối khoảng hở
      final closeKernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closedEdges = cv.morphologyEx(edges, cv.MORPH_CLOSE, closeKernel);

      // 4. Giãn nở nhẹ
      final dilateKernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
      final smoothEdges = cv.dilate(closedEdges, dilateKernel);

      // 5. Đảo màu → Nền TRẮNG, Viền ĐEN
      final inverted = cv.bitwiseNOT(smoothEdges);

      final encoded = cv.imencode('.png', inverted);
      return encoded.$2;
    } catch (e) {
      debugPrint("Error in Native Sketch compute: $e");
      return null;
    }
  }
}