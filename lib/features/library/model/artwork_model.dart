enum LibrarySection {
  continueColoring,
  recommendation,
  trending,
}

class ArtworkModel {
  final String id;
  final String title;
  final String imagePath;
  final String category;
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
    required this.section, 
    this.isPremium = false,
    this.isFavorite = false,
    this.isHot = false,
    this.isNew = false,
    this.progress = 0,
  });
}