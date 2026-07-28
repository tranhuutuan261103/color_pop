import 'package:flutter/material.dart';

import '../../../core/repository/library_repository.dart';
import '../../../common/utils/category_mapper.dart';
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
  // Lớp giao tiếp với dữ liệu (Database/API)
  final LibraryRepository _repository = const LibraryRepository();

  List<Map<String, dynamic>> _dynamicCategories = [];
  bool _isLoadingCategories = true; // Tải dữ liệu danh mục từ repository
  int _activeSuggestionsIndex = 0; // Chỉ số của tab gợi ý đang được chọn

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Lấy dữ liệu danh mục từ backend/local storage thông qua _repository
  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      final mappedCategories = categories
          .map((c) => CategoryMapper.getVisuals(c))
          .toList();
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

              // Thanh lọc/gợi ý ngang
              LibrarySuggestionsList(
                activeIndex: _activeSuggestionsIndex,
                onTagSelected: (index) {
                  setState(() => _activeSuggestionsIndex = index);
                },
              ),
              const SizedBox(height: 24),

              const LibraryPremiumBanner(),
              const SizedBox(height: 28),

              // Section: Các bức tranh đang tô
              const LibrarySectionTitle(title: '🖍️ Continue Coloring'),
              const SizedBox(height: 14),
              const ContinueColoringList(),
              const SizedBox(height: 28),

              // Section: Đề xuất
              const LibrarySectionTitle(title: '💖 Recommendations'),
              const SizedBox(height: 14),
              const RecommendationsGrid(),
              const SizedBox(height: 28),

              // Section: Đang thịnh hành
              const LibrarySectionTitle(title: '🔥 Prevailing'),
              const SizedBox(height: 14),
              const TrendingGrid(),
              const SizedBox(height: 28),

              // Section: Các danh mục (Data động được load từ API)
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
