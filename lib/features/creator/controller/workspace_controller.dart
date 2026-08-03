import 'dart:typed_data'; // Thêm thư viện này để dùng Uint8List
import 'package:flutter/material.dart';

import '../../../core/engine/logic/workspace_logic.dart';
import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';
import '../models/drawing_path.dart';

class WorkspaceController extends ChangeNotifier {
  // ==========================================
  // 1. TRẠNG THÁI HỆ THỐNG & DỮ LIỆU (SYSTEM STATE)
  // ==========================================
  bool isLoading = true; 
  ColorProject? project; 
  late String currentImagePath; 
  
  // MỚI: Biến lưu trữ mảng byte của bức ảnh để hiển thị lên màn hình.
  // Giao diện (WorkspaceCanvas) sẽ dùng Image.memory(displayImageBytes!) để vẽ.
  Uint8List? displayImageBytes; 

  // ==========================================
  // 2. TRẠNG THÁI GIAO DIỆN (UI STATE)
  // ==========================================
  int selectedToolIndex = 0; // 0: Tô màu (Smart Fill), 1: Tẩy, 2: Cọ lớn, 3: Bút chì,...
  double sliderValue = 0.5; 
  int selectedColorIndex = 3; 
  bool isPanMode = false; 

  // ==========================================
  // 3. TRẠNG THÁI VẼ NHÁP FLUTTER (DRAWING STATE)
  // ==========================================
  final List<DrawingPath> paths = []; 
  DrawingPath? currentPath; 
  
  // ==========================================
  // 4. KÍCH THƯỚC ẢNH
  // ==========================================
  int imageWidth = 1;
  int imageHeight = 1;

  /// Khởi tạo Controller
  WorkspaceController(String initialImagePath) {
    currentImagePath = initialImagePath;
    _initData();
  }

  /// Khởi tạo dữ liệu từ Native
  Future<void> _initData() async {
    // 1. Gọi Native xử lý logic dự án (Copy file, chuyển đen trắng...)
    final result = await WorkspaceLogic.initProjectLogic(currentImagePath);
    project = result['project'];
    currentImagePath = result['currentImagePath'];
    imageWidth = result['width'];
    imageHeight = result['height'];

    // 2. Yêu cầu Native load ảnh vào RAM và trả về bản Preview (Uint8List)
    displayImageBytes = await WorkspaceLogic.loadProjectToNative(currentImagePath);
    
    // 3. Hoàn tất khởi tạo
    isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // HÀM TƯƠNG TÁC TỪ UI
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
  // HÀM TƯƠNG TÁC VỚI DATABASE
  // ==========================================
  Future<void> markAsCompleted() async {
    if (project != null) {
      final updatedProject = project!.copyWith(status: 'completed');
      await DatabaseHelper.instance.updateProject(updatedProject);
    }
  }
  
  // Kích hoạt vẽ lại UI chủ động
  void triggerRebuild() => notifyListeners();
}