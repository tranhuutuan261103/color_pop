// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:image/image.dart' as img;
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import '../../models/color_project.dart';
// import '../../services/database_helper.dart';
// import '../bitmap/bitmap_converter.dart';
// import '../bitmap/bitmap_stack.dart';

// class WorkspaceLogic {
//   // Hàm đọc file
//   /* Đọc ảnh và trả về dữ liệu byte.
//   Ảnh trong app có thể đến từ 2 nguồn:
//   - assets/: ảnh được đóng gói trong APK/IPA nên phải đọc bằng rootBundle.
//   - File hệ thống (Gallery/Documents): đọc trực tiếp bằng File.readAsBytes().
//   Hàm này giúp các phần xử lý ảnh phía sau chỉ cần làm việc với Uint8List 
//   mà không cần quan tâm ảnh đến từ nguồn nào. */ 
//   static Future<Uint8List> getBytes(String path) async {
//     // Asset không phải là file vật lý nên không thể dùng File(path)
//     if (path.startsWith('assets/')) {
//       final byteData = await rootBundle.load(path);
//       return byteData.buffer.asUint8List();
//     }
//     // Ảnh trong Gallery/Documents là file thật trên thiết bị.
//     return File(path).readAsBytes();
//   }

//   // Khởi tạo dữ liệu dự án khi bắt đầu vào màn hình vẽ.
//   // Trả về Map chứa dữ liệu project và các thông số ảnh.
//   static Future<Map<String, dynamic>> initProjectLogic(String imagePath) async {
//     final appDir = await getApplicationDocumentsDirectory(); 
//     String currentImagePath = imagePath;
//     ColorProject project;
//     int width = 1;
//     int height = 1;

//     // Kiểm tra xem file ảnh đã nằm trong thư mục an toàn của app (ApplicationDocumentsDirectory) chưa
//     /*  - Trường hợp 1 (Chưa có): Ảnh vừa được chọn từ thư viện. Hàm sẽ sinh tên file mới, đọc ảnh 
//     -> chuyển sang ảnh đen trắng (grayscale) 
//     -> nén lại thành JPG và lưu vào thư mục app. 
//     Sau đó tạo bản ghi Database ColorProject.
//         - Trường hợp 2 (Đã có): Ảnh là dự án cũ đang tô dở. 
//     Nó chỉ việc tìm trong Database, và đọc kích thước ảnh (width, height). */ 
//     if (!currentImagePath.contains(appDir.path)) {
//       // Tạo tên file an toàn với timestamp
//       final fileName = 'bw_${DateTime.now().millisecondsSinceEpoch}_${p.basename(currentImagePath)}';
//       final savedImagePath = p.join(appDir.path, fileName);

//       final imageBytes = await getBytes(currentImagePath);

//       final decodedImage = img.decodeImage(imageBytes); // Decode ảnh
//       if (decodedImage != null) {
//         width = decodedImage.width;
//         height = decodedImage.height;
//         // Chuyển ảnh thành đen trắng (Grayscale) và nén lại thành JPG để tiết kiệm dung lượng
//         final grayscaleImage = img.grayscale(decodedImage);
//         final encodedImage = img.encodeJpg(grayscaleImage);
//         await File(savedImagePath).writeAsBytes(encodedImage);
//       } else {
//         // Fallback nếu không decode được
//         await File(savedImagePath).writeAsBytes(imageBytes);
//       }

//       currentImagePath = savedImagePath;

//       // Tạo bản ghi Database
//       project = ColorProject(
//         imagePath: savedImagePath,
//         status: 'in_progress',
//         createdAt: DateTime.now().millisecondsSinceEpoch,
//       );
//       final id = await DatabaseHelper.instance.insertProject(project);
//       project = project.copyWith(id: id);
//     } else {
//       // Nếu ảnh đã nằm trong App Dir (Tức là mở lại dự án đang làm dở)
//       final allProjects = await DatabaseHelper.instance.getAllProjects();
//       try {
//         project = allProjects.firstWhere((proj) => proj.imagePath == currentImagePath);
//       } catch (_) {
//         // Khôi phục project nếu mất bản ghi trong Database
//         project = ColorProject(
//           imagePath: currentImagePath,
//           status: 'in_progress',
//           createdAt: DateTime.now().millisecondsSinceEpoch,
//         );
//       }
//       // Đọc kích thước ảnh hiện tại
//       final imageBytes = await getBytes(currentImagePath);
//       final decodedImage = img.decodeImage(imageBytes);
//       if (decodedImage != null) {
//         width = decodedImage.width;
//         height = decodedImage.height;
//       }
//     }

//     return {
//       'project': project,
//       'currentImagePath': currentImagePath,
//       'width': width,
//       'height': height,
//     };
//   }

//   // Khởi tạo mask
//   // Trích xuất đường viền từ ảnh và nạp vào lớp ảnh (Layer) đang thao tác.
//   // Bước này tạo ra "khung tranh" đen trắng cho người dùng tô màu.
//   static Future<void> seedActiveLayer(BitmapStack? stack, String imagePath, int width, int height) async {
//     final layer = stack?.activeLayer;
//     if (stack == null || layer == null || width <= 1 || height <= 1) return;

//     final imageBytes = await getBytes(imagePath);
//     final decodedImage = img.decodeImage(imageBytes);
//     if (decodedImage == null) return;

//     final grayscale = img.grayscale(decodedImage);

//     // THẮT CỔ CHAI (BOTTLENECK): Thuật toán tìm đường viền trên ma trận pixel.
//     // Với app thương mại, tính năng này thường được viết bằng C++ (OpenCV) và gọi qua JNI (Android)/FFI (Dart).
//     final outlineMask = const BitmapConverter().buildOutlineMask(
//       image: grayscale,
//       threshold: 140,
//       expansion: 1,
//     );

//     layer.surface.clear();
//     // Xây dựng lại ảnh hiển thị dựa trên mặt nạ (mask) đường viền.
//     // Quét qua hàng triệu pixel, nếu là viền thì gán màu đen, nếu không thì trong suốt.
//     for (var y = 0; y < height; y++) {
//       for (var x = 0; x < width; x++) {
//         final index = y * width + x;
//         final isOutline = outlineMask[index] == 1;
//         final argb = isOutline ? 0xFF000000 : 0x00000000;
//         layer.surface.setPixel(x, y, argb);
//       }
//     }
//     layer.invalidateCache();
//   }
// }

import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/color_project.dart';
import '../../services/database_helper.dart';
import '../bitmap/bitmap_stack.dart';

/// [WorkspaceLogic] được tối ưu hóa Native (Kotlin/Swift)
class WorkspaceLogic {
  // Khai báo kênh giao tiếp với Native. Tên kênh phải khớp với MainActivity.kt
  static const platform = MethodChannel('com.fau.color_pop/image_processor');

  static Future<Uint8List> getBytes(String path) async {
    if (path.startsWith('assets/')) {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    }
    return File(path).readAsBytes();
  }

  static Future<Map<String, dynamic>> initProjectLogic(String imagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    String currentImagePath = imagePath;
    ColorProject project;
    int width = 1;
    int height = 1;

    if (!currentImagePath.contains(appDir.path)) {
      final fileName = 'bw_${DateTime.now().millisecondsSinceEpoch}_${p.basename(currentImagePath)}';
      final savedImagePath = p.join(appDir.path, fileName);

      // Nếu là ảnh assets, phải copy ra thư mục thật để Native có thể đọc được bằng File Path
      if (currentImagePath.startsWith('assets/')) {
        final bytes = await getBytes(currentImagePath);
        final tempPath = p.join(appDir.path, 'temp_${p.basename(currentImagePath)}');
        await File(tempPath).writeAsBytes(bytes);
        currentImagePath = tempPath;
      }

      try {
        // GỌI KOTLIN: Chuyển đen trắng và lưu ảnh với tốc độ cực cao
        await platform.invokeMethod('processGrayscale', {
          'inputPath': currentImagePath,
          'outputPath': savedImagePath,
        });
        currentImagePath = savedImagePath;
      } catch (e) {
        print("Lỗi Native khi xử lý ảnh: $e");
        // Fallback: Nếu native lỗi, copy nguyên file gốc
        final bytes = await File(currentImagePath).readAsBytes();
        await File(savedImagePath).writeAsBytes(bytes);
        currentImagePath = savedImagePath;
      }

      project = ColorProject(
        imagePath: savedImagePath,
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
    }

    // Đọc kích thước file trực tiếp bằng decodeImage của Flutter (Native decode rất nhanh)
    // Hoặc bạn có thể tạo 1 hàm Native nữa để trả về width/height nếu cần tối đa hiệu năng.
    final imageProps = await decodeImageFromList(await File(currentImagePath).readAsBytes());
    width = imageProps.width;
    height = imageProps.height;
    imageProps.dispose();

    return {
      'project': project,
      'currentImagePath': currentImagePath,
      'width': width,
      'height': height,
    };
  }

  static Future<void> seedActiveLayer(BitmapStack? stack, String imagePath, int width, int height) async {
    final layer = stack?.activeLayer;
    if (stack == null || layer == null || width <= 1 || height <= 1) return;

    try {
      // GỌI KOTLIN: Nhận lại mảng Byte (1 là viền, 0 là rỗng)
      // Thao tác này tiết kiệm hàng chục giây cho ảnh lớn so với Dart thuần
      final Uint8List? maskBytes = await platform.invokeMethod('buildOutlineMask', {
        'inputPath': imagePath,
        'threshold': 140,
      });

      if (maskBytes == null || maskBytes.length != width * height) return;

      layer.surface.clear();

      // Dù vẫn dùng vòng lặp for ở Dart, nhưng lúc này ta chỉ xử lý mảng 1 chiều 
      // đã được chuẩn bị sẵn, bỏ qua bước tính toán màu phức tạp.
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final index = y * width + x;
          final isOutline = maskBytes[index] == 1;
          
          final argb = isOutline ? 0xFF000000 : 0x00000000;
          layer.surface.setPixel(x, y, argb);
        }
      }
      
      layer.invalidateCache();
    } catch (e) {
      print("Lỗi Native khi trích xuất viền: $e");
    }
  }
}