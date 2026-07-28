import 'package:flutter/material.dart';
import '../../../common/constants/app_colors.dart';
import '../../../core/models/artwork_model.dart';
import '../../creator/view/workspace_screen.dart';

/// Widget độc lập đại diện cho một thẻ Artwork.
/// Việc tách riêng giúp tái sử dụng ở nhiều màn hình khác (Home, Search...)
/// và làm code màn hình chính sạch sẽ hơn.
class ArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final Map<String, dynamic> visuals;

  const ArtworkCard({
    super.key,
    required this.artwork,
    required this.visuals,
  });

  @override
  Widget build(BuildContext context) {
    // Dùng GestureDetector để bắt sự kiện người dùng chạm vào toàn bộ thẻ
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkspaceScreen(imagePath: artwork.imagePath),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          // Tạo đổ bóng nhẹ cho card
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Cắt bỏ phần tử con bị tràn ra khỏi bo góc của card
        clipBehavior: Clip.antiAlias,
        
        // Sử dụng Stack để xếp chồng các widget (Ảnh/Text nằm dưới, các Badge nằm trên)
        child: Stack(
          children: [
            // Lớp dưới cùng: Ảnh và Thông tin
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phần hiển thị hình ảnh (tự chiếm không gian còn lại)
                Expanded(
                  child: Container(
                    color: visuals['color'],
                    child: Image.asset(
                      artwork.imagePath,
                      fit: BoxFit.cover,
                      // Xử lý an toàn khi không load được ảnh
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint("ERROR IMAGE: ${artwork.imagePath}");
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.withOpacity(0.5),
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Phần hiển thị Text (Tiêu đề và tên danh mục)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visuals['title'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Lớp đè trên: Icon Bookmark (Góc trên trái)
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

            // Lớp đè trên: Nhãn NEW hoặc HOT (Góc trên phải) - Chỉ hiện khi thỏa điều kiện
            if (artwork.isNew || artwork.isHot)
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
                    artwork.isNew ? 'NEW' : 'HOT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}