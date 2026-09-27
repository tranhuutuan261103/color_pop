import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';

/// [WorkspaceLogic]
/// Cầu nối điều phối giữa Flutter Controller và Kotlin Native Engine.
class WorkspaceLogic {
  static const platform = MethodChannel('com.fau.color_pop/image_processor');

  static Future<Uint8List> getBytes(String path) async {
    if (path.startsWith('assets/')) {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List();
    }
    return File(path).readAsBytes();
  }

  /// Gọi Native Engine xử lý ảnh và trả về file .cpop
  static Future<String?> createColorPopDocument(String imagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    String currentImagePath = imagePath;

    if (currentImagePath.startsWith('assets/')) {
      final bytes = await getBytes(currentImagePath);
      final tempPath = p.join(
        appDir.path,
        'temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(tempPath).writeAsBytes(bytes);
      currentImagePath = tempPath;
    }

    final outputCpopPath = p.join(
      appDir.path,
      'doc_${DateTime.now().millisecondsSinceEpoch}.cpop',
    );

    try {
      final String? resultPath = await platform
          .invokeMethod<String>('createColorPopDocument', {
            'inputPath': currentImagePath,
            'outputPath': outputCpopPath,
          })
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException(
              'Native vectorization timed out after 60 seconds',
            ),
          );
      if (resultPath == null || !await File(resultPath).exists()) {
        throw StateError('Native engine did not create the CPOP file.');
      }
      return resultPath;
    } catch (e) {
      debugPrint('Native Engine Exception (createColorPopDocument): $e');
      rethrow;
    }
  }

  static Future<ColorProject> initProjectLogic(String imagePath) async {
    final allProjects = await DatabaseHelper.instance.getAllProjects();
    ColorProject? project;
    try {
      project = allProjects.firstWhere((proj) => proj.imagePath == imagePath);
    } catch (_) {
      // Create new project if not exists
      final newProject = ColorProject(
        imagePath: imagePath,
        status: 'in_progress',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = await DatabaseHelper.instance.insertProject(newProject);
      project = newProject.copyWith(id: id);
    }
    return project;
  }
}
