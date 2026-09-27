// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Định nghĩa trạng thái tô màu động của người dùng (User Canvas State).
// Lưu trữ tập trung các vùng đã đổ màu (Region Fills) và các nét vẽ tự do (Freehand Strokes) gắn liền với từng Region.

import 'dart:ui';
import 'tool_type.dart';

/// Đại diện cho một nét vẽ tay tự do do người dùng quẹt trên màn hình
class FreehandStroke {
  /// Danh sách các điểm tọa độ mà đường cọ đi qua
  final List<Offset> points;

  /// Màu sắc của nét cọ
  final Color color;

  /// Kích thước / Kích thước nét cọ (Stroke width)
  final double size;

  /// Loại công cụ vẽ được sử dụng (Ví dụ: Bút chì, cọ màu nước, cọ sáp...)
  final ToolType type;

  FreehandStroke({
    required this.points,
    required this.color,
    required this.size,
    required this.type,
  });
}

/// Trạng thái lưu trữ việc tô màu của người dùng trên toàn bộ tài liệu
class PaintState {
  /// Mapping từ Region ID sang màu do người dùng chọn (Chỉ lưu những vùng đã bị đổi màu để tối ưu dung lượng)
  final Map<int, Color> regionFills;

  /// Mapping từ Region ID sang danh sách các nét vẽ tay tự do nằm trong vùng đó
  final Map<int, List<FreehandStroke>> regionStrokes;

  PaintState({Map<int, Color>? regionFills, Map<int, List<FreehandStroke>>? regionStrokes})
      : regionFills = regionFills ?? {},
        regionStrokes = regionStrokes ?? {};

  /// Cập nhật/Ghi đè màu tô cho một Region cụ thể (Dùng cho công cụ Flood Fill / Tap-to-Fill)
  void setRegionColor(int regionId, Color color) {
    regionFills[regionId] = color;
  }

  /// Lấy màu mà người dùng đã tô cho Region. Trả về null nếu vùng này chưa được tô màu
  Color? getRegionColor(int regionId) {
    return regionFills[regionId];
  }

  /// Thêm một nét vẽ tay tự do mới vào Region chỉ định
  void addStroke(int regionId, FreehandStroke stroke) {
    // Nếu chưa có mảng chứa nét vẽ cho regionId này thì tự động khởi tạo mảng rỗng rồi add stroke vào
    regionStrokes.putIfAbsent(regionId, () => []).add(stroke);
  }

  /// Lấy danh sách toàn bộ các nét vẽ tay tự do của một Region
  List<FreehandStroke> getStrokes(int regionId) {
    return regionStrokes[regionId] ?? [];
  }

  /// Xóa sạch màu tô và nét vẽ tay của một Region (Đưa Region về trạng thái phôi gốc)
  void clearRegion(int regionId) {
    regionFills.remove(regionId);
    regionStrokes.remove(regionId);
  }

  /// Dùng khi người dùng đổ màu (Fill) đè lên khu vực đã vẽ nét.
  void clearStrokesInRegion(int regionId) {
    regionStrokes.remove(regionId);
  }
}