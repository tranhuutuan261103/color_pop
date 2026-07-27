import 'package:flutter/services.dart';
import '../../model/artwork_model.dart';

class AssetLibraryDataSource {
  AssetLibraryDataSource._();

  /// Thư mục gốc chứa toàn bộ ảnh của Library
  static const String _rootFolder = 'assets/images/categories/forbaby/';

  /// Đọc toàn bộ ảnh trong assets
  static Future<List<ArtworkModel>> loadArtworks() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> assets = assetManifest.listAssets();

    final imagePaths = assets
        .where((path) => path.startsWith(_rootFolder))
        .where(
          (path) =>
              path.endsWith(".png") ||
              path.endsWith(".jpg") ||
              path.endsWith(".jpeg"),
        )
        .toList();

    imagePaths.sort();
    return imagePaths.map(_createArtwork).toList();
  }

  static LibrarySection _detectSection(String category) {
    switch (category) {
      case "animals":
      case "cartoons":
        return LibrarySection.recommendation;

      case "trends":
        return LibrarySection.trending;

      default:
        return LibrarySection.recommendation;
    }
  }

  static ArtworkModel _createArtwork(String imagePath) {
    // Category
    final folders = imagePath.split('/');
    final category = folders[4];

    // File name
    final fileName = folders.last;

    // TODO(Hung):
    // Sau này đổi title tại đây
    final title = fileName
        .replaceAll(".png", "")
        .replaceAll(".jpg", "")
        .replaceAll(".jpeg", "");

    return ArtworkModel(
      id: imagePath,
      title: title,
      imagePath: imagePath,
      category: category,
      section: _detectSection(category),
    );
  }
}
