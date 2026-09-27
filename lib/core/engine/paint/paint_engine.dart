// File: paint_engine.dart

import 'dart:ui';
import '../../models/paint_state.dart';
import '../../models/tool_type.dart';
import 'paint_tools.dart';

/// PaintEngine đóng vai trò là "Bộ xử lý Dữ liệu ngầm".
/// Trong kiến trúc 2 Lớp (Active Layer & Base Layer):
/// - Lúc người dùng đang lướt ngón tay, Engine này âm thầm nhận tọa độ để xây dựng cấu trúc dữ liệu nét vẽ.
/// - Nó KHÔNG trực tiếp yêu cầu UI vẽ lại (tránh lag).
/// - Khi người dùng nhấc ngón tay, Controller mới gọi notifyListeners() để render lại toàn bộ bằng dữ liệu từ đây.
class PaintEngine {
  final PaintState paintState;
  
  PaintTool? _activeTool;
  
  PaintEngine(this.paintState);

  /// Cập nhật công cụ hiện hành, màu sắc và kích thước cọ
  void setTool(ToolType type, Color color, double size) {
    switch (type) {
      case ToolType.fill:
        _activeTool = FillTool(color);
        break;
      case ToolType.eraser:
        _activeTool = EraserTool(size);
        break;
      case ToolType.brush:
        _activeTool = BrushTool(color, size);
        break;
      case ToolType.pencil:
        _activeTool = PencilTool(color, size);
        break;
      case ToolType.spray:
        _activeTool = SprayTool(color, size);
        break;
    }
  }

  /// Nhận sự kiện bắt đầu chạm.
  /// Gọi âm thầm từ WorkspaceController để khởi tạo nét mới trong PaintState.
  void onPointerDown(Offset position, int? regionId) {
    if (_activeTool != null && regionId != null) {
      _activeTool!.onPointerDown(position, regionId, paintState);
    }
  }

  /// Nhận tọa độ khi ngón tay di chuyển.
  /// Bơm liên tục tọa độ (points) vào công cụ (Brush/Pencil/Eraser) để lưu trữ.
  void onPointerMove(Offset position, int? regionId) {
    if (_activeTool != null && regionId != null) {
      _activeTool!.onPointerMove(position, regionId, paintState);
    }
  }

  /// Chốt nét vẽ khi người dùng nhấc ngón tay.
  /// Kết thúc việc lưu trữ nét vẽ hiện tại vào PaintState.
  void onPointerUp() {
    if (_activeTool != null) {
      _activeTool!.onPointerUp(paintState);
    }
  }
}