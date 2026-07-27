import '../../model/artwork_model.dart';
import '../datasource/asset_library_datasource.dart';

class LibraryRepository {
  const LibraryRepository();

  Future<List<ArtworkModel>> getAllArtworks() {
    return AssetLibraryDataSource.loadArtworks();
  }

  Future<List<String>> getCategories() async {
    final artworks = await getAllArtworks();

    final categories = artworks
        .map((e) => e.category)
        .toSet()
        .toList();

    categories.sort();

    return categories;
  }

  Future<List<ArtworkModel>> getArtworksByCategory(String category) async {
    final artworks = await getAllArtworks();
    return artworks.where((e) => e.category == category).toList();
  }
}