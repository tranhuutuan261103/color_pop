import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';
import '../widget/workspace_app_bar.dart';
import '../widget/workspace_canvas.dart';
import '../widget/tool_palette.dart';
import '../widget/brush_slider.dart';
import '../widget/color_palette.dart';
import '../widget/bottom_toolbar.dart';

class WorkspaceScreen extends StatefulWidget {
  final String imagePath;
  const WorkspaceScreen({super.key, required this.imagePath});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  // Bộ điều khiển trung tâm chứa toàn bộ logic, state và dữ liệu của màn hình này.
  late WorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Controller. Controller sẽ tự động gọi logic load file, setup bitmap, database ngay khi được khởi tạo.
    _controller = WorkspaceController(widget.imagePath);
  }

  @override
  void dispose() {
    // Hủy controller khi thoát màn hình để giải phóng bộ nhớ, tránh memory leak từ ChangeNotifier và các luồng xử lý ảnh.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dùng ListenableBuilder để lắng nghe Controller
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // LUỒNG 1: Đang khởi tạo dữ liệu (Loading)
        if (_controller.isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // LUỒNG 2: Khởi tạo xong, hiển thị giao diện làm việc
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Thanh tiêu đề và các nút chức năng (Lưu, Thoát...)
                WorkspaceAppBar(controller: _controller),

                // 2. Khu vực vẽ (Canvas): Dùng Expanded để chiếm toàn bộ không gian trống còn lại ở giữa màn hình.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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