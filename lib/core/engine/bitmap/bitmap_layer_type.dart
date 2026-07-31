/// Xác định loại layer trong hệ thống Bitmap Engine.
///
/// Thứ tự render từ dưới lên trên:
///
/// Background
///      ↓
/// Color
///      ↓
/// Preview
///      ↓
/// Selection
///      ↓
/// Outline
///      ↓
/// Overlay
enum BitmapLayerType {
  /// Ảnh nền (nếu có)
  background,

  /// Layer chứa toàn bộ màu người dùng đã tô.
  color,

  /// Layer hiển thị nét cọ tạm thời khi kéo.
  ///
  /// Khi thả tay sẽ được merge vào Color.
  preview,

  /// Layer chứa mask để giới hạn vùng tô.
  ///
  /// Người dùng không nhìn thấy.
  mask,

  /// Layer dùng để highlight vùng đang chọn.
  selection,

  /// Layer chứa toàn bộ đường viền của tranh.
  ///
  /// Layer này luôn nằm trên cùng.
  outline,

  /// Layer phủ hiệu ứng.
  ///
  /// Ví dụ:
  /// - Glow
  /// - Highlight
  /// - Sparkle
  overlay,
}

/// Extension hỗ trợ kiểm tra nhanh.
extension BitmapLayerTypeExtension on BitmapLayerType {
  /// Có cho phép người dùng chỉnh sửa không.
  bool get editable {
    switch (this) {
      case BitmapLayerType.color:
      case BitmapLayerType.preview:
        return true;

      case BitmapLayerType.background:
      case BitmapLayerType.mask:
      case BitmapLayerType.selection:
      case BitmapLayerType.outline:
      case BitmapLayerType.overlay:
        return false;
    }
  }

  /// Có hiển thị lên màn hình không.
  bool get visibleByDefault {
    switch (this) {
      case BitmapLayerType.mask:
        return false;

      case BitmapLayerType.selection:
        return false;

      default:
        return true;
    }
  }

  /// Thứ tự render.
  ///
  /// Giá trị nhỏ hơn sẽ được vẽ trước.
  int get zIndex {
    switch (this) {
      case BitmapLayerType.background:
        return 0;

      case BitmapLayerType.color:
        return 1;

      case BitmapLayerType.preview:
        return 2;

      case BitmapLayerType.selection:
        return 3;

      case BitmapLayerType.outline:
        return 4;

      case BitmapLayerType.overlay:
        return 5;

      case BitmapLayerType.mask:
        return -1;
    }
  }

  /// Tên hiển thị.
  String get displayName {
    switch (this) {
      case BitmapLayerType.background:
        return 'Background';

      case BitmapLayerType.color:
        return 'Color';

      case BitmapLayerType.preview:
        return 'Preview';

      case BitmapLayerType.mask:
        return 'Mask';

      case BitmapLayerType.selection:
        return 'Selection';

      case BitmapLayerType.outline:
        return 'Outline';

      case BitmapLayerType.overlay:
        return 'Overlay';
    }
  }
}