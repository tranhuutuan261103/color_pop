// File: edge_settings_screen.dart
// Chức năng: Màn hình cho phép người dùng tùy chỉnh các thông số tách viền (Edge Detection) trước khi chạy AI Preview.

import 'package:flutter/material.dart';
import '../../../core/processingAI/edge_detection_settings.dart';
import '../widget/basic_settings_section.dart';
import '../widget/soft_edges_section.dart';
import '../widget/hard_edges_section.dart';

class EdgeSettingsScreen extends StatefulWidget {
  const EdgeSettingsScreen({super.key});

  @override
  State<EdgeSettingsScreen> createState() => _EdgeSettingsScreenState();
}

class _EdgeSettingsScreenState extends State<EdgeSettingsScreen> {
  // Trạng thái lưu trữ các thông số tách viền hiện tại (khởi tạo giá trị mặc định)
  EdgeDetectionSettings _settings = const EdgeDetectionSettings();

  /// Đóng màn hình hiện tại và trả cấu hình offline về cho màn hình gọi nó.
  void _continue() {
    Navigator.pop(context, {'settings': _settings});
  }

  /// Cập nhật lại state của màn hình mỗi khi người dùng thay đổi thông số trên các widget con.
  void _updateSettings(EdgeDetectionSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng màu nền chung của ứng dụng (Soft Peach / Pastel Warm)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        // Nút quay lại màn hình trước
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color ?? Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // Tiêu đề AppBar có kèm icon trang trí
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.secondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Processing Parameters',
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.titleLarge?.color ??
                    Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            children: [
              // Nhóm cài đặt thông số chi tiết & nét cơ bản
              BasicSettingsSection(
                settings: _settings,
                onChanged: _updateSettings,
              ),
              const SizedBox(height: 16),

              // Nhóm cài đặt làm mượt viền (Soft Edges)
              SoftEdgesSection(settings: _settings, onChanged: _updateSettings),
              const SizedBox(height: 16),

              // Nhóm chế độ xử lý đường viền cứng (Hard Edges)
              HardEdgesSection(settings: _settings, onChanged: _updateSettings),
              const SizedBox(height: 28),

              // Nút bấm Gradient lớn ở cuối trang để xác nhận và chuyển sang màn hình Preview
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColorDark.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _continue,
                  icon: const Icon(
                    Icons.image_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Preview Result',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
