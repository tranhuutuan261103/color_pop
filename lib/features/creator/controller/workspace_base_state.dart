import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../core/models/color_pop_document.dart';
import '../../../core/spatial/spatial_index.dart';
import '../../../core/engine/paint/paint_engine.dart';
import '../../../core/models/tool_type.dart';
import '../constants/workspace_colors.dart';
import '../models/active_stroke_data.dart';

abstract class WorkspaceBaseState extends ChangeNotifier {
  final String initialImagePath;
  final String modelType;

  bool isLoading = true; // Quản lý hiển thị màn hình loading
  String? loadError;
  ColorPopDocument?
  document; // Bộ não chứa toàn bộ vector, tọa độ, và lịch sử tô màu
  SpatialIndex?
  spatialIndex; // Công cụ tìm kiếm nhanh: Truyền vào x,y -> Trả ra ID vùng
  PaintEngine? paintEngine; // Động cơ xử lý nét cọ, đổ màu và giới hạn vùng vẽ
  String?
  currentCpopPath; // File vật lý (.cpop) lưu trữ toàn bộ project trên máy

  double imageWidth = 1;
  double imageHeight = 1;

  // Dùng để 'chụp ảnh' màn hình giao diện Flutter khi muốn xuất file PNG
  GlobalKey canvasKey = GlobalKey();

  // Trạng thái thanh công cụ (UI)
  int selectedToolIndex = 2;
  double sliderValue = 0.5;
  int selectedColorIndex = 0;
  bool isPanMode = false; // True: Dùng ngón tay để kéo/zoom ảnh. False: Để vẽ.

  // Kênh liên lạc siêu tốc giúp vẽ nét tức thời ở 60-120fps mà không làm lag các UI khác
  final ValueNotifier<ActiveStrokeData?> activeStrokeNotifier = ValueNotifier(
    null,
  );

  // Ảnh viền đã được xử lý từ màn hình Preview (nếu có)
  final Uint8List? preProcessedEdgeBytes;

  // File cpop có sẵn từ Library (nếu có)
  final String? preProcessedCpopPath;

  // Ảnh Line Art (UI Image) dùng để render lớp viền sắc nét trên Canvas bằng BlendMode.multiply
  ui.Image? lineArtUiImage;

  WorkspaceBaseState(
    this.initialImagePath, {
    this.modelType = 'canny',
    this.preProcessedEdgeBytes,
    this.preProcessedCpopPath,
  });

  /// Đồng bộ màu, cọ, độ dày từ UI (Controller) vào bộ máy xử lý (PaintEngine)
  void updatePaintEngineState() {
    if (paintEngine == null) return;
    ToolType type = ToolType.values[selectedToolIndex];
    double size = sliderValue * 20 + 5;
    if (type == ToolType.brush) {
      size = sliderValue * 30 + 15;
    }
    Color color = workspaceColors[selectedColorIndex];
    paintEngine!.setTool(type, color, size);
  }

  bool get isFillTool => ToolType.values[selectedToolIndex] == ToolType.fill;
  bool get isEraserTool =>
      ToolType.values[selectedToolIndex] == ToolType.eraser;

  void triggerRebuild() {
    notifyListeners();
  }

  @override
  void dispose() {
    // Dọn rác bộ nhớ (RAM) khi người dùng thoát khỏi màn hình tô màu
    document = null;
    lineArtUiImage?.dispose();
    lineArtUiImage = null;
    activeStrokeNotifier.dispose();
    super.dispose();
  }
}
