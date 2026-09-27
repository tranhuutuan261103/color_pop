// File: server_mode_card.dart
// Chức năng: Thẻ tùy chọn (Card) cho phép người dùng bật/tắt tính năng xử lý ảnh qua máy chủ (Cloud) hoặc xử lý nội bộ (Local).

import 'package:flutter/material.dart';

class ServerModeCard extends StatelessWidget {
  final bool useServer;                   // Trạng thái hiện tại: true = dùng server, false = dùng local
  final ValueChanged<bool> onChanged;     // Hàm callback gọi khi người dùng gạt công tắc thay đổi trạng thái

  const ServerModeCard({
    super.key,
    required this.useServer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        // Tạo bóng đổ nhẹ cho card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Viền màu chủ đạo mờ để làm nổi bật thẻ cấu hình này
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Khung chứa icon đồng bộ mây đại diện cho chế độ server
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.cloud_sync, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 14),
          // Phần tiêu đề và mô tả ngắn gọn về chế độ server
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xử lý trên máy chủ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chất lượng cao hơn, cần kết nối mạng',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Công tắc tự động thích ứng giao diện giữa Android và iOS
          Switch.adaptive(
            value: useServer,
            onChanged: onChanged,
            // ignore: deprecated_member_use
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}