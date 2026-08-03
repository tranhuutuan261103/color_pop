import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';

/// [WorkspaceLogic]
/// Quản lý giao tiếp và gọi Native Engine qua MethodChannel.
/// Tất cả thao tác đọc, lưu, xử lý ảnh đều do Native (Kotlin) chịu trách nhiệm.
class WorkspaceLogic {
  // Kênh giao tiếp hai chiều: Flutter sẽ gọi tên hàm, truyền tham số qua kênh này,
  // Native sẽ nhận, xử lý và trả kết quả về.
  static const platform = MethodChannel('com.fau.color_pop/image_processor');

  // Hàm đọc file
  static Future<Uint8List> getBytes(String path) async {
    if (path.startsWith('assets/')) {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    }
    return File(path).readAsBytes();
  }

  // Khởi tạo dữ liệu dự án khi bắt đầu vào màn hình vẽ.
  static Future<Map<String, dynamic>> initProjectLogic(String imagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    String currentImagePath = imagePath;
    ColorProject project;
    int width = 1;
    int height = 1;

    if (!currentImagePath.contains(appDir.path)) {
      final fileName = 'bw_${DateTime.now().millisecondsSinceEpoch}_${p.basename(currentImagePath)}';
      final savedImagePath = p.join(appDir.path, fileName);

      if (currentImagePath.startsWith('assets/')) {
        final bytes = await getBytes(currentImagePath);
        final tempPath = p.join(appDir.path, 'temp_${p.basename(currentImagePath)}');
        await File(tempPath).writeAsBytes(bytes);
        currentImagePath = tempPath;
      }

      try {
        final Map<dynamic, dynamic> resultInfo = await platform.invokeMethod(
          'processGrayscale',
          {'inputPath': currentImagePath, 'outputPath': savedImagePath},
        );

        currentImagePath = resultInfo['path'] as String;
        width = resultInfo['width'] as int;
        height = resultInfo['height'] as int;
      } catch (e) {
        throw Exception("Native Engine Exception (processGrayscale): $e");
      }

      project = ColorProject(
        imagePath: currentImagePath,
        status: 'in_progress',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = await DatabaseHelper.instance.insertProject(project);
      project = project.copyWith(id: id);
    } else {
      final allProjects = await DatabaseHelper.instance.getAllProjects();

      try {
        project = allProjects.firstWhere((proj) => proj.imagePath == currentImagePath);
      } catch (_) {
        project = ColorProject(
          imagePath: currentImagePath,
          status: 'in_progress',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
      }

      try {
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
  static Future<Uint8List?> seedActiveLayer(String imagePath, int width, int height) async {
    if (width <= 1 || height <= 1) return null;
    try {
      final Uint8List? maskBytes = await platform.invokeMethod('buildOutlineMask', {
        'inputPath': imagePath,
        'threshold': 120,
      });
      return maskBytes;
    } catch (e) {
      print("Native Engine Exception (buildOutlineMask): $e");
      return null;
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

  // =========================================================================
  // NHÓM 5 CÔNG CỤ VẼ TÁCH BIỆT (Dễ hiểu cho các thành viên trong dự án)
  // =========================================================================

  // [TÍNH NĂNG 1]: BÚT CHÌ (Vẽ nét tự do đè lên mọi thứ, tạo thành viền)
  static Future<bool> applyPencilStroke({
    required List<Offset> points,
    required Color color,
    required double radius,
  }) async {
    if (points.isEmpty) return false;

    final Float64List flatPoints = Float64List(points.length * 2);
    for (int i = 0; i < points.length; i++) {
      flatPoints[i * 2] = points[i].dx;
      flatPoints[i * 2 + 1] = points[i].dy;
    }

    try {
      final bool success = await platform.invokeMethod('applyPencilStroke', {
        'points': flatPoints,
        'color': color.value, // Đã bao gồm thông số Alpha (Opacity)
        'radius': radius,
      });
      return success;
    } catch (e) {
      print("Lỗi Native Engine (Pencil): $e");
      return false;
    }
  }

  // [TÍNH NĂNG 2]: TẨY (Xóa nét tự do, làm trong suốt pixel)
  // Tẩy không cần nhận tham số color
  static Future<bool> applyEraserStroke({
    required List<Offset> points,
    required double radius,
  }) async {
    if (points.isEmpty) return false;

    final Float64List flatPoints = Float64List(points.length * 2);
    for (int i = 0; i < points.length; i++) {
      flatPoints[i * 2] = points[i].dx;
      flatPoints[i * 2 + 1] = points[i].dy;
    }

    try {
      final bool success = await platform.invokeMethod('applyEraserStroke', {
        'points': flatPoints,
        'radius': radius,
      });
      return success;
    } catch (e) {
      print("Lỗi Native Engine (Eraser): $e");
      return false;
    }
  }

  // [TÍNH NĂNG 3]: CỌ THÔNG MINH (Chỉ tô vùng trống, dừng khi chạm viền)
  static Future<Uint8List?> applySmartBrush({
    required List<Offset> points,
    required Color color,
    required double radius,
    required int startX,
    required int startY,
  }) async {
    if (points.isEmpty) return null;

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
      });
      return updatedImageBytes;
    } catch (e) {
      print("Lỗi tô màu Smart Brush: $e");
      return null;
    }
  }

  // [TÍNH NĂNG 4]: THÙNG SƠN (Tô loang màu - Flood Fill)
  static Future<Uint8List?> applyFloodFill({
    required int startX,
    required int startY,
    required Color color,
  }) async {
    try {
      final Uint8List? updatedImageBytes = await platform.invokeMethod('applyFloodFill', {
        'startX': startX,
        'startY': startY,
        'color': color.value,
      });
      return updatedImageBytes;
    } catch (e) {
      print("Lỗi Native Engine (Flood Fill): $e");
      return null;
    }
  }

  // [TÍNH NĂNG 5]: BÌNH XỊT (Spray / Airbrush)
  static Future<Uint8List?> applySpray({
    required List<Offset> points,
    required Color color,
    required double radius,
    double density = 0.5, // Mặc định mật độ phun là 0.5
  }) async {
    if (points.isEmpty) return null;

    final Float64List flatPoints = Float64List(points.length * 2);
    for (int i = 0; i < points.length; i++) {
      flatPoints[i * 2] = points[i].dx;
      flatPoints[i * 2 + 1] = points[i].dy;
    }

    try {
      final Uint8List? updatedImageBytes = await platform.invokeMethod('applySpray', {
        'points': flatPoints,
        'color': color.value,
        'radius': radius,
        'density': density,
      });
      return updatedImageBytes;
    } catch (e) {
      print("Lỗi Native Engine (Spray): $e");
      return null;
    }
  }
}