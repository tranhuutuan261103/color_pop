// File: action_card.dart
// Chức năng: Card tùy chỉnh dùng để hiển thị các tùy chọn chức năng, hành động với giao diện bắt mắt (Gradient, Icon, Nút bấm).

import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final String title;                    // Tiêu đề chính của card
  final String subtitle;                 // Nội dung mô tả ngắn bên dưới
  final List<Color> gradientColors;      // Danh sách màu tạo hiệu ứng chuyển màu nền (gradient)
  final IconData icon;                   // Biểu tượng hiển thị chính
  final Color? iconColor;                // Màu sắc tùy chọn cho icon (nếu có)
  final List<Widget>? buttons;           // Danh sách các nút bấm tùy chọn đặt ở chân card
  final VoidCallback? onTap;             // Hàm xử lý sự kiện khi người dùng bấm vào toàn bộ card

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    this.iconColor,
    this.buttons,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Cho phép card phản hồi hiệu ứng chạm (ripple effect) nếu có truyền hàm xử lý onTap
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          // Tạo hiệu ứng chuyển màu nền gradient từ góc trên-trái xuống dưới-phải
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          // Tạo độ nổi (shadow) nhẹ nhàng cho card
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần hàng trên: Gồm Tiêu đề, Phụ đề ở bên trái và Icon lớn ở bên phải
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Nếu có truyền iconColor riêng thì hiển thị thêm icon nhỏ đi kèm tiêu đề
                          if (iconColor != null) ...[
                            Icon(icon, color: iconColor, size: 24),
                            const SizedBox(width: 8),
                          ],
                          // Tiêu đề card
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Phụ đề mô tả chức năng
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Khung chứa icon lớn đại diện cho chức năng ở góc phải trên
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
            
            // Phần chân card: Tùy biến hiển thị danh sách nút bấm hoặc icon mũi tên điều hướng
            if (buttons != null) ...[
              const SizedBox(height: 16),
              // Hiển thị các nút bấm nằm ngang được căn đều không gian
              Row(
                children: buttons!
                    .map(
                      (btn) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: btn,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              // Nếu không có nút bấm riêng, hiển thị nút mũi tên chuyển trang ở góc phải dưới
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}