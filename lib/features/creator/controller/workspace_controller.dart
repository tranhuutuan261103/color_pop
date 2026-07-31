import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../core/engine/bitmap/bitmap_stack.dart';
import '../../../core/engine/bitmap/bitmap_renderer.dart';
import '../../../core/engine/coloring/coloring_controller.dart';
import '../../../core/engine/logic/workspace_logic.dart';
import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';
import '../models/drawing_path.dart';

class WorkspaceController extends ChangeNotifier {
  // 1. TRẠNG THÁI HỆ THỐNG & DỮ LIỆU (SYSTEM STATE)
  bool isLoading = true; // Trạng thái màn hình chờ ban đầu
  ColorProject? project; // Dữ liệu dự án lưu trữ trong Database
  late String currentImagePath; // Đường dẫn file ảnh đang thao tác
  
  // 2. TRẠNG THÁI GIAO DIỆN (UI STATE)
  int selectedToolIndex = 0; // Công cụ đang chọn (0: Tô màu, 1: Tẩy,...)
  double sliderValue = 0.5; // Giá trị độ lớn của cọ/tẩy (0.0 - 1.0)
  int selectedColorIndex = 3; // Index màu đang chọn trong bảng màu
  bool isPanMode = false; // Chế độ Di chuyển/Zoom ảnh (true) hay Vẽ (false)

  // 3. TRẠNG THÁI VẼ TAY (DRAWING STATE)
  final List<DrawingPath> paths = []; // Danh sách các nét vẽ tự do
  DrawingPath? currentPath; // Nét vẽ hiện tại đang được giữ ngón tay trên màn hình
  
  // 4. CORE ENGINE (BỘ MÁY XỬ LÝ)
  int imageWidth = 1;
  int imageHeight = 1;
  final ColoringController coloringController = ColoringController();
  BitmapStack? bitmapStack; // Quản lý cấu trúc layer (lớp ảnh) dưới dạng byte

  /// Khởi tạo Controller với đường dẫn ảnh ban đầu.
  WorkspaceController(String initialImagePath) {
    currentImagePath = initialImagePath;
    _initData(); // Bắt đầu luồng chuẩn bị dữ liệu
  }

  /// Hàm khởi tạo bất đồng bộ: Load ảnh, setup database, bóc tách đường viền.
  Future<void> _initData() async {
    // 1. Chạy logic xử lý ảnh và DB
    final result = await WorkspaceLogic.initProjectLogic(currentImagePath);
    project = result['project'];
    currentImagePath = result['currentImagePath'];
    imageWidth = result['width'];
    imageHeight = result['height'];

    // 2. Khởi tạo bộ nhớ Bitmap theo đúng kích thước ảnh
    bitmapStack = BitmapStack.createDefault(width: imageWidth, height: imageHeight);
    // Gắn bộ nhớ Bitmap vào Controller tô màu để nó biết phải đổ màu vào đâu
    coloringController.attachStack(bitmapStack!);
    
    // 3. Quét ảnh gốc để trích xuất viền đen (mask) và đổ vào Layer đang active
    await WorkspaceLogic.seedActiveLayer(bitmapStack, currentImagePath, imageWidth, imageHeight);
    
    // 4. Hoàn tất khởi tạo, báo cho View tắt Loading và hiển thị UI
    isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // HÀM TƯƠNG TÁC TỪ UI (USER ACTIONS)
  // Mỗi hàm sau khi cập nhật biến đều gọi notifyListeners() để vẽ lại UI
  // ==========================================
  void updateTool(int index) {
    selectedToolIndex = index;
    notifyListeners();
  }

  void updateSlider(double value) {
    sliderValue = value;
    notifyListeners();
  }

  void updateColor(int index) {
    selectedColorIndex = index;
    notifyListeners();
  }

  void togglePanMode() {
    isPanMode = !isPanMode;
    notifyListeners();
  }

  // ==========================================
  // HÀM TƯƠNG TÁC VỚI DATABASE/ENGINE
  // ==========================================

  /// Đánh dấu dự án hiện tại là đã hoàn thành và lưu vào CSDL
  Future<void> markAsCompleted() async {
    if (project != null) {
      final updatedProject = project!.copyWith(status: 'completed');
      await DatabaseHelper.instance.updateProject(updatedProject);
    }
  }

  /// Chuyển đổi dữ liệu byte của Layer đang active thành [ui.Image] 
  /// để Flutter CustomPaint có thể render lên màn hình.
  Future<ui.Image> renderActiveLayerImage() async {
    final layer = bitmapStack?.activeLayer;
    if (layer == null) throw Exception('No active layer available');
    return const BitmapRenderer().renderLayer(layer);
  }
  
  /// Kích hoạt vẽ lại UI một cách chủ động từ bên ngoài (ví dụ: Canvas gọi 
  /// hàm này liên tục khi ngón tay đang di chuyển để render nét vẽ mượt mà).
  void triggerRebuild() => notifyListeners();
}