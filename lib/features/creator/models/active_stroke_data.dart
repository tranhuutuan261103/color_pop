import 'dart:ui';

/// Lưu trữ dữ liệu tạm thời của nét vẽ đang được thực hiện (ngón tay chưa nhấc lên).
/// Giúp UI chỉ cần render lại nét này (cực nhẹ) thay vì render lại toàn bộ bức tranh.
class ActiveStrokeData {
  final Path strokePath; // Quỹ đạo ngón tay người dùng
  final Path
  clipRegionPath; // Khuôn (mặt nạ) của vùng đang tô, dùng để xén phần màu lem ra ngoài
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final int regionId; // ID của vùng đang được vẽ
  final Offset lastPoint; // Điểm cuối cùng đã được chấp nhận vào nét
  final bool isPaused; // Tạm dừng khi ngón tay đang ở ngoài vùng

  ActiveStrokeData({
    required this.strokePath,
    required this.clipRegionPath,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    required this.regionId,
    required this.lastPoint,
    this.isPaused = false,
  });

  ActiveStrokeData copyWith({
    Path? strokePath,
    Path? clipRegionPath,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
    int? regionId,
    Offset? lastPoint,
    bool? isPaused,
  }) {
    return ActiveStrokeData(
      strokePath: strokePath ?? this.strokePath,
      clipRegionPath: clipRegionPath ?? this.clipRegionPath,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
      regionId: regionId ?? this.regionId,
      lastPoint: lastPoint ?? this.lastPoint,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
