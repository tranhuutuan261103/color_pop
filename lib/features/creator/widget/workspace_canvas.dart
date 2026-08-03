import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/engine/logic/workspace_logic.dart';
import '../controller/workspace_controller.dart';
import '../models/drawing_path.dart';
import '../constants/workspace_colors.dart';
import '../painter/drawing_painter.dart';

class WorkspaceCanvas extends StatelessWidget {
  final WorkspaceController controller;

  const WorkspaceCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        panEnabled: controller.isPanMode,
        scaleEnabled: true,
        minScale: 0.1,
        maxScale: 10.0,
        child: Center(
          child: controller.displayImageBytes != null
              ? AspectRatio(
                  aspectRatio: controller.imageWidth / controller.imageHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // HÌNH ẢNH THẬT SỰ (Được cập nhật lập tức từ Native)
                          Image.memory(
                            controller.displayImageBytes!,
                            fit: BoxFit.fill,
                            gaplessPlayback: true, // Chống chớp giật (flicker) khi load ảnh mới
                          ),
                          
                          // LỚP VẼ NHÁP CỦA FLUTTER
                          GestureDetector(
                            onPanStart: _shouldDisableDrawing()
                                ? null
                                : (details) => _handlePanStart(details),
                            onPanUpdate: _shouldDisableDrawing()
                                ? null
                                : (details) => _handlePanUpdate(details),
                            onPanEnd: _shouldDisableDrawing()
                                ? null
                                : (details) => _handlePanEnd(details, canvasSize),
                            child: CustomPaint(
                              painter: DrawingPainter(controller.paths),
                              size: Size.infinite,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              : const CircularProgressIndicator(), // Đang đợi ảnh từ Native
        ),
      ),
    );
  }

  bool _shouldDisableDrawing() {
    return controller.isPanMode ||
        (controller.selectedToolIndex != 2 && controller.selectedToolIndex != 3);
  }

  void _handlePanStart(DragStartDetails details) {
    controller.currentPath = DrawingPath(
      points: [details.localPosition],
      color: workspaceColors[controller.selectedColorIndex],
      strokeWidth: controller.sliderValue * 40 + 2,
      isEraser: controller.selectedToolIndex == 1,
    );
    controller.paths.add(controller.currentPath!);
    controller.triggerRebuild();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    controller.currentPath?.points.add(details.localPosition);
    controller.triggerRebuild();
  }

  void _handlePanEnd(DragEndDetails details, Size canvasSize) async {
    if (controller.currentPath != null && controller.currentPath!.points.isNotEmpty) {
      
      // Tỷ lệ màn hình so với ảnh thật
      final wRatio = canvasSize.width == 0 ? 1 : canvasSize.width;
      final hRatio = canvasSize.height == 0 ? 1 : canvasSize.height;

      // Tính điểm bắt đầu (Start Point) để Kotlin xác định vùng giới hạn
      final firstPoint = controller.currentPath!.points.first;
      final startX = (firstPoint.dx / wRatio * controller.imageWidth).round();
      final startY = (firstPoint.dy / hRatio * controller.imageHeight).round();

      // Convert toàn bộ tọa độ
      final realPoints = controller.currentPath!.points.map((point) {
        return Offset(
          (point.dx / wRatio * controller.imageWidth).roundToDouble(),
          (point.dy / hRatio * controller.imageHeight).roundToDouble(),
        );
      }).toList();

      // Xóa nét nháp Flutter NGAY LẬP TỨC để đỡ rối mắt
      controller.currentPath = null;
      controller.paths.clear();
      controller.triggerRebuild();

      // GỌI NATIVE: Nướng ảnh với nét cọ bị giới hạn bởi đường viền
      final Uint8List? updatedBytes = await WorkspaceLogic.applySmartBrush(
        points: realPoints,
        color: workspaceColors[controller.selectedColorIndex],
        radius: controller.sliderValue * 40 + 2,
        startX: startX.clamp(0, controller.imageWidth - 1),
        startY: startY.clamp(0, controller.imageHeight - 1),
        isEraser: controller.selectedToolIndex == 1,
      );

      // CẬP NHẬT ẢNH: Nhận mảng Byte mới từ Native và hiển thị lên màn hình
      if (updatedBytes != null) {
        controller.displayImageBytes = updatedBytes;
        controller.triggerRebuild();
      }
    }
  }
}