import 'package:flutter/material.dart';
import '../../../core/repository/library_repository.dart';
import '../../../core/models/artwork_model.dart';
import '../widgets/artwork_card.dart'; 

class CategoryArtworksScreen extends StatefulWidget {
  final String categoryRaw;
  final Map<String, dynamic> visuals;

  const CategoryArtworksScreen({
    super.key,
    required this.categoryRaw,
    required this.visuals,
  });

  @override
  State<CategoryArtworksScreen> createState() => _CategoryArtworksScreenState();
}

class _CategoryArtworksScreenState extends State<CategoryArtworksScreen> {
  final LibraryRepository _repository = const LibraryRepository();
  
  List<ArtworkModel> _artworks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  // Lấy danh sách ảnh dựa theo categoryRaw được truyền vào từ màn hình trước
  Future<void> _loadArtworks() async {
    try {
      final artworks = await _repository.getArtworksByCategory(widget.categoryRaw);
      if (mounted) {
        setState(() {
          _artworks = artworks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // AppBar tùy chỉnh, hiển thị Icon và Tên của Danh mục ở giữa
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColorDark),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min, // Thu gọn Row vừa bằng nội dung để can giữa chính xác
          children: [
            Text(
              widget.visuals['icon'],
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              widget.visuals['title'],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
          ],
        ),
      ),
      
      body: SafeArea(
        // Xử lý 3 trạng thái: Đang tải -> Rỗng -> Có dữ liệu
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _artworks.isEmpty
                ? const Center(child: Text('Không có tranh nào trong danh mục này.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(20.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.8, // Căn chỉnh tỷ lệ chiều rộng/cao của thẻ Artwork
                    ),
                    itemCount: _artworks.length,
                    itemBuilder: (context, index) {
                      final artwork = _artworks[index];
                      // Sử dụng Widget đã được tách ra, code rất gọn gàng
                      return ArtworkCard(
                        artwork: artwork,
                        visuals: widget.visuals,
                      );
                    },
                  ),
      ),
    );
  }
}