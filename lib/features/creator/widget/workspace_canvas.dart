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
      child: Stack(
        children: [
          InteractiveViewer(
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
                                    showVectorOutline: widget.controller.showVectorOutline,
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
                                        showVectorOutline: widget.controller.showVectorOutline,
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

          // Nút chuyển đổi nhanh so sánh "Viền của viền" nổi trên góc Canvas
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  widget.controller.toggleVectorOutline();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.controller.showVectorOutline
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.controller.showVectorOutline
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.controller.showVectorOutline
                            ? 'Viền của viền: BẬT'
                            : 'Viền của viền: TẮT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
  final bool showVectorOutline;

  ActiveLayerPainter({
    required this.activeData,
    required this.scaleX,
    required this.scaleY,
    this.lineArtImage,
    this.showVectorOutline = true,
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

    // Render đường viền vector khử răng cưa sub-pixel của vùng đang vẽ (Viền của viền)
    // Nằm ngay DƯỚI Line Art để khi viền ảnh phủ lên sẽ ép chặt viền vector vào đúng hình dáng ảnh
    if (showVectorOutline) {
      final vectorOutlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = Colors.black;

      canvas.save();
      canvas.scale(scaleX, scaleY);
      canvas.drawPath(activeData!.clipRegionPath, vectorOutlinePaint);
      canvas.restore();
    }

    // Render Line Art Overlay lên TRÊN CÙNG với BlendMode.multiply
    // Giữ nguyên viền đen 100% sắc nét, ngăn nét cọ che lấp và ép phẳng viền vector
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
  }

  @override
  bool shouldRepaint(covariant ActiveLayerPainter oldDelegate) {
    return true; 
  }
}