import 'package:flutter/material.dart';
import '../constants/workspace_colors.dart';
import '../models/active_stroke_data.dart';
import 'workspace_base_state.dart';

/// Mixin xử lý sự kiện chạm vẽ (touch events)
mixin WorkspaceTouchHandler on WorkspaceBaseState {
  /// Bước 1: Ngón tay vừa chạm vào màn hình (Bắt đầu vẽ)
  void handlePointerDown(Offset localPosition, Size canvasSize) {
    if (document == null || spatialIndex == null || paintEngine == null) return;

    // Quy đổi tọa độ màn hình điện thoại sang tọa độ thực tế của bức tranh
    final scaleX = document!.width / canvasSize.width;
    final scaleY = document!.height / canvasSize.height;
    final docPoint = Offset(
      localPosition.dx * scaleX,
      localPosition.dy * scaleY,
    );

    // Tìm xem tọa độ này đang nằm ở Vùng (Region) số mấy
    var region = spatialIndex!.getRegionAtPoint(docPoint);
    if (region == null || region.isStroke) {
      region = spatialIndex!.getNearestRegion(docPoint, maxDistance: 12.0);
    }

    if (region != null && !region.isStroke) {
      if (isFillTool) {
        // Công cụ cái xô (Fill): Đổ màu lập tức, báo Lớp Nền vẽ lại toàn bộ
        paintEngine!.onPointerDown(docPoint, region.id);
        notifyListeners();
      } else {
        // Công cụ Cọ/Chì/Tẩy/Phun sơn: Chuẩn bị vẽ
        final clipRegionPath = spatialIndex!.getRegionPath(region.id);

        if (clipRegionPath != null) {
          final newStroke = Path()..moveTo(docPoint.dx, docPoint.dy);
          double brushWidth = sliderValue * 20 + 5;
          if (selectedToolIndex == 2) {
            // Cọ lớn (Large Brush): kích thước từ 15px đến 45px
            brushWidth = sliderValue * 30 + 15;
          }

          activeStrokeNotifier.value = ActiveStrokeData(
            strokePath: newStroke,
            clipRegionPath: clipRegionPath,
            color: workspaceColors[selectedColorIndex],
            strokeWidth: brushWidth,
            isEraser: isEraserTool,
            regionId: region.id,
            lastPoint: docPoint,
            isPaused: false,
          );
        }

        // Bơm điểm chạm đầu tiên vào PaintEngine (âm thầm)
        paintEngine!.onPointerDown(docPoint, region.id);
      }
    }
  }

  /// Bước 2: Ngón tay đang di chuyển (Kéo nét)
  void handlePointerMove(Offset localPosition, Size canvasSize) {
    if (activeStrokeNotifier.value != null && !isFillTool) {
      final scaleX = document!.width / canvasSize.width;
      final scaleY = document!.height / canvasSize.height;
      final docPoint = Offset(
        localPosition.dx * scaleX,
        localPosition.dy * scaleY,
      );

      final currentData = activeStrokeNotifier.value!;

      // 1. Kiểm tra xem điểm đến có nằm trong Region ban đầu hay không
      final isInside = spatialIndex!.isInsideRegion(
        currentData.regionId,
        docPoint,
        tolerance: 2.0,
      );

      // 2. Kiểm tra xem điểm đến có chạm vào pixel của nét viền đen không
      final onBlack = spatialIndex!.isBlack(docPoint, threshold: 75);

      if (!currentData.isPaused) {
        // ĐANG VẼ BÌNH THƯỜNG:
        // Kiểm tra xem đoạn di chuyển từ lastPoint đến docPoint có đâm xuyên qua viền đen không
        final crossedLine = spatialIndex!.segmentCrossesLine(
          currentData.lastPoint,
          docPoint,
          threshold: 75,
        );

        if (!isInside || onBlack || crossedLine) {
          // Gặp viền đen hoặc ranh giới: Tìm điểm an toàn cuối cùng sát viền
          final safePoint = spatialIndex!.findLastSafePoint(
            currentData.lastPoint,
            docPoint,
            currentData.regionId,
          );
          if (safePoint != null && (safePoint - currentData.lastPoint).distance > 0.5) {
            currentData.strokePath.lineTo(safePoint.dx, safePoint.dy);
            paintEngine!.onPointerMove(safePoint, currentData.regionId);
          }
          // Chuyển sang trạng thái tạm dừng tại điểm an toàn mà KHÔNG cắt đứt nét vẽ
          activeStrokeNotifier.value = currentData.copyWith(
            lastPoint: safePoint ?? currentData.lastPoint,
            isPaused: true,
          );
        } else {
          // Nét vẽ hoàn toàn hợp lệ trong khoảng trắng: Kéo nét tiếp
          currentData.strokePath.lineTo(docPoint.dx, docPoint.dy);
          paintEngine!.onPointerMove(docPoint, currentData.regionId);
          activeStrokeNotifier.value = currentData.copyWith(
            lastPoint: docPoint,
            isPaused: false,
          );
        }
      } else {
        // ĐANG TẠM DỪNG (ngón tay chạm viền hoặc kéo ra ngoài):
        // Khi người dùng kéo ngón tay quay trở lại vùng trắng hợp lệ:
        // Đảm bảo đoạn từ lastPoint đến docPoint KHÔNG cắt qua viền đen (cùng một phía của rào cản)
        final canReturn = isInside &&
            !onBlack &&
            !spatialIndex!.segmentCrossesLine(
              currentData.lastPoint,
              docPoint,
              threshold: 75,
            );

        if (canReturn) {
          // Tiếp tục kéo nét quay về mượt mà, không đứt đoạn và tuyệt đối không xuyên qua viền
          currentData.strokePath.lineTo(docPoint.dx, docPoint.dy);
          paintEngine!.onPointerMove(docPoint, currentData.regionId);
          activeStrokeNotifier.value = currentData.copyWith(
            lastPoint: docPoint,
            isPaused: false,
          );
        }
      }
    }
  }

  /// Bước 3: Ngón tay nhấc lên khỏi màn hình (Chốt nét)
  void handlePointerUp() {
    if (activeStrokeNotifier.value != null) {
      activeStrokeNotifier.value = null;
      paintEngine!.onPointerUp();
      notifyListeners();
    } else {
      paintEngine?.onPointerUp();
      notifyListeners();
    }
  }

  /// Đổ màu trực tiếp vào 1 vùng bằng ID
  void applyColorToRegion(int regionId, Color color) {
    if (document == null) return;
    document!.paintState.setRegionColor(regionId, color);
    notifyListeners();
  }
}
