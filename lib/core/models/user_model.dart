class UserModel {
  final int? id;
  final String name;
  final String avatarPath;

  UserModel({
    this.id,
    required this.name,
    required this.avatarPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      avatarPath: map['avatarPath'],
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? avatarPath,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
