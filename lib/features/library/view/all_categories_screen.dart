import 'package:flutter/material.dart';
import '../data/repository/library_repository.dart';
import 'category_artworks_screen.dart';

class _CategoryLargeCard extends StatelessWidget {
  final Map<String, dynamic> category;

  const _CategoryLargeCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
    
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

    categories = data.map(_mapCategory).toList();

    setState(() {
      loading = false;
    });
  }

  Map<String, dynamic> _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'animals':
        return {
          'title': 'Động vật',
          'icon': '🦁',
          'color': const Color(0xFFFFF0F5),
          'categoryRaw': category,
        };

      case 'alphabets':
        return {
          'title': 'Chữ cái',
          'icon': '🔤',
          'color': const Color(0xFFF0F8FF),
          'categoryRaw': category,
        };

      case 'cartoons':
        return {
          'title': 'Hoạt hình',
          'icon': '👾',
          'color': const Color(0xFFE8F5E9),
          'categoryRaw': category,
        };

      case 'families':
        return {
          'title': 'Gia đình',
          'icon': '👨‍👩‍👧‍👦',
          'color': const Color(0xFFFFF8E1),
          'categoryRaw': category,
        };

      case 'fruits':
        return {
          'title': 'Hoa quả',
          'icon': '🍎',
          'color': const Color(0xFFF3E5F5),
          'categoryRaw': category,
        };

      case 'numbers':
        return {
          'title': 'Số đếm',
          'icon': '123',
          'color': const Color(0xFFFFEBEE),
          'categoryRaw': category,
        };

      case 'trends':
        return {
          'title': 'Thịnh hành',
          'icon': '🔥',
          'color': const Color(0xFFE0F7FA),
          'categoryRaw': category,
        };

      case 'vegetations':
        return {
          'title': 'Thực vật',
          'icon': '🌿',
          'color': const Color(0xFFFFF3E0),
          'categoryRaw': category,
        };

      default:
        return {
          'title': category,
          'icon': '📁',
          'color': Colors.grey.shade100,
          'categoryRaw': category,
        };
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemBuilder: (_, index) {
                  final c = categories[index];
        
                  return _CategoryLargeCard(category: c);
                },
              ),
      ),
    );
  }
}
