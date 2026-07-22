import 'package:flutter/material.dart';

class LibraryMockData {
  // Dữ liệu cho thanh cuộn ngang "Gợi ý"
  static const List<String> suggestions = [
    '🏠 Tất cả',
    '🔖 Đã lưu',
    '🎁 Gói',
    '📅 Hàng ngày',
    '🔥 Thịnh hành',
  ];

  // Dữ liệu cho danh sách Category (dạng lưới gọn gàng)
  static const List<Map<String, dynamic>> categories = [
    {'title': 'Động vật', 'icon': '🦁', 'color': Color(0xFFFFF0F5)},
    {'title': 'Mandala', 'icon': '🏵️', 'color': Color(0xFFF0F8FF)},
    {'title': 'Phong cảnh', 'icon': '🏞️', 'color': Color(0xFFE8F5E9)},
    {'title': 'Hoa lá', 'icon': '🌺', 'color': Color(0xFFFFF8E1)},
    {'title': 'Kỳ ảo', 'icon': '🦄', 'color': Color(0xFFF3E5F5)},
    {'title': 'Nhân vật', 'icon': '👸', 'color': Color(0xFFFFEBEE)},
    {'title': 'Đồ ăn', 'icon': '🍔', 'color': Color(0xFFE0F7FA)},
    {'title': 'Phương tiện', 'icon': '🚗', 'color': Color(0xFFFFF3E0)},
  ];
}