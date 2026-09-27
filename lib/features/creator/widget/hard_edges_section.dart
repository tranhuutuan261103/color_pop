// File: hard_edges_section.dart
// Chức năng: Widget hiển thị nhóm cài đặt Bước 3 (Tinh chỉnh nâng cao bao gồm Gaussian, Morphology bổ sung và Anti-Alias Sigma).

import 'package:flutter/material.dart';
import '../../../core/processingAI/edge_detection_settings.dart';
import 'settings_tile_helper.dart';

class HardEdgesSection extends StatelessWidget {
  final EdgeDetectionSettings settings;                    // Đối tượng cấu hình hiện tại
  final ValueChanged<EdgeDetectionSettings> onChanged;     // Hàm callback gọi khi thông số thay đổi

  const HardEdgesSection({
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
        boxShadow: [
          BoxShadow(
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
          // Tiêu đề nhóm: Hiển thị số '3' tròn kèm nhãn "Tinh chỉnh nâng cao"
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
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tinh chỉnh nâng cao',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Khối giao diện sẽ bị mờ và khóa tương tác nếu điều kiện sử dụng soft edges trái ngược
          AnimatedOpacity(
            opacity: !settings.useSoftEdges ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: settings.useSoftEdges,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Slider điều chỉnh kích thước Gaussian bổ sung
                  BuildSliderTile(
                    icon: Icons.waves,
                    label: 'Tinh chỉnh hình thái',
                    subtitle: 'Điều chỉnh cấu trúc và hình dạng chi tiết',
                    value: settings.gaussianBlurSize.toDouble(),
                    min: 0,
                    max: 15,
                    divisions: 15,
                    displayValue: settings.gaussianBlurSize.toString(),
                    onChanged: (v) => onChanged(
                      settings.copyWith(gaussianBlurSize: v.toInt()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 2. Slider Morphology bổ sung (Lấp lỗ hổng + lọc nhiễu hạt)
                  BuildSliderTile(
                    icon: Icons.cleaning_services,
                    label: 'Morphology',
                    subtitle: 'Lấp lỗ hổng + loại noise',
                    value: settings.morphologySize.toDouble(),
                    min: 0,
                    max: 7,
                    divisions: 7,
                    displayValue: settings.morphologySize.toString(),
                    onChanged: (v) => onChanged(
                      settings.copyWith(morphologySize: v.toInt()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 3. Slider điều chỉnh độ mượt chống răng cưa (Anti-Alias Sigma)
                  BuildSliderTile(
                    icon: Icons.auto_fix_high,
                    label: 'Anti-Alias Sigma',
                    subtitle: 'Blur nhẹ cuối cùng. 0 = tắt',
                    value: settings.antiAliasSigma,
                    min: 0.0,
                    max: 3.0,
                    divisions: 30, // Chia nhỏ để tùy chỉnh độ mượt tinh tế từng 0.1 đơn vị
                    displayValue: settings.antiAliasSigma.toStringAsFixed(1),
                    onChanged: (v) => onChanged(
                      settings.copyWith(antiAliasSigma: v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}