// File color_pop_document.dart

// [FILE ĐỊNH DẠNG CẤU TRÚC]
// Đây là model gốc (Root) định nghĩa toàn bộ dữ liệu của một bức tranh trong định dạng mới.
// Nó bao gồm cấu trúc hình học (regions), trạng thái tô màu của user (paintState) 
// và thông tin phụ (metadata).

import '../topology/region.dart';
import 'paint_state.dart';

/// Chứa các thông tin phụ trợ về nguồn gốc của file dữ liệu
class Metadata {
  final int createdAt;            // Thời gian tạo file (Timestamp)
  final String sourceImageHash;   // Mã băm của ảnh gốc, dùng để đối chiếu, verify hoặc cache
  final double globalConfidence;  // Độ tin cậy của thuật toán bóc tách nét vẽ từ ảnh gốc (ví dụ: 0.0 -> 1.0)

  Metadata({
    required this.createdAt,
    required this.sourceImageHash,
    required this.globalConfidence,
  });
}

/// Model bao trùm toàn bộ một bức tranh để render lên Canvas
class ColorPopDocument {
  final int version;    // Phiên bản của cấu trúc file (Dùng để migration data khi app update sau này)
  final double width;   // Original logical width
  final double height;  // Original logical height
  final List<Region> regions; // Cấu trúc topology tĩnh: Danh sách các vùng có thể tô màu hoặc các nét vẽ
  final PaintState paintState; // Trạng thái động: Chứa dữ liệu lịch sử/hiện tại về các màu mà user đã tô
  final Metadata metadata; // Các thông tin siêu dữ liệu đi kèm

  ColorPopDocument({
    required this.version, 
    required this.width,
    required this.height,
    required this.regions,
    PaintState? paintState,
    required this.metadata,
  }) : paintState = paintState ?? PaintState(); // Khởi tạo state trống nếu user chưa tô gì

  // Kiểm tra xem file document này có đủ điều kiện hợp lệ để render không
  bool isValid() {
    return width > 0 && height > 0 && regions.isNotEmpty;
  }
}
