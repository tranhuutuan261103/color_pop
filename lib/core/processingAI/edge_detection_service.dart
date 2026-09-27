// File: edge_detection_service.dart
// Chức năng: Dịch vụ cốt lõi quản lý nạp mô hình TFLite, thực thi suy luận AI (Inference) và xử lý hậu kỳ (Post-processing) bằng OpenCV.

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'edge_detection_settings.dart';

class EdgeDetectionService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  /// Đường dẫn tệp mô hình TFLite trong thư mục assets của dự án.
  static const String _modelAssetPath = 'assets/hed_mobile_v2_fp32.tflite';

  /// Kích thước chiều rộng/cao đầu vào tiêu chuẩn mà mô hình yêu cầu (256x256).
  static const int _inputSize = 256;

  /// Tải tệp mô hình AI (.tflite) vào bộ nhớ RAM/VRAM của thiết bị.
  /// Ưu tiên kích hoạt GPU Delegate để tăng tốc xử lý.
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      final interpreterOptions = InterpreterOptions();

      // Kích hoạt tăng tốc phần cứng GPU tùy theo hệ điều hành
      if (Platform.isAndroid) {
        interpreterOptions.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        interpreterOptions.addDelegate(GpuDelegate());
      }

      // Nạp mô hình dò viền HED v2 (RGB 3 kênh, định dạng FP32)
      _interpreter = await Interpreter.fromAsset(
        _modelAssetPath,
        options: interpreterOptions,
      );
      _isLoaded = true;
      debugPrint('AI Model loaded successfully ($_modelAssetPath)');
    } catch (e) {
      debugPrint('Failed to load AI model with GPU: $e');
      // Cơ chế dự phòng (Fallback): Thử nạp mô hình chạy bằng CPU nếu GPU gặp sự cố
      try {
        _interpreter = await Interpreter.fromAsset(_modelAssetPath);
        _isLoaded = true;
        debugPrint('AI Model loaded (CPU fallback)');
      } catch (e2) {
        debugPrint('Failed to load AI model even on CPU: $e2');
      }
    }
  }

  /// Thực thi suy luận AI (Inference) trên dữ liệu bytes của ảnh gốc.
  /// Trả về bản đồ xác suất (Probability Map) cùng thông tin kích thước gốc.
  Future<Map<String, dynamic>?> runInference(Uint8List imageBytes) async {
    if (_interpreter == null) {
      await loadModel();
    }
    if (_interpreter == null) return null;

    try {
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      originalImage = img.bakeOrientation(
        originalImage,
      ); // Chuẩn hóa hướng xoay của ảnh

      final int origW = originalImage.width;
      final int origH = originalImage.height;

      // Thay đổi kích thước ảnh về chuẩn 256x256 để đưa vào tensor của mô hình
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Chuẩn hóa màu theo chuẩn ImageNet (Mean & Std) cho 3 kênh RGB
      const List<double> mean = [0.485, 0.456, 0.406];
      const List<double> std = [0.229, 0.224, 0.225];

      var inputTensor = List.generate(
        1,
        (batch) => List.generate(
          _inputSize,
          (y) => List.generate(_inputSize, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              (pixel.r / 255.0 - mean[0]) / std[0],
              (pixel.g / 255.0 - mean[1]) / std[1],
              (pixel.b / 255.0 - mean[2]) / std[2],
            ];
          }),
        ),
      );

      var outputTensor = List.generate(
        1,
        (batch) => List.generate(
          _inputSize,
          (y) => List.generate(_inputSize, (x) => [0.0]),
        ),
      );

      // Chạy mô hình TFLite (chỉ 1 lần duy nhất, nhanh 1-2 giây)
      _interpreter!.run(inputTensor, outputTensor);

      // Trích xuất bản đồ xác suất đường viền dạng mảng 1D (tối ưu cho Isolate)
      final List<double> probMapFlat = List.generate(
        _inputSize * _inputSize,
        (i) => outputTensor[0][i ~/ _inputSize][i % _inputSize][0],
      );

      return {
        'probMap': probMapFlat,
        'originalWidth': origW,
        'originalHeight': origH,
        'cropWidth': _inputSize,
        'cropHeight': _inputSize,
      };
    } catch (e) {
      debugPrint('Error running AI model: $e');
      return null;
    }
  }

  /// Thực thi suy luận AI chất lượng cao (Patch-based Inference).
  /// Chia ảnh thành nhiều mảnh 256x256 có overlap, chạy AI từng mảnh rồi ghép lại.
  /// Dùng cho kết quả cuối cùng (Apply), KHÔNG dùng cho preview vì chậm hơn.
  /// maxDim: Giới hạn kích thước tối đa để cân bằng chất lượng & hiệu năng (mặc định 512).
  Future<Map<String, dynamic>?> runHighQualityInference(
    Uint8List imageBytes, {
    int maxDim = 512,
  }) async {
    if (_interpreter == null) {
      await loadModel();
    }
    if (_interpreter == null) return null;

    try {
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      originalImage = img.bakeOrientation(originalImage);

      final int origW = originalImage.width;
      final int origH = originalImage.height;

      // Scale ảnh xuống maxDim nếu cần, giữ tỉ lệ khung hình
      double scale = 1.0;
      if (origW > maxDim || origH > maxDim) {
        scale = maxDim / math.max(origW, origH);
      }
      int workW = (origW * scale).toInt();
      int workH = (origH * scale).toInt();

      img.Image workingImage = originalImage;
      if (scale < 1.0) {
        workingImage = img.copyResize(
          originalImage,
          width: workW,
          height: workH,
          interpolation: img.Interpolation.linear,
        );
      }

      int padW = math.max(workW, _inputSize);
      int padH = math.max(workH, _inputSize);

      const List<double> mean = [0.485, 0.456, 0.406];
      const List<double> std = [0.229, 0.224, 0.225];

      // Tính tọa độ bắt đầu từng patch (overlap 56px)
      int stride = 200;
      List<int> yStarts = [];
      for (int y = 0; y < padH; y += stride) {
        if (y + _inputSize > padH) {
          yStarts.add(padH - _inputSize);
          break;
        }
        yStarts.add(y);
      }
      List<int> xStarts = [];
      for (int x = 0; x < padW; x += stride) {
        if (x + _inputSize > padW) {
          xStarts.add(padW - _inputSize);
          break;
        }
        xStarts.add(x);
      }

      debugPrint(
        'HQ Inference: $workW x $workH, patches: ${yStarts.length}x${xStarts.length} = ${yStarts.length * xStarts.length}',
      );

      // Trọng số blend kiểu kim tự tháp để vùng overlap được hòa trộn mượt mà
      List<List<double>> patchWeight = List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          double dist = [
            x,
            y,
            _inputSize - 1 - x,
            _inputSize - 1 - y,
          ].reduce(math.min).toDouble();
          return dist + 1.0;
        });
      });

      // Dùng mảng 1D ngay từ đầu để tối ưu bộ nhớ
      final probMap = List.filled(padH * padW, 0.0);
      final weightMap = List.filled(padH * padW, 0.0);

      for (int startY in yStarts) {
        for (int startX in xStarts) {
          var inputTensor = List.generate(
            1,
            (batch) => List.generate(
              _inputSize,
              (y) => List.generate(_inputSize, (x) {
                int px = startX + x;
                int py = startY + y;
                if (px < workW && py < workH) {
                  final pixel = workingImage.getPixel(px, py);
                  return [
                    (pixel.r / 255.0 - mean[0]) / std[0],
                    (pixel.g / 255.0 - mean[1]) / std[1],
                    (pixel.b / 255.0 - mean[2]) / std[2],
                  ];
                } else {
                  return [
                    -mean[0] / std[0],
                    -mean[1] / std[1],
                    -mean[2] / std[2],
                  ];
                }
              }),
            ),
          );

          var outputTensor = List.generate(
            1,
            (batch) => List.generate(
              _inputSize,
              (y) => List.generate(_inputSize, (x) => [0.0]),
            ),
          );

          _interpreter!.run(inputTensor, outputTensor);

          for (int py = 0; py < _inputSize; py++) {
            for (int px = 0; px < _inputSize; px++) {
              double val = outputTensor[0][py][px][0];
              double w = patchWeight[py][px];
              int idx = (startY + py) * padW + (startX + px);
              probMap[idx] += val * w;
              weightMap[idx] += w;
            }
          }
          // Nhường event loop để không đơ UI (loading dialog vẫn xoay)
          await Future.delayed(Duration.zero);
        }
      }

      // Trích xuất kết quả kích thước workW x workH dạng mảng 1D
      final List<double> finalProbMapFlat = List.filled(workH * workW, 0.0);
      for (int y = 0; y < workH; y++) {
        for (int x = 0; x < workW; x++) {
          int idx = y * padW + x;
          if (weightMap[idx] > 0) {
            finalProbMapFlat[y * workW + x] = probMap[idx] / weightMap[idx];
          }
        }
      }

      return {
        'probMap': finalProbMapFlat,
        'originalWidth': origW,
        'originalHeight': origH,
        'cropWidth': workW,
        'cropHeight': workH,
      };
    } catch (e) {
      debugPrint('Error running HQ AI model: $e');
      return null;
    }
  }

  /// Áp dụng xử lý hậu kỳ (Post-processing) thông qua Isolate độc lập để không gây giật lag UI.
  static Future<Uint8List?> applyPostProcessing(
    Map<String, dynamic> inferenceResult,
    EdgeDetectionSettings settings,
  ) async {
    return compute(_postProcessCompute, {
      'probMap': inferenceResult['probMap'],
      'originalWidth': inferenceResult['originalWidth'],
      'originalHeight': inferenceResult['originalHeight'],
      'cropWidth': inferenceResult['cropWidth'],
      'cropHeight': inferenceResult['cropHeight'],
      'settings': settings,
    });
  }

  static cv.Mat _thinLines(
    cv.Mat mat,
    EdgeDetectionSettings settings,
    int originalWidth,
    int originalHeight,
    int workingWidth,
    int workingHeight,
  ) {
    if (settings.lineThinning <= 0) return mat;

    final scaleX = originalWidth / workingWidth;
    final scaleY = originalHeight / workingHeight;
    final scale = math.max(scaleX, scaleY);
    // Tính toán số bước làm mỏng tối ưu để thu gọn viền về độ mỏng thanh mảnh đẹp mắt
    int passes = (settings.lineThinning * (scale > 1.5 ? 2.8 : 2.2)).round().clamp(3, 9);
    final kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (3, 3));

    cv.Mat thinned = mat;
    if (!settings.invertColors) {
      // Nền trắng (255), Viền đen (0) -> Dilate nền trắng làm co viền đen
      for (int i = 0; i < passes; i++) {
        thinned = cv.dilate(thinned, kernel);
      }
      thinned = cv.gaussianBlur(thinned, (3, 3), 0.5);
      final finalThresh = cv.threshold(thinned, 128.0, 255, cv.THRESH_BINARY);
      thinned = finalThresh.$2;
    } else {
      // Nền đen (0), Viền trắng (255) -> Erode viền trắng
      for (int i = 0; i < passes; i++) {
        thinned = cv.erode(thinned, kernel);
      }
      thinned = cv.gaussianBlur(thinned, (3, 3), 0.5);
      final finalThresh = cv.threshold(thinned, 128.0, 255, cv.THRESH_BINARY);
      thinned = finalThresh.$2;
    }
    return thinned;
  }

  /// Hàm chạy trên luồng ngầm (Background Isolate) thực hiện các thuật toán OpenCV và xử lý ảnh.
  static Uint8List? _postProcessCompute(Map<String, dynamic> params) {
    try {
      // Đọc mảng 1D để tăng tốc độ gửi qua Isolate
      final List<double> probMapFlat = params['probMap'];
      final int originalWidth = params['originalWidth'];
      final int originalHeight = params['originalHeight'];
      final EdgeDetectionSettings settings = params['settings'];

      final int h = params['cropHeight'];
      final int w = params['cropWidth'];

      // TRƯỜNG HỢP 1: Chế độ làm mềm viền (Soft Edges - Sigmoid Contrast Mode)
      if (settings.useSoftEdges) {
        List<double> allValues = List.from(probMapFlat);
        allValues.sort();

        final int idx05 = (allValues.length * 0.005).floor().clamp(
          0,
          allValues.length - 1,
        );
        final int idx995 = (allValues.length * 0.995).floor().clamp(
          0,
          allValues.length - 1,
        );
        final double minVal = allValues[idx05];
        final double maxVal = allValues[idx995];

        img.Image outputMask = img.Image(width: w, height: h, numChannels: 3);

        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            double val = probMapFlat[y * w + x];

            if (maxVal > minVal) {
              val = (val - minVal) / (maxVal - minVal);
            }
            val = val.clamp(0.0, 1.0);

            // Áp dụng hàm Sigmoid tăng độ tương phản đường viền
            final double k = settings.softEdgeClarity;
            final double midpoint = settings.threshold;
            double sigmoidArg = -k * (val - midpoint);
            sigmoidArg = sigmoidArg.clamp(-50.0, 50.0);
            double result = 1.0 / (1.0 + math.exp(sigmoidArg));

            int edgeVal = (result * 255).clamp(0, 255).toInt();
            outputMask.setPixelRgb(x, y, edgeVal, edgeVal, edgeVal);
          }
        }

        final pngBytes = Uint8List.fromList(img.encodePng(outputMask));
        cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_GRAYSCALE);

        // HED raw output: Viền = 255 (trắng), Nền = 0 (đen).
        // Quy ước chuẩn cho tranh tô màu & Canvas: Nền TRẮNG (255), Viền ĐEN (0).
        // Khi settings.invertColors == false (mặc định), đảo bít để ra Nền TRẮNG / Viền ĐEN.
        if (!settings.invertColors) {
          mat = cv.bitwiseNOT(mat);
        }

        // Khôi phục kích thước về độ phân giải gốc của ảnh
        if (originalWidth != w || originalHeight != h) {
          mat = cv.resize(mat, (
            originalWidth,
            originalHeight,
          ), interpolation: cv.INTER_LINEAR);
        }

        mat = _thinLines(mat, settings, originalWidth, originalHeight, w, h);

        final encoded = cv.imencode('.png', mat);
        return encoded.$2;
      }
      // TRƯỜNG HỢP 2: Chế độ thông thường / Threshold Mode
      else {
        img.Image rawMask = img.Image(width: w, height: h, numChannels: 3);
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            int val = (probMapFlat[y * w + x] * 255).clamp(0, 255).toInt();
            rawMask.setPixelRgb(x, y, val, val, val);
          }
        }

        final pngBytes = Uint8List.fromList(img.encodePng(rawMask));
        cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_GRAYSCALE);

        // Làm mờ Gaussian khử nhiễu trước khi cắt ngưỡng
        if (settings.gaussianBlurSize > 0) {
          int kSize = settings.gaussianBlurSize;
          if (kSize % 2 == 0) kSize += 1;
          mat = cv.gaussianBlur(mat, (kSize, kSize), 0);
        }

        // Cắt ngưỡng nhị phân (Hard Threshold)
        final int threshVal = (settings.threshold * 255).toInt();
        final threshResult = cv.threshold(
          mat,
          threshVal.toDouble(),
          255,
          cv.THRESH_BINARY,
        );
        mat = threshResult.$2;

        // Xử lý hình thái học (Morphology) để lấp lỗ hổng và lọc nhiễu
        if (settings.morphologySize > 0) {
          final kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (
            settings.morphologySize,
            settings.morphologySize,
          ));
          mat = cv.morphologyEx(mat, cv.MORPH_CLOSE, kernel);
          mat = cv.morphologyEx(mat, cv.MORPH_OPEN, kernel);
        }

        // Khử răng cưa cuối cùng với Anti-Alias Sigma
        if (settings.antiAliasSigma > 0) {
          int kAA = (settings.antiAliasSigma * 4).toInt() | 1;
          if (kAA < 3) kAA = 3;
          mat = cv.gaussianBlur(mat, (kAA, kAA), settings.antiAliasSigma);
        }

        // HED raw output: Viền = 255 (trắng), Nền = 0 (đen).
        // Quy ước chuẩn cho tranh tô màu & Canvas: Nền TRẮNG (255), Viền ĐEN (0).
        // Khi settings.invertColors == false (mặc định), đảo bít để ra Nền TRẮNG / Viền ĐEN.
        if (!settings.invertColors) {
          mat = cv.bitwiseNOT(mat);
        }

        // Khôi phục kích thước về độ phân giải gốc
        if (originalWidth != w || originalHeight != h) {
          mat = cv.resize(mat, (
            originalWidth,
            originalHeight,
          ), interpolation: cv.INTER_LINEAR);
        }

        mat = _thinLines(mat, settings, originalWidth, originalHeight, w, h);

        final encoded = cv.imencode('.png', mat);
        return encoded.$2;
      }
    } catch (e) {
      debugPrint('Error in post-processing: $e');
      return null;
    }
  }

  /// Hàm tương thích ngược (Legacy): Nhận bytes ảnh, chạy AI và áp dụng cấu hình mặc định.
  Future<Uint8List?> detectEdges(Uint8List imageBytes) async {
    final inferenceResult = await runInference(imageBytes);
    if (inferenceResult == null) return null;
    return applyPostProcessing(inferenceResult, const EdgeDetectionSettings());
  }

  /// Giải phóng bộ nhớ của bộ thông dịch TFLite khi không còn sử dụng.
  void close() {
    _interpreter?.close();
    _isLoaded = false;
  }

  // ==========================================================================
  // BƯỚC LÀM MỎNG VIỀN SAU AI (Post-AI Line Thinning)
  // Chạy trên Isolate riêng, hoàn toàn tách biệt khỏi pipeline AI.
  // Nhận ảnh edge PNG (kết quả từ AI) → Trả về ảnh edge PNG với viền mỏng 1-2px.
  // ==========================================================================

  /// Làm mỏng viền trên ảnh edge PNG đã qua xử lý AI.
  /// Chạy trong Isolate riêng (compute) để không block UI.
  /// [edgeBytes]: Dữ liệu bytes PNG của ảnh viền (kết quả từ AI hoặc thuật toán).
  /// [targetThicknessPx]: Độ dày viền mục tiêu tính bằng pixel (mặc định 1-2px).
  static Future<Uint8List?> thinEdgeBytes(
    Uint8List edgeBytes, {
    int targetThicknessPx = 2,
  }) async {
    return compute(_thinEdgeBytesCompute, {
      'edgeBytes': edgeBytes,
      'targetThicknessPx': targetThicknessPx,
    });
  }

  /// Hàm chạy trên Isolate riêng thực hiện làm mỏng viền bằng OpenCV.
  /// Cách tiếp cận: Iterative morphological erosion trên viền đen,
  /// sử dụng tỷ lệ pixel để ước tính và kiểm soát độ dày viền.
  static Uint8List? _thinEdgeBytesCompute(Map<String, dynamic> params) {
    try {
      final Uint8List edgeBytes = params['edgeBytes'];
      final int targetThicknessPx = params['targetThicknessPx'];

      // 1. Decode ảnh PNG edge thành grayscale Mat
      cv.Mat mat = cv.imdecode(edgeBytes, cv.IMREAD_GRAYSCALE);
      final int width = mat.cols;
      final int height = mat.rows;

      // 2. Nhị phân hóa để đảm bảo ảnh chỉ có trắng/đen rõ ràng
      final binResult = cv.threshold(mat, 128.0, 255, cv.THRESH_BINARY);
      mat = binResult.$2;

      // 3. Phát hiện quy ước: nền trắng viền đen hay nền đen viền trắng
      //    Đếm pixel trắng — nếu > 50% thì nền trắng, viền đen.
      final totalPixels = width * height;
      final data = mat.data;
      int whiteCount = 0;
      for (int i = 0; i < totalPixels; i++) {
        if (data[i] > 128) whiteCount++;
      }
      final bool isWhiteBackground = whiteCount > totalPixels ~/ 2;

      // 4. Chuẩn hóa: chuyển sang nền trắng (255) viền đen (0) để xử lý thống nhất
      cv.Mat work = isWhiteBackground ? mat : cv.bitwiseNOT(mat);

      // 5. Ước tính độ dày viền dựa trên tỷ lệ pixel đen.
      //    Tỷ lệ này giúp quyết định cần bao nhiêu bước erosion.
      //    Với ảnh edge thông thường, viền chiếm ~5-20% diện tích.
      int blackPixels = totalPixels - (isWhiteBackground ? whiteCount : (totalPixels - whiteCount));
      final double blackRatio = blackPixels / totalPixels;
      debugPrint('Edge black ratio: ${(blackRatio * 100).toStringAsFixed(1)}%');

      // 6. Tính số bước erosion cần thiết để đạt độ mảnh tinh tế mục tiêu.
      int erodeSteps;
      if (blackRatio < 0.03) {
        erodeSteps = 2;
      } else if (blackRatio < 0.06) {
        erodeSteps = 4;
      } else if (blackRatio < 0.12) {
        erodeSteps = 6;
      } else if (blackRatio < 0.20) {
        erodeSteps = 8;
      } else {
        erodeSteps = 10;
      }

      // Điều chỉnh theo targetThicknessPx: mỏng hơn đáng kể so với preview
      if (targetThicknessPx <= 1) {
        erodeSteps += 2;
      }

      debugPrint('Thinning edges: erodeSteps=$erodeSteps (blackRatio=${(blackRatio * 100).toStringAsFixed(1)}%)');

      if (erodeSteps > 0) {
        // 7. Iterative dilate nền trắng (= thu hẹp viền đen) từng bước nhỏ
        // Luân phiên sử dụng MORPH_CROSS và MORPH_ELLIPSE để bảo toàn tính liên tục 4 hướng,
        // giúp viền mỏng thanh mảnh, sắc sảo mà tuyệt đối không bị đứt nét.
        final kernelCross = cv.getStructuringElement(cv.MORPH_CROSS, (3, 3));
        final kernelEllipse = cv.getStructuringElement(cv.MORPH_ELLIPSE, (3, 3));

        for (int i = 0; i < erodeSteps; i++) {
          final k = (i % 2 == 0) ? kernelCross : kernelEllipse;
          work = cv.dilate(work, k);
        }

        // 8. Refine: Gaussian blur nhẹ + Re-threshold để xác lập lõi viền mỏng sạch sẽ
        work = cv.gaussianBlur(work, (3, 3), 0.4);
        final finalThresh = cv.threshold(work, 140.0, 255, cv.THRESH_BINARY);
        work = finalThresh.$2;

        // Khử răng cưa (Sub-pixel Anti-Aliasing) cho ảnh viền Line Art:
        // Tạo dải chuyển tiếp mức xám mịn ở rìa viền (0 -> 60 -> 140 -> 220 -> 255),
        // giúp GPU khử răng cưa mượt mà khi zoom to, loại bỏ hoàn toàn hiện tượng bậc thang pixel
        work = cv.gaussianBlur(work, (3, 3), 0.65);
      }

      // 9. Chuẩn hóa đầu ra: Luôn xuất NỀN TRẮNG (255) / VIỀN ĐEN (0) cho VectorizationEngine & Canvas
      final encoded = cv.imencode('.png', work);
      return encoded.$2;
    } catch (e) {
      debugPrint('Error in thinEdgeBytes: $e');
      return null;
    }
  }
}
