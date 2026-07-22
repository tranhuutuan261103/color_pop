import 'package:flutter/material.dart';
import '../../../common/constants/app_colors.dart';
import '../constants/library_mock_data.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Giữ nguyên các khai báo của bạn
  // final LibraryRepository _repository = const LibraryRepository();
  // List<ArtworkModel> _allArtworks = [];
  // List<ArtworkModel> _filteredArtworks = [];
  // bool _isLoading = true;

  int _activeSuggestionsIndex = 0;

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
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBox(),
              const SizedBox(height: 20),

              _buildCategories(), // Thanh cuộn ngang Gợi ý

              const SizedBox(height: 24),
              _buildPremiumBanner(),
              const SizedBox(height: 28),

              _buildSectionTitle('🖍️ Tiếp tục tô màu'),
              const SizedBox(height: 14),
              _buildContinueList(),
              const SizedBox(height: 28),

              _buildSectionTitle('💖 Gợi ý cho bạn'),
              const SizedBox(height: 14),
              _buildSuggestionsGrid(),
              const SizedBox(height: 28),

              _buildSectionTitle('🔥 Thịnh hành'),
              const SizedBox(height: 14),
              _buildTrendingGrid(),
              const SizedBox(height: 28),

              // ---- KHU VỰC CATEGORY MỚI ĐƯỢC THÊM VÀO ----
              _buildCategoryHeader(),
              const SizedBox(height: 14),
              _buildCategoriesGrid(),

              const SizedBox(height: 60), // Extra padding ở cuối màn hình
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Thư viện 📚',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('🎨', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Text('🔍', style: TextStyle(fontSize: 18)),
          hintText: 'Tìm tranh tô màu...',
          hintStyle: TextStyle(color: AppColors.secondaryText, fontSize: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // Chú ý: Đã lấy data từ LibraryMockData
  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: LibraryMockData.suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isActive = index == _activeSuggestionsIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSuggestionsIndex = index; // Đã sửa lỗi biến ở đây
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.secondaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '👑 Mở khóa 1.000.000+ tranh',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Dùng thử',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColorDark,
      ),
    );
  }

  Widget _buildContinueList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildContinueCard(
            title: 'Gấu Teddy dễ thương',
            progress: 0.75,
            icon: '🧸',
            bgColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            statusText: '⏸ Đang tạm dừng',
            statusBgColor: const Color(0xFFE8F5E9),
            statusTextColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 14),
          _buildContinueCard(
            title: 'Kỳ lân giữa trời sao',
            progress: 0.30,
            icon: '🦄',
            bgColor: Theme.of(context).primaryColor.withOpacity(0.2),
            statusText: '▶ Bắt đầu',
            statusBgColor: const Color(0xFFFFF3E0),
            statusTextColor: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueCard({
    required String title,
    required double progress,
    required String icon,
    required Color bgColor,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã hoàn thành ${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.8,
      children: [
        _buildGridCard(
          title: 'Mèo con ngủ ngày',
          subtitle: 'Mới nhất',
          icon: '🐱',
          bgColor: const Color(0xFFFFF0F5),
        ),
        _buildGridCard(
          title: 'Gấu Bắc Cực',
          subtitle: 'Phổ biến',
          icon: '🐻',
          bgColor: const Color(0xFFF0F8FF),
          isNew: true,
          hasPlay: true,
        ),
        _buildGridCard(
          title: 'Vườn hoa anh đào',
          subtitle: 'Thư giãn',
          icon: '🌸',
          bgColor: const Color(0xFFFFF8E1),
          hasPlay: true,
        ),
        _buildGridCard(
          title: 'Cáo con tinh nghịch',
          subtitle: 'Dễ thương',
          icon: '🦊',
          bgColor: const Color(0xFFE8F5E9),
        ),
      ],
    );
  }

  Widget _buildTrendingGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.8,
      children: [
        _buildGridCard(
          title: 'Nàng tiên cá',
          subtitle: 'Fantasy',
          icon: '🧜‍♀️',
          bgColor: const Color(0xFFF3E5F5),
        ),
        _buildGridCard(
          title: 'Dâu tây ngọt ngào',
          subtitle: 'Food',
          icon: '🍓',
          bgColor: const Color(0xFFFFEBEE),
          isHot: true,
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color bgColor,
    bool isNew = false,
    bool isHot = false,
    bool hasPlay = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: bgColor,
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 60)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bookmark icon
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🔖', style: TextStyle(fontSize: 14)),
            ),
          ),

          if (isNew || isHot)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isNew ? 'NEW' : 'HOT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          if (hasPlay)
            Positioned(
              bottom: 60, // Above the text section
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  '▶',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET CATEGORY MỚI THÊM
  // ==========================================

  Widget _buildCategoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('🗂️ Khám phá danh mục'),
        GestureDetector(
          onTap: () {
            // TODO: Navigate sang màn hình xem toàn bộ Category
          },
          child: Text(
            'Xem tất cả',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    // Chỉ lấy 6 items đầu tiên trong danh sách để hiển thị gọn gàng trên màn chính
    final displayItems = LibraryMockData.categories.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4, // Tỷ lệ giúp thẻ category nằm ngang dẹt lại
      ),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final category = displayItems[index];
        return _buildCategoryCompactCard(
          title: category['title'],
          icon: category['icon'],
          bgColor: category['color'],
        );
      },
    );
  }

  Widget _buildCategoryCompactCard({
    required String title,
    required String icon,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Xử lý khi nhấn vào category
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
