class UserModel {
  final String id;
  String name;
  String email;
  String? photoUrl;
  DateTime createdAt;
  Map<String, dynamic> settings;
  Map<String, int> stats;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
    Map<String, int>? stats,
  })  : createdAt = createdAt ?? DateTime.now(),
        settings = settings ?? {},
        stats = stats ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'settings': settings,
      'stats': stats,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }
}