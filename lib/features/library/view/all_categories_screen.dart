import 'package:flutter/material.dart';
import '../../../common/utils/category_mapper.dart'; 
import '../../../core/repository/library_repository.dart';
import 'category_artworks_screen.dart';

// Widget hiển thị thẻ danh mục
class _CategoryLargeCard extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategoryLargeCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      // Hiệu ứng chạm (Tap)
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryArtworksScreen(
                categoryRaw: category['categoryRaw'],
                visuals: category,
              ),
            ),
          );
        },
    
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: category['color'],
                child: Text(
                  category['icon'],
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Text(
                    category['title'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});
  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final LibraryRepository _repository = const LibraryRepository();
  List<Map<String, dynamic>> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repository.getCategories();
    // Map dữ liệu thô sang định dạng có chứa UI/Visuals (màu, icon)
    categories = data.map((c) => CategoryMapper.getVisuals(c)).toList();
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Explore Categories"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: categories.length,

                // Cấu hình hiển thị lưới: 2 cột
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),

                // Trả về thẻ category card bằng dữ liệu đã chuẩn bị
                itemBuilder: (_, index) {
                  final c = categories[index];
                  return _CategoryLargeCard(category: c);
                },
              ),
      ),
    );
  }
}