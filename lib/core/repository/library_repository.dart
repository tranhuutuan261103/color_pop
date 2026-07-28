import '../models/artwork_model.dart';
import 'asset_library_datasource.dart';

// Lớp Repository quản lý dữ liệu của Thư viện tranh
class LibraryRepository {
  const LibraryRepository();

  // Lấy danh sách tất cả các bức tranh từ nguồn dữ liệu (Assets/Local)
  Future<List<ArtworkModel>> getAllArtworks() {
    return AssetLibraryDataSource.loadArtworks();
  }

  // Trích xuất và trả về danh sách các danh mục (Categories) có trong hệ thống
  Future<List<String>> getCategories() async {
    final artworks = await getAllArtworks(); // Lấy toàn bộ data tranh
    print("======================");
    // Logic lọc danh mục:
    final categories = artworks
        .map(
          (e) => e.category,
        ) // 1. Lấy ra thuộc tính 'category' của tất cả các tranh
        .toSet() // 2. Ép sang Set để loại bỏ các danh mục trùng lặp
        .toList(); // 3. Ép về List để trả về
    print(categories);
    print("======================");
    categories.sort(); // Sắp xếp danh sách theo bảng chữ cái Alphabet

    return categories;
  }

  // Lọc và lấy danh sách các bức tranh thuộc một danh mục cụ thể
  Future<List<ArtworkModel>> getArtworksByCategory(String category) async {
    final artworks = await getAllArtworks(); // Lấy toàn bộ data tranh
    // Dùng .where() để giữ lại những bức tranh có category khớp với tham số truyền vào
    return artworks.where((e) => e.category == category).toList();
  }
}
