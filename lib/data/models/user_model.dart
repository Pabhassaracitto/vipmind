import '../../core/utils/firestore_converters.dart';

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
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      photoUrl: json['photoUrl'] as String?,
      // May be a Firestore Timestamp or an ISO string depending on who wrote it.
      createdAt: firestoreDate(json['createdAt']),
      settings: firestoreMap(json['settings']),
      stats: firestoreMap(json['stats']).map(
        (key, value) => MapEntry(key, firestoreInt(value)),
      ),
    );
  }
}