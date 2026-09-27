// File: creator_app_bar.dart
// Chức năng: AppBar cho màn hình Creator.

import 'package:flutter/material.dart';

/// Thanh tiêu đề (AppBar) tùy chỉnh dành riêng cho màn hình Creator.
/// Hiển thị tiêu đề lớn đậm và một huy hiệu (badge) dạng pill ở góc phải 
/// để hiển thị số lượng điểm/stars kèm nút thêm nhanh.
class CreatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CreatorAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Đồng bộ màu nền của AppBar với màu nền chung của màn hình (Scaffold)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0, // Loại bỏ hiệu ứng bóng đổ mặc định để tạo phong cách thiết kế phẳng (flat)
      title: Text(
        'Creator',
        style: TextStyle(
          // Tự động đổi màu chữ theo theme sáng/tối hiện tại của ứng dụng
          color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
          fontWeight: FontWeight.w900,
          fontSize: 26,
        ),
      ),
      actions: [
        // Container tạo hình chiếc nhãn (pill) chứa icon ngôi sao, số lượng và nút cộng ở góc phải
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon tượng trưng cho điểm số hoặc phần thưởng (stars)
              Icon(Icons.stars, color: Theme.of(context).primaryColor, size: 18),
              
              const SizedBox(width: 6),
              // Hiển thị giá trị số lượng hiện tại (đang đặt mặc định là '0')
              Text(
                '0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                ),
              ),
              const SizedBox(width: 8),

              // Nút hình tròn chứa dấu cộng dùng để thêm mới hoặc tăng giá trị
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.add, color: Colors.white, size: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}