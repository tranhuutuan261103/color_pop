import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/engine/logic/workspace_logic.dart';
import '../controller/workspace_controller.dart';
import '../models/drawing_path.dart';
import '../constants/workspace_colors.dart';
import '../painter/drawing_painter.dart';

class WorkspaceCanvas extends StatefulWidget {
  final WorkspaceController controller;

  const WorkspaceCanvas({super.key, required this.controller});

  @override
  State<WorkspaceCanvas> createState() => _WorkspaceCanvasState();
}

class _WorkspaceCanvasState extends State<WorkspaceCanvas> {
  // Trạng thái quản lý Real-time và Multi-touch
  int _activePointers = 0; // Đếm số ngón tay chạm màn hình
  bool _isDrawing = false;
  
  DateTime _lastProcessTime = DateTime.now();
  bool _isProcessingNative = false;
  Offset? _lastSentPoint;
  
  // Tọa độ gốc cho Smart Brush
  int? _anchorX;
  int? _anchorY;
  
  // Biến hứng tọa độ để nhận diện Tap (Thùng sơn)
  Offset? _tapStartPoint;
  DateTime? _tapStartTime;

  Size _canvasSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        // Cho phép dùng 1 ngón tay di chuyển nếu đang bật isPanMode.
        // Còn Zoom bằng 2 ngón thì LÚC NÀO CŨNG HOẠT ĐỘNG.
        panEnabled: widget.controller.isPanMode,
        scaleEnabled: true, 
        minScale: 0.1,
        maxScale: 10.0,
        child: Center(
          child: widget.controller.displayImageBytes != null
              ? AspectRatio(
                  aspectRatio: widget.controller.imageWidth / widget.controller.imageHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // HÌNH ẢNH GỐC
                          Image.memory(
                            widget.controller.displayImageBytes!,
                            fit: BoxFit.fill,
                            gaplessPlayback: true, 
                          ),
                          
                          // LỚP VẼ & LẮNG NGHE ĐA ĐIỂM (MULTI-TOUCH)
                          Listener(
                            onPointerDown: (event) {
                              _activePointers++;
                              if (_activePointers == 1 && !widget.controller.isPanMode) {
                                _isDrawing = true;
                                _handlePointerDown(event.localPosition);
                              } else if (_activePointers > 1 && _isDrawing) {
                                // 2 NGÓN TAY: Ngưng vẽ để cho phép Zoom
                                _isDrawing = false;
                                _abortStroke();
                              }
                            },
                            onPointerMove: (event) {
                              if (_isDrawing && _activePointers == 1) {
                                _handlePointerMove(event.localPosition);
                              }
                            },
                            onPointerUp: (event) {
                              _activePointers--;
                              if (_isDrawing && _activePointers == 0) {
                                _isDrawing = false;
                                _handlePointerUp(event.localPosition);
                              }
                              if (_activePointers < 0) _activePointers = 0;
                            },
                            onPointerCancel: (event) {
                              _activePointers = 0;
                              if (_isDrawing) {
                                _isDrawing = false;
                                _abortStroke();
                              }
                            },
                            child: CustomPaint(
                              painter: DrawingPainter(widget.controller.paths),
                              size: Size.infinite,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }

  // --- XỬ LÝ CHẠM VÀO ---
  void _handlePointerDown(Offset localPosition) {
    // 1. Phục vụ tính năng Thùng sơn (Chạm Tap)
    _tapStartPoint = localPosition;
    _tapStartTime = DateTime.now();

    if (widget.controller.selectedToolIndex == 0) return;

    // 2. Neo tọa độ cho Smart Brush
    final wRatio = _canvasSize.width == 0 ? 1 : _canvasSize.width;
    final hRatio = _canvasSize.height == 0 ? 1 : _canvasSize.height;
    _anchorX = (localPosition.dx / wRatio * widget.controller.imageWidth).round();
    _anchorY = (localPosition.dy / hRatio * widget.controller.imageHeight).round();

    _lastSentPoint = localPosition;
    _lastProcessTime = DateTime.now();

    // Vẽ nháp cho Tẩy(1) và Bút chì(3). Cọ(2) chờ Realtime Native.
    if (widget.controller.selectedToolIndex == 1 || widget.controller.selectedToolIndex == 3) {
      widget.controller.currentPath = DrawingPath(
        points: [localPosition],
        color: workspaceColors[widget.controller.selectedColorIndex],
        strokeWidth: widget.controller.sliderValue * 40 + 2,
        isEraser: widget.controller.selectedToolIndex == 1,
      );
      widget.controller.paths.add(widget.controller.currentPath!);
    }
    widget.controller.triggerRebuild();
  }

  // --- XỬ LÝ LÚC VUỐT (REALTIME) ---
  void _handlePointerMove(Offset localPosition) {
    if (widget.controller.selectedToolIndex == 0) return;
    
    if (widget.controller.currentPath != null) {
      widget.controller.currentPath!.points.add(localPosition);
    }
    widget.controller.triggerRebuild();

    final now = DateTime.now();
    // 60FPS Refresh (16ms)
    if (now.difference(_lastProcessTime).inMilliseconds > 16 && !_isProcessingNative && _lastSentPoint != null) {
      _isProcessingNative = true;
      _lastProcessTime = now;

      final segmentPoints = [_lastSentPoint!, localPosition];
      _lastSentPoint = localPosition;

      _processChunkToNative(segmentPoints).then((_) => _isProcessingNative = false);
    }
  }

  // --- XỬ LÝ NHẤC TAY ---
  void _handlePointerUp(Offset localPosition) async {
    // Nếu là Tool 0 (Thùng sơn) -> Kiểm tra xem có phải chạm ngắn (Tap) không
    if (widget.controller.selectedToolIndex == 0) {
      if (_tapStartPoint != null && _tapStartTime != null) {
        final distance = (localPosition - _tapStartPoint!).distance;
        final timeDiff = DateTime.now().difference(_tapStartTime!).inMilliseconds;
        
        // Điều kiện của "1 Cú chạm nhẹ": Tay di chuyển ít hơn 10 pixel và nhấc lên nhanh dưới 500ms
        if (distance < 10 && timeDiff < 500) {
          final wRatio = _canvasSize.width == 0 ? 1 : _canvasSize.width;
          final hRatio = _canvasSize.height == 0 ? 1 : _canvasSize.height;

          final startX = (localPosition.dx / wRatio * widget.controller.imageWidth).round();
          final startY = (localPosition.dy / hRatio * widget.controller.imageHeight).round();

          final updatedBytes = await WorkspaceLogic.applyFloodFill(
            startX: startX.clamp(0, widget.controller.imageWidth - 1),
            startY: startY.clamp(0, widget.controller.imageHeight - 1),
            color: workspaceColors[widget.controller.selectedColorIndex],
          );

          if (updatedBytes != null) {
            widget.controller.displayImageBytes = updatedBytes;
            widget.controller.triggerRebuild();
          }
        }
      }
      return;
    }

    if (_lastSentPoint != null) {
        await _processChunkToNative([_lastSentPoint!, localPosition]);
    }

    _abortStroke(); // Dọn dẹp
  }

  // --- HỦY NÉT VẼ ---
  void _abortStroke() {
    widget.controller.currentPath = null;
    widget.controller.paths.clear();
    widget.controller.triggerRebuild();
    _lastSentPoint = null;
    _tapStartPoint = null;
  }

  // --- GIAO TIẾP NATIVE ---
  Future<void> _processChunkToNative(List<Offset> rawPoints) async {
    final wRatio = _canvasSize.width == 0 ? 1 : _canvasSize.width;
    final hRatio = _canvasSize.height == 0 ? 1 : _canvasSize.height;

    final realPoints = rawPoints.map((point) {
      return Offset(
        (point.dx / wRatio * widget.controller.imageWidth).roundToDouble(),
        (point.dy / hRatio * widget.controller.imageHeight).roundToDouble(),
      );
    }).toList();

    final color = workspaceColors[widget.controller.selectedColorIndex];
    final radius = widget.controller.sliderValue * 40 + 2;
    Uint8List? updatedBytes;

    switch (widget.controller.selectedToolIndex) {
      case 2: // Cọ thông minh
        updatedBytes = await WorkspaceLogic.applySmartBrush(
          points: realPoints, color: color, radius: radius,
          startX: _anchorX?.clamp(0, widget.controller.imageWidth - 1) ?? 0,
          startY: _anchorY?.clamp(0, widget.controller.imageHeight - 1) ?? 0,
        );
        break;
      // Nếu bạn đã cấu hình Eraser(1), Pencil(3) và Spray(4) trả về File Byte từ Kotlin thì gọi tương tự như trên!
    }

    if (updatedBytes != null) {
      widget.controller.displayImageBytes = updatedBytes;
      widget.controller.triggerRebuild();
    }
  }
}