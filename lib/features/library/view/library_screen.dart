import 'package:flutter/material.dart';

import '../data/repository/library_repository.dart';
import '../widgets/library_top_section.dart';
import '../widgets/library_suggestions_list.dart';
import '../widgets/continue_coloring_list.dart';
import '../widgets/library_artwork_grids.dart';
import '../widgets/library_categories_grid.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryRepository _repository = const LibraryRepository();

  List<Map<String, dynamic>> _dynamicCategories = [];
  bool _isLoadingCategories = true;
  int _activeSuggestionsIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      final mappedCategories = categories.map((c) => _getCategoryVisuals(c)).toList();
      if (mounted) {
        setState(() {
          _dynamicCategories = mappedCategories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Map<String, dynamic> _getCategoryVisuals(String category) {
    final Map<String, dynamic> visuals;
    switch (category.toLowerCase()) {
      case 'animals':
        visuals = {'title': 'Động vật', 'icon': '🦁', 'color': const Color(0xFFFFF0F5)};
        break;
      case 'alphabets':
        visuals = {'title': 'Chữ cái', 'icon': '🔤', 'color': const Color(0xFFF0F8FF)};
        break;
      case 'cartoons':
        visuals = {'title': 'Hoạt hình', 'icon': '👾', 'color': const Color(0xFFE8F5E9)};
        break;
      case 'families':
        visuals = {'title': 'Gia đình', 'icon': '👨‍👩‍👧‍👦', 'color': const Color(0xFFFFF8E1)};
        break;
      case 'fruits':
        visuals = {'title': 'Hoa quả', 'icon': '🍎', 'color': const Color(0xFFF3E5F5)};
        break;
      case 'numbers':
        visuals = {'title': 'Số đếm', 'icon': '123', 'color': const Color(0xFFFFEBEE)};
        break;
      case 'trends':
        visuals = {'title': 'Thịnh hành', 'icon': '🔥', 'color': const Color(0xFFE0F7FA)};
        break;
      case 'vegetations':
        visuals = {'title': 'Thực vật', 'icon': '🌿', 'color': const Color(0xFFFFF3E0)};
        break;
      default:
        final title = category.isEmpty ? '' : category[0].toUpperCase() + category.substring(1);
        visuals = {'title': title, 'icon': '📁', 'color': const Color(0xFFF3E5F5)};
        break;
    }
    visuals['categoryRaw'] = category;
    return visuals;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LibraryHeader(),
              const SizedBox(height: 20),
              const LibrarySearchBox(),
              const SizedBox(height: 20),
              LibrarySuggestionsList(
                activeIndex: _activeSuggestionsIndex,
                onTagSelected: (index) {
                  setState(() => _activeSuggestionsIndex = index);
                },
              ),
              const SizedBox(height: 24),
              const LibraryPremiumBanner(),
              const SizedBox(height: 28),

              const LibrarySectionTitle(title: '🖍️ Continue Coloring'),
              const SizedBox(height: 14),
              const ContinueColoringList(),
              const SizedBox(height: 28),

              const LibrarySectionTitle(title: '💖 Recommendations'),
              const SizedBox(height: 14),
              const RecommendationsGrid(),
              const SizedBox(height: 28),

              const LibrarySectionTitle(title: '🔥 Prevailing'),
              const SizedBox(height: 14),
              const TrendingGrid(),
              const SizedBox(height: 28),

              const LibraryCategoryHeader(),
              const SizedBox(height: 14),
              LibraryCategoriesGrid(
                isLoading: _isLoadingCategories,
                categories: _dynamicCategories,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}