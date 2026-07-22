class ColorProject {
  final int? id;
  final String imagePath;
  final String status; // 'in_progress' or 'completed'
  final int createdAt;

  ColorProject({
    this.id,
    required this.imagePath,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory ColorProject.fromMap(Map<String, dynamic> map) {
    return ColorProject(
      id: map['id'],
      imagePath: map['imagePath'],
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }

  ColorProject copyWith({
    int? id,
    String? imagePath,
    String? status,
    int? createdAt,
  }) {
    return ColorProject(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}