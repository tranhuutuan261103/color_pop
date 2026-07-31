import 'dart:collection';

import 'bitmap_buffer.dart';
import 'bitmap_layer.dart';
import 'bitmap_layer_type.dart';
import 'bitmap_surface.dart';

/// Quản lý toàn bộ layer trong Bitmap Engine.
class BitmapStack {
  BitmapStack();

  final List<BitmapLayer> _layers = [];

  BitmapLayer? _activeLayer;

  int _nextLayerId = 0;

  /// Danh sách layer (read-only).
  UnmodifiableListView<BitmapLayer> get layers =>
      UnmodifiableListView(_layers);

  /// Layer đang được chỉnh sửa.
  BitmapLayer? get activeLayer => _activeLayer;

  int get length => _layers.length;

  bool get isEmpty => _layers.isEmpty;

  bool get isNotEmpty => _layers.isNotEmpty;

  /// Khởi tạo các layer mặc định.
  factory BitmapStack.createDefault({
    required int width,
    required int height,
  }) {
    final stack = BitmapStack();

    for (final type in BitmapLayerType.values) {
      stack.addLayer(
        BitmapLayer(
          id: stack._generateLayerId(),
          type: type,
          surface: BitmapSurface(
            buffer: BitmapBuffer(
              width: width,
              height: height,
            ),
          ),
        ),
      );
    }

    stack.setActiveLayer(BitmapLayerType.color);

    return stack;
  }

  int _generateLayerId() {
    return _nextLayerId++;
  }

  /// Thêm layer.
  void addLayer(BitmapLayer layer) {
    _layers.add(layer);

    _sortLayers();

    _activeLayer ??= layer.editable ? layer : null;
  }

  /// Xóa layer.
  bool removeLayer(BitmapLayerType type) {
    final layer = getLayer(type);

    if (layer == null) {
      return false;
    }

    _layers.remove(layer);

    if (_activeLayer == layer) {
      _activeLayer = editableLayers.isNotEmpty
          ? editableLayers.first
          : null;
    }

    return true;
  }

  /// Lấy layer theo type.
  BitmapLayer? getLayer(BitmapLayerType type) {
    for (final layer in _layers) {
      if (layer.type == type) {
        return layer;
      }
    }

    return null;
  }

  /// Lấy layer theo id.
  BitmapLayer? getLayerById(int id) {
    for (final layer in _layers) {
      if (layer.id == id) {
        return layer;
      }
    }

    return null;
  }

  /// Các layer có thể chỉnh sửa.
  List<BitmapLayer> get editableLayers =>
      _layers.where((e) => e.editable).toList();

  /// Các layer hiển thị để render.
  List<BitmapLayer> get renderLayers {
    final result = List<BitmapLayer>.from(_layers);

    result.sort(
      (a, b) => a.zIndex.compareTo(b.zIndex),
    );

    return result.where((e) => e.visible).toList();
  }

  /// Đặt active layer.
  bool setActiveLayer(BitmapLayerType type) {
    final layer = getLayer(type);

    if (layer == null) {
      return false;
    }

    if (!layer.editable) {
      return false;
    }

    _activeLayer = layer;

    return true;
  }

  /// Kiểm tra tồn tại.
  bool contains(BitmapLayerType type) {
    return getLayer(type) != null;
  }

  /// Hiển thị / Ẩn layer.
  void toggleVisible(BitmapLayerType type) {
    final layer = getLayer(type);

    layer?.toggleVisible();
  }

  /// Khóa / Mở khóa layer.
  void toggleLocked(BitmapLayerType type) {
    final layer = getLayer(type);

    layer?.toggleLocked();
  }

  /// Xóa tất cả layer có thể chỉnh sửa.
  void clearEditableLayers() {
    for (final layer in editableLayers) {
      layer.clear();
    }
  }

  /// Reset toàn bộ bitmap.
  void clearAllLayers() {
    for (final layer in _layers) {
      layer.surface.clear();
    }
  }

  /// Clone stack.
  BitmapStack clone() {
    final stack = BitmapStack();

    stack._nextLayerId = _nextLayerId;

    for (final layer in _layers) {
      stack.addLayer(layer.clone());
    }

    if (_activeLayer != null) {
      stack.setActiveLayer(_activeLayer!.type);
    }

    return stack;
  }

  void _sortLayers() {
    _layers.sort(
      (a, b) => a.zIndex.compareTo(b.zIndex),
    );
  }

  @override
  String toString() {
    return '''
BitmapStack(
  layers: ${_layers.length},
  active: ${_activeLayer?.name}
)
''';
  }
}