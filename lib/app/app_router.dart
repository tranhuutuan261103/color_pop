// File app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/home/cubit/home_cubit.dart';
import '../features/main/view/main_screen.dart';
import '../features/history/view/history_screen.dart';
import '../features/creator/view/workspace_screen.dart';
import '../features/creator/view/edge_settings_screen.dart';
import '../features/creator/view/edge_preview_screen.dart';
import '../core/processingAI/edge_detection_settings.dart';
import 'dart:typed_data';

/// Chịu trách nhiệm điều hướng trung tâm của App.
/// Mọi lệnh chuyển trang (Navigator.pushNamed) đều đi qua hàm [generateRoute] để kiểm tra,
/// ép kiểu dữ liệu và bọc Provider/State trước khi mở giao diện mới.
class AppRouter {
  static const String homeRoute = '/';
  static const String historyRoute = '/history';
  static const String workspaceRoute = '/workspace';
  static const String edgeSettingsRoute = '/edge-settings';
  static const String edgePreviewRoute = '/edge-preview';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ---------------------------------------------------------
      // HOME: Khởi tạo HomeCubit và tự động gọi API/Load dữ liệu ngay
      // ---------------------------------------------------------
      case homeRoute:
        return MaterialPageRoute(
          // Tải HomeCubit vào UI và tải dữ liệu ngay lập tức
          builder: (_) => BlocProvider(
            create: (_) => HomeCubit()..loadHomeData(),
            child: const MainScreen(),
          ),
        );
      // ---------------------------------------------------------
      // WORKSPACE: Màn hình chỉnh sửa ảnh.
      // Hỗ trợ 2 kiểu nhận args: Map (nhiều dữ liệu) hoặc String (chỉ mỗi đường dẫn ảnh)
      // ---------------------------------------------------------
      case workspaceRoute:
        // Hứng dữ liệu (đường dẫn ảnh và loại model) được truyền sang
        String imagePath = '';
        String modelType = 'ai'; // Default là model AI
        Uint8List? edgeBytes;
        // Trích xuất dữ liệu an toàn
        if (settings.arguments is Map) {
          // Trường hợp 1: Truyền vào 1 cụm dữ liệu phức tạp
          final args = settings.arguments as Map<String, dynamic>;
          imagePath = args['path'] as String;
          modelType = args['model'] as String? ?? 'ai';
          edgeBytes = args['edgeBytes'] as Uint8List?;
        } else if (settings.arguments is String) {
          // Trường hợp 2: Chỉ truyền vào 1 đường dẫn ảnh đơn giản
          imagePath = settings.arguments as String;
        }
        return MaterialPageRoute(
          builder: (_) => WorkspaceScreen(
            imagePath: imagePath,
            modelType: modelType,
            edgeBytes: edgeBytes,
          ),
        );
      // ---------------------------------------------------------
      // EDGE SETTINGS: Màn hình cài đặt cho tính năng Edge Detection
      // ---------------------------------------------------------
      case edgeSettingsRoute:
        return MaterialPageRoute(builder: (_) => const EdgeSettingsScreen());
      // ---------------------------------------------------------
      // EDGE PREVIEW: Màn hình xem trước kết quả Edge Detection.
      // Bắt buộc args là Map.
      // ---------------------------------------------------------
      case edgePreviewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EdgePreviewScreen(
            imageBytes: args['imageBytes'] as Uint8List,
            imagePath: args['imagePath'] as String,
            initialSettings:
                args['settings'] as EdgeDetectionSettings? ??
                const EdgeDetectionSettings(),
          ),
        );
      // ---------------------------------------------------------
      // HISTORY: Lịch sử thao tác
      // ---------------------------------------------------------
      case historyRoute:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      // ---------------------------------------------------------
      // MẶC ĐỊNH (FALLBACK): Bắt lỗi khi gọi sai tên Route
      // ---------------------------------------------------------
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
