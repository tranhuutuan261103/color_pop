import 'package:flutter/material.dart';

class CategoryMapper {
  /// Converts a category string into a Map containing visual properties
  /// (Title, Icon, Background Color).
  static Map<String, dynamic> getVisuals(String category) {
    final Map<String, dynamic> visuals;

    // Sử dụng .trim() để loại bỏ các khoảng trắng thừa từ API/Database
    switch (category.trim().toLowerCase()) {
      case 'animals':
        visuals = {'title': 'Animals', 'icon': '🦁', 'color': const Color(0xFFFFF0F5)};
        break;
      case 'nature':
        visuals = {'title': 'Nature', 'icon': '🌿', 'color': const Color(0xFFE8F5E9)};
        break;
      case 'patterns':
        visuals = {'title': 'Patterns', 'icon': '🌀', 'color': const Color(0xFFF3E5F5)};
        break;
      case 'fantasy':
        visuals = {'title': 'Fantasy', 'icon': '🦄', 'color': const Color(0xFFEDE7F6)};
        break;
      case 'characters':
        visuals = {'title': 'Characters', 'icon': '🧑', 'color': const Color(0xFFFFF3E0)};
        break;
      case 'lifestyle':
        visuals = {'title': 'Lifestyle', 'icon': '☕', 'color': const Color(0xFFFFF8E1)};
        break;
      case 'events':
        visuals = {'title': 'Events', 'icon': '🎉', 'color': const Color(0xFFFFEBEE)};
        break;
      case 'kids_basics':  
        visuals = {'title': 'Kids Basics', 'icon': '🔤', 'color': const Color(0xFFE0F7FA)};
        break;
      case 'typography':
        visuals = {'title': 'Typography', 'icon': '✍️', 'color': const Color(0xFFECEFF1)};
        break;
      case 'travel_and_places':
        visuals = {'title': 'Travel & Places', 'icon': '✈️', 'color': const Color(0xFFE3F2FD)};
        break;
      case 'sports_and_action':
        visuals = {'title': 'Sports & Action', 'icon': '⚽', 'color': const Color(0xFFFBE9E7)};
        break;
      case 'dark_and_gothic':
        visuals = {'title': 'Dark & Gothic', 'icon': '💀', 'color': const Color(0xFFEFEBE9)};
        break;
      case 'spirituality':
        visuals = {'title': 'Spirituality', 'icon': '🧘', 'color': const Color(0xFFF3E5F5)};
        break;
      case 'science_and_education':
        visuals = {'title': 'Science & Education', 'icon': '🔬', 'color': const Color(0xFFE8EAF6)};
        break;
      case 'tattoo_art':
        visuals = {'title': 'Tattoo Art', 'icon': '🖋️', 'color': const Color(0xFFFFF0F5)};
        break;
      case 'music_and_arts':
        visuals = {'title': 'Music & Arts', 'icon': '🎵', 'color': const Color(0xFFFFF9C4)};
        break;
      case 'history_and_eras':
        visuals = {'title': 'History & Eras', 'icon': '🏛️', 'color': const Color(0xFFD7CCC8)};
        break;
      case 'fairytales_and_stories':
        visuals = {'title': 'Fairytales & Stories', 'icon': '📖', 'color': const Color(0xFFF8BBD0)};
        break;
      case 'abstract_and_surreal':
        visuals = {'title': 'Abstract & Surreal', 'icon': '🎨', 'color': const Color(0xFFE1BEE7)};
        break;
      case 'careers_and_professions':
        visuals = {'title': 'Careers', 'icon': '💼', 'color': const Color(0xFFCFD8DC)};
        break;
      case 'world_and_nations':
        visuals = {'title': 'World & Nations', 'icon': '🌍', 'color': const Color(0xFFC8E6C9)};
        break;
      case 'military_and_forces':
        visuals = {'title': 'Military', 'icon': '🪖', 'color': const Color(0xFFBCAAA4)};
        break;
      case 'vietnamese_heritage':
        visuals = {'title': 'Vietnamese Heritage', 'icon': '🇻🇳', 'color': const Color(0xFFFFCDD2)};
        break;
      default:
        // Fallback xử lý nếu thư mục chưa được định nghĩa
        final title = category.isEmpty
            ? ''
            : category[0].toUpperCase() + category.substring(1).replaceAll('_', ' ');
        visuals = {'title': title, 'icon': '📁', 'color': const Color(0xFFF3E5F5)};
        break;
    }
    
    // Gắn thêm categoryRaw để trả về
    visuals['categoryRaw'] = category;
    return visuals;
  }
}