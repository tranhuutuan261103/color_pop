// File workspace_controller.dart

import 'workspace_base_state.dart';
import 'workspace_io_manager.dart';
import 'workspace_touch_handler.dart';
import 'workspace_ui_handler.dart';

// Export model dữ liệu nét vẽ, giúp các màn hình UI import controller
// là có thể dùng luôn model này mà không cần import nhiều lần.
export '../models/active_stroke_data.dart';

/// [WorkspaceController] là Controller trung tâm quản lý màn hình làm việc (chỉnh sửa/tách viền ảnh).
/// Áp dụng kiến trúc chia nhỏ module bằng Mixin:
/// - Kế thừa [WorkspaceBaseState]: Lưu trữ dữ liệu cốt lõi (ảnh gốc, ảnh đích, model type đang chọn).
/// - [WorkspaceIOManager]: Xử lý đọc/ghi/lưu ảnh.
/// - [WorkspaceUIHandler]: Quản lý update giao diện và các hiệu ứng visual.
/// - [WorkspaceTouchHandler]: Xử lý logic cử chỉ, chạm, vuốt, vẽ mask trên màn hình.
class WorkspaceController extends WorkspaceBaseState
    with WorkspaceIOManager, WorkspaceUIHandler, WorkspaceTouchHandler {
  /// Khởi tạo Controller.
  WorkspaceController(
    super.initialImagePath, {
    super.modelType = 'canny',
    super.preProcessedEdgeBytes,
    super.preProcessedCpopPath,
  }) {
    // Kích hoạt hàm setup ban đầu (được định nghĩa ở class cha/mixin).
    // Nhiệm vụ: Tải ảnh vào bộ nhớ, khởi tạo bộ lọc Sobel/Canny hoặc load AI model.
    initWorkspace();
  }
}
