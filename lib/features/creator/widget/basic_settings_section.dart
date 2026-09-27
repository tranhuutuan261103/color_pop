// File: basic_settings_section.dart
// Chức năng: Widget hiển thị nhóm cài đặt Bước 1 (Chi tiết & Nét) gồm ngưỡng chi tiết, bật/tắt làm mềm viền và điều chỉnh độ rõ nét.

import 'package:flutter/material.dart';
import '../../../core/processingAI/edge_detection_settings.dart';
import 'settings_tile_helper.dart';

class BasicSettingsSection extends StatelessWidget {
  final EdgeDetectionSettings
  settings; // Đối tượng chứa các thông số cài đặt hiện tại
  final ValueChanged<EdgeDetectionSettings>
  onChanged; // Hàm callback gọi khi có thông số thay đổi

  const BasicSettingsSection({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        // Tạo đổ bóng nhẹ cho card nhóm cài đặt
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phần tiêu đề nhóm: Hiển thị số '1' tròn kèm nhãn "Chi tiết & Nét"
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Chi tiết & Nét',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).textTheme.titleLarge?.color ??
                      Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Slider điều chỉnh độ chi tiết (Threshold)
          BuildSliderTile(
            icon: Icons.tune,
            label: 'Độ chi tiết',
            subtitle: 'Mức ngưỡng',
            value: settings.threshold,
            min: 0.1,
            max: 0.95,
            divisions: 17,
            displayValue: settings.threshold.toStringAsFixed(2),
            // Sử dụng copyWith để cập nhật riêng thuộc tính threshold mà giữ nguyên các giá trị khác
            onChanged: (v) => onChanged(settings.copyWith(threshold: v)),
          ),
          const SizedBox(height: 8),

          // 2. Chọn độ phân giải tối đa của ảnh dùng để tách viền (Patch Max Dimension)
          Text(
            'Chất lượng xử lý offline',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 6),

          // Nhóm nút chọn 2 mức độ phân giải: 512 (Cân bằng) và 768 (Chính xác)
          Center(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 512, label: Text('512 - Cân bằng')),
                ButtonSegment<int>(value: 768, label: Text('768 - Chính xác')),
              ],
              selected: {settings.patchMaxDim},
              onSelectionChanged: (values) {
                onChanged(settings.copyWith(patchMaxDim: values.first));
              },
            ),
          ),
          const SizedBox(height: 8),

          // Chọn quy ước màu đầu ra cho ảnh dùng để tô màu.
          BuildSwitchTile(
            icon: Icons.invert_colors,
            label: 'Viền trắng / nền đen',
            subtitle: 'Tắt để dùng viền đen / nền trắng',
            value: settings.invertColors,
            onChanged: (v) => onChanged(settings.copyWith(invertColors: v)),
          ),
          const SizedBox(height: 8),

          // Công tắc bật/tắt tính năng làm mềm đường viền (Soft Edges)
          BuildSwitchTile(
            icon: Icons.blur_on,
            label: 'Làm mềm đường viền',
            subtitle: 'Giảm răng cưa, làm mượt biên',
            value: settings.useSoftEdges,
            onChanged: (v) => onChanged(settings.copyWith(useSoftEdges: v)),
          ),
          const SizedBox(height: 8),

          // 3. Slider điều chỉnh độ rõ nét (Chỉ cho phép tương tác và hiển thị rõ khi useSoftEdges = true)
          AnimatedOpacity(
            opacity: settings.useSoftEdges
                ? 1.0
                : 0.4, // Làm mờ khi tính năng tắt
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !settings
                  .useSoftEdges, // Chặn chạm/tương tác khi tính năng tắt
              child: BuildSliderTile(
                icon: Icons.wb_sunny_outlined,
                label: 'Độ rõ nét',
                subtitle: 'Tăng cường độ sắc nét tổng thể',
                value: settings.softEdgeClarity,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                displayValue: settings.softEdgeClarity.toInt().toString(),
                onChanged: (v) =>
                    onChanged(settings.copyWith(softEdgeClarity: v)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
