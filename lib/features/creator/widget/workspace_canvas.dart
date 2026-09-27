import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/engine/render/hybrid_renderer.dart';
import '../controller/workspace_controller.dart';

class WorkspaceCanvas extends StatefulWidget {
  final WorkspaceController controller;

  const WorkspaceCanvas({super.key, required this.controller});

  @override
  State<WorkspaceCanvas> createState() => _WorkspaceCanvasState();
}

class _WorkspaceCanvasState extends State<WorkspaceCanvas> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        // Chế độ Pan/Zoom được điều khiển từ Controller
        panEnabled: widget.controller.isPanMode,
        scaleEnabled: true,
        minScale: 0.1,
        maxScale: 10.0,
        child: Center(
          child: (widget.controller.document != null)
              ? AspectRatio(
                  aspectRatio: widget.controller.imageWidth / widget.controller.imageHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Tính toán tỷ lệ scale giữa màn hình (Canvas) và ảnh gốc (Document)
                      final scaleX = constraints.maxWidth / widget.controller.imageWidth;
                      final scaleY = constraints.maxHeight / widget.controller.imageHeight;

                      return RepaintBoundary(
                        // canvasKey dùng để chụp lại toàn bộ màn hình khi xuất file PNG
                        key: widget.controller.canvasKey,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // --- 1. LỚP NỀN (BASE LAYER) ---
                            // Chứa ảnh gốc, màu nền, các nét vẽ hoàn thành và lớp viền Line Art
                            CustomPaint(
                              painter: HybridRenderer(
                                widget.controller.document!,
                                lineArtImage: widget.controller.lineArtUiImage,
                              ),
                              size: Size.infinite,
                            ),

                            // --- 2. LỚP ĐỘNG (ACTIVE LAYER) ---
                            // Lớp kính trong suốt chỉ vẽ duy nhất nét cọ đang lướt ngón tay
                            ValueListenableBuilder<ActiveStrokeData?>(
                              valueListenable: widget.controller.activeStrokeNotifier,
                              builder: (context, activeData, child) {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: ActiveLayerPainter(
                                    activeData: activeData,
                                    scaleX: scaleX,
                                    scaleY: scaleY,
                                    lineArtImage: widget.controller.lineArtUiImage,
                                  ),
                                );
                              },
                            ),

                            // --- 3. BẮT SỰ KIỆN CHẠM (TOUCH CATCHER) ---
                            Listener(
                              onPointerDown: (event) {
                                final canvasSize = context.size;
                                if (canvasSize != null) {
                                  widget.controller.handlePointerDown(event.localPosition, canvasSize);
                                }
                              },
                              onPointerMove: (event) {
                                final canvasSize = context.size;
                                if (canvasSize != null) {
                                  widget.controller.handlePointerMove(event.localPosition, canvasSize);
                                }
                              },
                              onPointerUp: (event) {
                                widget.controller.handlePointerUp();
                              },
                              child: Container(color: Colors.transparent),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// CustomPainter chuyên biệt để vẽ nét vẽ đang lướt tay
/// Kết hợp kỹ thuật Clipping Mask để nét vẽ luôn bị giới hạn trong vùng được chọn.
/// Render Line Art lên trên cùng để viền đóng vai trò là vật cản cứng tuyệt đối.
class ActiveLayerPainter extends CustomPainter {
  final ActiveStrokeData? activeData;
  final double scaleX;
  final double scaleY;
  final ui.Image? lineArtImage;

  ActiveLayerPainter({
    required this.activeData,
    required this.scaleX,
    required this.scaleY,
    this.lineArtImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (activeData == null) return;

    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.clipPath(activeData!.clipRegionPath);

    Paint paint = Paint()
      ..color = activeData!.color
      ..strokeWidth = activeData!.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (activeData!.isEraser) {
      paint.blendMode = BlendMode.clear;
    }

    canvas.drawPath(activeData!.strokePath, paint);
    canvas.restore();

    // Render Line Art Overlay lên trên nét cọ đang vẽ với BlendMode.multiply
    // Giữ nguyên viền đen 100% sắc nét, ngăn nét cọ che lấp hoặc đè lên viền
    if (lineArtImage != null) {
      final lineArtPaint = Paint()
        ..blendMode = BlendMode.multiply
        ..filterQuality = FilterQuality.high;

      final srcRect = Rect.fromLTWH(
        0,
        0,
        lineArtImage!.width.toDouble(),
        lineArtImage!.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(lineArtImage!, srcRect, dstRect, lineArtPaint);
    }

    // Render đường viền vector khử răng cưa sub-pixel của vùng đang vẽ
    // Tự động lấp đầy khoảng hở giữa đường bao và đường viền thành màu đen đồng nhất
    final vectorOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = Colors.black;

    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.drawPath(activeData!.clipRegionPath, vectorOutlinePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ActiveLayerPainter oldDelegate) {
    return true; 
  }
}