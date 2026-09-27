// File workspace_screen.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../controller/workspace_controller.dart';
import '../widget/workspace_app_bar.dart';
import '../widget/workspace_canvas.dart';
import '../widget/tool_palette.dart';
import '../widget/brush_slider.dart';
import '../widget/color_palette.dart';
import '../widget/bottom_toolbar.dart';

/// Màn hình không gian làm việc chính (Workspace).
/// Nơi người dùng thực hiện các thao tác tô màu, tẩy xóa trên ảnh đã chọn.
class WorkspaceScreen extends StatefulWidget {
  final String imagePath;
  final String modelType;
  final Uint8List? edgeBytes; // Nhận kết quả từ Edge Preview Screen
  final String? cpopPath; // Trực tiếp nhận cpopPath nếu có (Dùng cho Library)
  const WorkspaceScreen({
    super.key,
    required this.imagePath,
    this.modelType = 'ai',
    this.edgeBytes,
    this.cpopPath,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  // Pattern: Tách biệt UI và Logic. Mọi nghiệp vụ xử lý ảnh,
  // quản lý state (màu, cọ, undo/redo) đều nằm trong controller này.
  late WorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Controller. Controller sẽ tự động gọi logic load file, setup bitmap, database ngay khi được khởi tạo.
    _controller = WorkspaceController(
      widget.imagePath,
      modelType: widget.modelType,
      preProcessedEdgeBytes: widget.edgeBytes,
      preProcessedCpopPath: widget.cpopPath,
    );
  }

  @override
  void dispose() {
    // Hủy controller khi thoát màn hình để giải phóng bộ nhớ, tránh memory leak từ ChangeNotifier và các luồng xử lý ảnh.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi trạng thái từ Controller (State Management).
    // Chỉ rebuild cây UI bên trong khi Controller gọi notifyListeners().
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // LUỒNG 1: Controller đang chuẩn bị dữ liệu ảnh (Loading)
        if (_controller.isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (_controller.loadError != null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(_controller.loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        // LUỒNG 2: Dữ liệu đã sẵn sàng, render Workspace UI
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Thanh tiêu đề và các nút chức năng (Nút Back, Save, Tên Project...)
                WorkspaceAppBar(controller: _controller),

                // 2. Khu vực vẽ (Canvas): Dùng Expanded để chiếm toàn bộ không gian trống còn lại ở giữa màn hình.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: WorkspaceCanvas(controller: _controller),
                  ),
                ),

                // 3. Khay chọn công cụ (Tô màu, Tẩy, Bút...)
                ToolPalette(controller: _controller),

                // 4. Thanh trượt chỉnh kích thước cọ/tẩy
                BrushSlider(controller: _controller),

                // 5. Bảng màu sắc
                ColorPalette(controller: _controller),
                const SizedBox(height: 16),

                // 6. Thanh công cụ phụ dưới cùng (Undo, Redo, Pan Mode...)
                BottomToolbar(controller: _controller),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
