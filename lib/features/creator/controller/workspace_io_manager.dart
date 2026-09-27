import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/engine/logic/workspace_logic.dart';
import '../../../core/format/color_pop_reader.dart';
import '../../../core/format/color_pop_writer.dart';
import '../../../core/spatial/spatial_index.dart';
import '../../../core/engine/paint/paint_engine.dart';
import '../../../core/processingAI/edge_detection_service.dart';
import '../../../core/processingAI/native_edge_detection.dart';
import 'workspace_base_state.dart';

import 'dart:typed_data';

/// Mixin chuyên quản lý luồng Khởi tạo (Input) và Lưu xuất project (Output)
mixin WorkspaceIOManager on WorkspaceBaseState {
  /// Đọc ảnh gốc -> Dùng AI/Thuật toán tách viền đen trắng -> Đẩy xuống C++ tách vector -> Load lên RAM
  Future<void> initWorkspace() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    Uint8List? boundaryBytes = preProcessedEdgeBytes;

    try {
      final project = await WorkspaceLogic.initProjectLogic(initialImagePath);

      String? cpopPath;

      // 1. KIỂM TRA FILE CPOP CÓ SẴN (Bypass AI & Native)
      if (preProcessedCpopPath != null && preProcessedCpopPath!.isNotEmpty) {
        try {
          // Thử lấy byte để xem file có tồn tại thật trong assets không
          await WorkspaceLogic.getBytes(preProcessedCpopPath!);
          cpopPath = preProcessedCpopPath;
          debugPrint(
            "⚡ BYPASS SUCCESS: Loaded pre-processed cpop -> $cpopPath",
          );
        } catch (_) {
          debugPrint(
            "⚠️ Cpop file not found in assets, falling back to Canny/AI: $preProcessedCpopPath",
          );
        }
      }

      // 2. NẾU KHÔNG CÓ CPOP SẴN, CHẠY THUẬT TOÁN (AI/CANNY) -> GỌI NATIVE
      if (cpopPath == null) {
        // Chuyển ảnh gốc thành mảng byte để đưa vào AI/Thuật toán
        final imageBytes = await WorkspaceLogic.getBytes(project.imagePath);
        Uint8List? edgeBytes;

        // Tách viền tùy theo lựa chọn (từ Preview hoặc chạy trực tiếp thuật toán)
        if (preProcessedEdgeBytes != null) {
          edgeBytes = preProcessedEdgeBytes;
        } else {
          if (modelType == 'ai') {
            final aiService = EdgeDetectionService();
            await aiService.loadModel();
            edgeBytes = await aiService.detectEdges(imageBytes);
            aiService.close();
          } else if (modelType == 'sobel') {
            edgeBytes = await NativeEdgeDetection.applySobel(imageBytes);
          } else if (modelType == 'canny') {
            edgeBytes = await NativeEdgeDetection.applyCanny(imageBytes);
          } else if (modelType == 'sketch') {
            edgeBytes = await NativeEdgeDetection.applySketch(imageBytes);
          }
        }

        if (edgeBytes != null) {
          boundaryBytes = edgeBytes;
          // Luôn làm mỏng viền cho Canvas để đạt độ mảnh tinh tế, sắc sảo (mảnh hơn đáng kể so với preview)
          final thinnedBytes = await EdgeDetectionService.thinEdgeBytes(
            edgeBytes,
            targetThicknessPx: 1,
          );
          if (thinnedBytes != null) {
            edgeBytes = thinnedBytes;
            boundaryBytes = thinnedBytes;
            debugPrint('✅ Post-AI thinning applied successfully (Canvas target 1px)');
          }
        }

        if (edgeBytes != null) {
          // AI trả về ảnh PNG byte array. Lưu nó thành file vật lý tạm thời.
          final tempDir = await getTemporaryDirectory();
          final tempEdgePath = p.join(
            tempDir.path,
            '${modelType}_edge_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await File(tempEdgePath).writeAsBytes(edgeBytes);

          // GỌI NATIVE C++: Quét file PNG trắng đen, tìm các vùng khép kín, biến thành đường Vector.
          cpopPath = await WorkspaceLogic.createColorPopDocument(tempEdgePath);
        } else {
          // Fallback: Nếu AI lỗi, dùng phương pháp cũ quét thẳng ảnh gốc
          cpopPath = await WorkspaceLogic.createColorPopDocument(
            project.imagePath,
          );
        }
      } // End of if (cpopPath == null) block

      if (cpopPath != null) {
        currentCpopPath = cpopPath;

        // 5. Giải mã file .cpop từ ổ cứng lên RAM (biến thành các Object Dart)
        document = await ColorPopReader.readFromFile(cpopPath);

        if (document != null) {
          imageWidth = document!.width;
          imageHeight = document!.height;

          // 6. Tải ảnh Line Art phục vụ việc render phủ viền bằng BlendMode.multiply
          if (boundaryBytes != null) {
            try {
              final codec = await ui.instantiateImageCodec(boundaryBytes);
              final frame = await codec.getNextFrame();
              lineArtUiImage = frame.image;
            } catch (e) {
              debugPrint("Lỗi giải mã lineArtUiImage: $e");
            }
          }

          // 7. Xây dựng bản đồ lưới để tăng tốc độ tìm kiếm tọa độ chạm
          spatialIndex = SpatialIndex(document!, boundaryBytes: boundaryBytes);

          // 8. Khởi tạo engine vẽ, gắn dữ liệu lịch sử (paintState) vào engine
          paintEngine = PaintEngine(document!.paintState);
          updatePaintEngineState();
        }
      }

      if (document == null) {
        throw StateError('Không tạo được dữ liệu canvas từ ảnh này.');
      }
    } catch (e) {
      loadError = 'Không thể mở canvas: $e';
      debugPrint("Lỗi khởi tạo Workspace: $e");
    } finally {
      isLoading = false;
      notifyListeners(); // Ẩn loading
    }
  }

  /// Lưu file .cpop (vector) và xuất ảnh kết quả ra PNG (pixel)
  Future<void> markAsCompleted() async {
    try {
      // 1. Lưu đè lịch sử (nét vẽ, vùng màu) vào file .cpop để lần sau mở ra tô tiếp được
      if (currentCpopPath != null && document != null) {
        await ColorPopWriter.writeToFile(document!, currentCpopPath!);
      }

      // 2. Trích xuất giao diện Canvas hiện tại thành ảnh PNG
      final boundary =
          canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Tăng độ phân giải lên 3 lần cho sắc nét
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final savePath = p.join(
          tempDir.path,
          'color_pop_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await File(savePath).writeAsBytes(pngBytes);
      }
    } catch (e) {
      debugPrint("Lỗi khi lưu ảnh: $e");
    }
  }
}
