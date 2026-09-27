enum LibrarySection { continueColoring, recommendation, trending }

class ArtworkModel {
  final String id;
  final String title;
  final String imagePath;
  final String category;
  final String subCategory;
  final LibrarySection section;

  final bool isPremium;
  final bool isFavorite;
  final bool isHot;
  final bool isNew;

  final String? cpopPath;
  final double progress;

  const ArtworkModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.category,
    required this.subCategory,
    required this.section,
    this.isPremium = false,
    this.isFavorite = false,
    this.isHot = false,
    this.isNew = false,
    this.cpopPath,
    this.progress = 0,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    String imgPath = json["imagePath"];
    
    // Tự động suy luận cpopPath từ imagePath
    // Ví dụ: assets/images/library/animals/cat.png -> assets/cpop/library/animals/cat.cpop
    // Hoặc tạm thời lưu cùng thư mục: assets/images/library/animals/cat.cpop
    // Nhưng vì mình sẽ tạo thư mục riêng là assets/cpop, nên thay chuỗi:
    String cpop = imgPath.replaceAll('assets/images', 'assets/cpop');
    int lastDot = cpop.lastIndexOf('.');
    if (lastDot != -1) {
      cpop = '${cpop.substring(0, lastDot)}.cpop';
    }

    return ArtworkModel(
      id: json["id"],
      title: json["title"],
      imagePath: imgPath,
      cpopPath: cpop,
      category: json["category"],
      subCategory: json["subcategory"] ?? "",
      section: _detectSection(json["category"]),
    );
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
}
