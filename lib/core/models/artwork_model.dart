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
    this.progress = 0,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    return ArtworkModel(
      id: json["id"],
      title: json["title"],
      imagePath: json["imagePath"],
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
