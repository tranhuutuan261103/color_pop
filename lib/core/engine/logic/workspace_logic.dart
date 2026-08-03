import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/engine/bitmap/bitmap_stack.dart';

/// [WorkspaceLogic]
/// Quản lý giao tiếp và gọi Native Engine qua MethodChannel.
/// Tất cả thao tác đọc, lưu, xử lý ảnh đều do Native (Kotlin) chịu trách nhiệm.
class WorkspaceLogic {
  // Kênh giao tiếp hai chiều: Flutter sẽ gọi tên hàm, truyền tham số qua kênh này,
  // Native sẽ nhận, xử lý và trả kết quả về.
  static const platform = MethodChannel('com.fau.color_pop/image_processor');

  // Hàm đọc file
  /* Đọc ảnh và trả về dữ liệu byte.
  Ảnh trong app có thể đến từ 2 nguồn:
  - assets/: ảnh được đóng gói trong APK/IPA nên phải đọc bằng rootBundle.
  - File hệ thống (Gallery/Documents): đọc trực tiếp bằng File.readAsBytes().
  Hàm này giúp các phần xử lý ảnh phía sau chỉ cần làm việc với Uint8List 
  mà không cần quan tâm ảnh đến từ nguồn nào. */
  static Future<Uint8List> getBytes(String path) async {
    if (path.startsWith('assets/')) {
      // Asset không phải là file vật lý nên không thể dùng File(path)
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    }
    // Ảnh trong Gallery/Documents là file thật trên thiết bị.
    return File(path).readAsBytes();
  }

  // Khởi tạo dữ liệu dự án khi bắt đầu vào màn hình vẽ.
  // Trả về Map chứa dữ liệu project và các thông số ảnh.
  static Future<Map<String, dynamic>> initProjectLogic(String imagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    String currentImagePath = imagePath;
    ColorProject project;
    int width = 1;
    int height = 1;

    // Kiểm tra xem file ảnh đã nằm trong thư mục an toàn của app (ApplicationDocumentsDirectory) chưa
    /*  - Trường hợp 1 (Chưa có): Ảnh vừa được chọn từ thư viện. Hàm sẽ sinh tên file mới, đọc ảnh 
    -> chuyển sang ảnh đen trắng (grayscale) 
    -> nén lại thành JPG và lưu vào thư mục app. 
    Sau đó tạo bản ghi Database ColorProject.
        - Trường hợp 2 (Đã có): Ảnh là dự án cũ đang tô dở. 
    Nó chỉ việc tìm trong Database, và đọc kích thước ảnh (width, height). */
    if (!currentImagePath.contains(appDir.path)) {
      // Tạo tên file an toàn để lưu vào bộ nhớ trong
      final fileName =
          'bw_${DateTime.now().millisecondsSinceEpoch}_${p.basename(currentImagePath)}';
      final savedImagePath = p.join(appDir.path, fileName);

      // Nếu là ảnh assets, chép ra temp để Native truy cập đường dẫn
      if (currentImagePath.startsWith('assets/')) {
        final bytes = await getBytes(currentImagePath);
        final tempPath = p.join(
          appDir.path,
          'temp_${p.basename(currentImagePath)}',
        );
        await File(tempPath).writeAsBytes(bytes);
        currentImagePath = tempPath;
      }

      try {
        // [NATIVE CALL]: Yêu cầu Native chuyển trắng đen, lưu file và trả về info
        final Map<dynamic, dynamic> resultInfo = await platform.invokeMethod(
          'processGrayscale',
          {'inputPath': currentImagePath, 'outputPath': savedImagePath},
        );

        currentImagePath = resultInfo['path'] as String;
        width = resultInfo['width'] as int;
        height = resultInfo['height'] as int;
      } catch (e) {
        // Nếu Native lỗi, throw exception chặn UI thay vì ráng làm tiếp
        throw Exception("Native Engine Exception (processGrayscale): $e");
      }

      // Tạo bản ghi Database
      project = ColorProject(
        imagePath: currentImagePath,
        status: 'in_progress',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = await DatabaseHelper.instance.insertProject(project);
      project = project.copyWith(id: id);
    } else {
      // Nếu ảnh đã nằm trong App Dir (Tức là mở lại dự án đang làm dở)
      final allProjects = await DatabaseHelper.instance.getAllProjects();

      try {
        project = allProjects.firstWhere(
          (proj) => proj.imagePath == currentImagePath,
        );
      } catch (_) {
        // Khôi phục project nếu mất bản ghi trong Database
        project = ColorProject(
          imagePath: currentImagePath,
          status: 'in_progress',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
      }

      try {
        // [NATIVE CALL]: Yêu cầu Native đọc nhanh thông số Width/Height
        final Map<dynamic, dynamic> info = await platform.invokeMethod(
          'getImageInfo',
          {'path': currentImagePath},
        );
        width = info['width'] as int;
        height = info['height'] as int;
      } catch (e) {
        throw Exception("Native Engine Exception (getImageInfo): $e");
      }
    }

    return {
      'project': project,
      'currentImagePath': currentImagePath,
      'width': width,
      'height': height,
    };
  }

  // Khởi tạo mask
  // Trích xuất đường viền từ ảnh và nạp vào lớp ảnh (Layer) đang thao tác.
  // Bước này tạo ra "khung tranh" đen trắng cho người dùng tô màu.
  static Future<void> seedActiveLayer(
    BitmapStack? stack,
    String imagePath,
    int width,
    int height,
  ) async {
    final layer = stack?.activeLayer;
    if (stack == null || layer == null || width <= 1 || height <= 1) return;

    try {
      // [NATIVE CALL]: Gọi Pipeline dò viền bằng Kotlin
      final Uint8List?
      maskBytes = await platform.invokeMethod('buildOutlineMask', {
        'inputPath': imagePath,
        'threshold':
            120, // ngưỡng cắt viền (0-255). Giá trị càng thấp -> viền càng nhiều, giá trị càng cao -> viền càng ít.
      });

      if (maskBytes == null || maskBytes.length != width * height) return;

      layer.surface.clear();

      // Thuật toán chuyển đổi mảng 1D sang tọa độ 2D (x, y)
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          // Thay vì dùng mảng 2 chiều tốn bộ nhớ, Native trả về mảng 1 chiều
          final index = y * width + x;
          final isOutline = maskBytes[index] == 1;

          final argb = isOutline ? 0xFF000000 : 0x00000000;
          layer.surface.setPixel(x, y, argb);
        }
      }

      layer
          .invalidateCache(); // Thông báo cho Flutter UI vẽ lại màn hình vì data của layer đã thay đổi.
    } catch (e) {
      print("Native Engine Exception (buildOutlineMask): $e");
    }
  }

  static Future<Uint8List?> loadProjectToNative(String path) async {
    try {
      final Uint8List? bytes = await platform.invokeMethod('loadProject', {'path': path});
      return bytes;
    } catch (e) {
      print("Lỗi tải ảnh lên Native: $e");
      return null;
    }
  }

  static Future<Uint8List?> applySmartBrush({
    required List<Offset> points,
    required Color color,
    required double radius,
    required int startX,
    required int startY,
    bool isEraser = false,
  }) async {
    if (points.isEmpty) return null;

    // Ép kiểu danh sách tọa độ thành mảng 1 chiều Float64List siêu tốc
    final Float64List flatPoints = Float64List(points.length * 2);
    for (int i = 0; i < points.length; i++) {
      flatPoints[i * 2] = points[i].dx;
      flatPoints[i * 2 + 1] = points[i].dy;
    }

    try {
      final Uint8List? updatedImageBytes = await platform.invokeMethod('applySmartBrush', {
        'points': flatPoints,
        'color': color.value,
        'radius': radius,
        'startX': startX,
        'startY': startY,
        'isEraser': isEraser,
      });
      return updatedImageBytes; // Trả về ảnh đã tô
    } catch (e) {
      print("Lỗi tô màu Native: $e");
      return null;
    }
  }

  // Vẽ nét cọ (Brush Stroke) hoặc Cục tẩy (Eraser) lên lớp ảnh đang thao tác.
  static Future<bool> applyBrushStroke({
    required List<Offset> points,
    required Color color,
    required double radius,
    bool isEraser = false,
  }) async {
    if (points.isEmpty) return false;

    // 1. Chuyển mảng List<Offset> thành mảng 1 chiều Float64List
    // Ví dụ: [Offset(10, 20), Offset(30, 40)] -> [10.0, 20.0, 30.0, 40.0]
    // Định dạng này đi qua Cầu nối Native với tốc độ cao nhất (không tốn phí JSON serialize)
    final Float64List flatPoints = Float64List(points.length * 2);
    for (int i = 0; i < points.length; i++) {
      flatPoints[i * 2] = points[i].dx;
      flatPoints[i * 2 + 1] = points[i].dy;
    }

    try {
      final bool success = await platform.invokeMethod('applyBrushStroke', {
        'points': flatPoints,
        'color': color.value, // Color.value là mã ARGB chuẩn
        'radius': radius,
        'isEraser': isEraser,
      });
      return success;
    } catch (e) {
      print("Lỗi Native Engine khi vẽ Cọ: $e");
      return false;
    }
  }
}
