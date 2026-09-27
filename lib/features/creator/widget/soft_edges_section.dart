// File: soft_edges_section.dart
// Chức năng: Widget hiển thị nhóm cài đặt Bước 2 (Chế độ xử lý nâng cao: Làm mờ Gaussian và Tinh chỉnh hình thái) tùy theo điều kiện.

import 'package:flutter/material.dart';
import '../../../core/processingAI/edge_detection_settings.dart';
import 'settings_tile_helper.dart';

class SoftEdgesSection extends StatelessWidget {
  final EdgeDetectionSettings settings;                    // Đối tượng chứa cấu hình hiện tại
  final ValueChanged<EdgeDetectionSettings> onChanged;     // Hàm callback khi thông số thay đổi

  const SoftEdgesSection({
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
          // Tiêu đề nhóm: Hiển thị số '2' tròn kèm nhãn "Chế độ xử lý"
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
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Chế độ xử lý',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Khối giao diện sẽ bị mờ và vô hiệu hóa nếu useSoftEdges thỏa mãn điều kiện ngược lại
          AnimatedOpacity(
            opacity: !settings.useSoftEdges ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: settings.useSoftEdges,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Slider điều chỉnh mức độ làm mờ Gaussian (Khử nhiễu)
                  BuildSliderTile(
                    icon: Icons.blur_on,
                    label: 'Làm mờ Gaussian',
                    subtitle: 'Giảm nhiễu bằng làm mờ trước khi xử lý',
                    value: settings.gaussianBlurSize.toDouble(), // Chuyển int sang double cho slider
                    min: 0,
                    max: 15,
                    divisions: 15,
                    displayValue: settings.gaussianBlurSize.toString(),
                    onChanged: (v) => onChanged(
                      settings.copyWith(gaussianBlurSize: v.toInt()), // Chuyển double về int khi lưu
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 2. Slider điều chỉnh tinh chỉnh hình thái học (Morphology)
                  BuildSliderTile(
                    icon: Icons.crop_square,
                    label: 'Tinh chỉnh hình thái',
                    subtitle: 'Làm đầy lỗ hổng và loại bỏ nhiễu nhỏ',
                    value: settings.morphologySize.toDouble(),
                    min: 0,
                    max: 7,
                    divisions: 7,
                    displayValue: settings.morphologySize.toString(),
                    onChanged: (v) => onChanged(
                      settings.copyWith(morphologySize: v.toInt()),
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