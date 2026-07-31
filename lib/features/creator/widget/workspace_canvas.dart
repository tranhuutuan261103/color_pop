import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../controller/workspace_controller.dart';
import '../models/drawing_path.dart';
import '../constants/workspace_colors.dart';
import '../painter/bitmap_layer_painter.dart';
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
          child: controller.imageWidth > 1
              ? AspectRatio(
                  aspectRatio: controller.imageWidth / controller.imageHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(controller.currentImagePath),
                            fit: BoxFit.fill,
                          ),
                          if (controller.bitmapStack?.activeLayer != null)
                            FutureBuilder<ui.Image>(
                              future: controller.renderActiveLayerImage(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                return Positioned.fill(
                                  child: CustomPaint(
                                    painter: BitmapLayerPainter(snapshot.requireData),
                                  ),
                                );
                              },
                            ),
                          GestureDetector(
                            onTapDown: controller.selectedToolIndex == 0
                                ? (details) => _handleFill(details, canvasSize)
                                : null,
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
              : Image.file(
                  File(controller.currentImagePath),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }

  bool _shouldDisableDrawing() {
    return controller.isPanMode ||
        (controller.selectedToolIndex != 2 && controller.selectedToolIndex != 3);
  }

  void _handleFill(TapDownDetails details, Size canvasSize) {
    final wRatio = canvasSize.width == 0 ? 1 : canvasSize.width;
    final hRatio = canvasSize.height == 0 ? 1 : canvasSize.height;

    final x = (details.localPosition.dx / wRatio * controller.imageWidth).round();
    final y = (details.localPosition.dy / hRatio * controller.imageHeight).round();

    final success = controller.coloringController.fillAt(
      x: x.clamp(0, controller.imageWidth - 1),
      y: y.clamp(0, controller.imageHeight - 1),
      color: workspaceColors[controller.selectedColorIndex],
    );

    if (success) controller.triggerRebuild();
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

  void _handlePanEnd(DragEndDetails details, Size canvasSize) {
    if (controller.currentPath != null) {
      final wRatio = canvasSize.width == 0 ? 1 : canvasSize.width;
      final hRatio = canvasSize.height == 0 ? 1 : canvasSize.height;

      final points = controller.currentPath!.points.map((point) {
        return Offset(
          (point.dx / wRatio * controller.imageWidth).roundToDouble(),
          (point.dy / hRatio * controller.imageHeight).roundToDouble(),
        );
      }).toList();

      final success = controller.coloringController.paintBrush(
        points: points,
        color: workspaceColors[controller.selectedColorIndex],
        radius: controller.sliderValue * 3 + 1.0,
      );

      if (success) controller.triggerRebuild();
    }
    controller.currentPath = null;
    controller.triggerRebuild();
  }
}