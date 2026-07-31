import 'dart:ui';

/// Trạng thái hiện tại của công cụ tô màu, dùng cho UI và controller.
class ColoringState {
  const ColoringState({
    this.tool = ColoringTool.fill,
    this.color = const Color(0xFF03A9F4),
    this.strokeWidth = 8.0,
    this.isEraser = false,
  });

  final ColoringTool tool;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  ColoringState copyWith({
    ColoringTool? tool,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
  }) {
    return ColoringState(
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}

enum ColoringTool { fill, erase, brush, pencil, spray }
