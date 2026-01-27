import 'package:uuid/uuid.dart';

class AnkiCardModel {
  final String id;
  String front;
  String back;
  String? imageUrl;
  String? audioUrl;
  int interval; // Days until next review
  double easeFactor;
  int repetitions;
  DateTime? nextReview;
  DateTime createdAt;
  String? sourceNodeId;
  String? sourceMindmapId;

  AnkiCardModel({
    String? id,
    required this.front,
    required this.back,
    this.imageUrl,
    this.audioUrl,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.nextReview,
    DateTime? createdAt,
    this.sourceNodeId,
    this.sourceMindmapId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AnkiCardModel copyWith({
    String? id,
    String? front,
    String? back,
    String? imageUrl,
    String? audioUrl,
    int? interval,
    double? easeFactor,
    int? repetitions,
    DateTime? nextReview,
    DateTime? createdAt,
    String? sourceNodeId,
    String? sourceMindmapId,
  }) {
    return AnkiCardModel(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      createdAt: createdAt ?? this.createdAt,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      sourceMindmapId: sourceMindmapId ?? this.sourceMindmapId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
      'nextReview': nextReview?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'sourceNodeId': sourceNodeId,
      'sourceMindmapId': sourceMindmapId,
    };
  }

  factory AnkiCardModel.fromJson(Map<String, dynamic> json) {
    return AnkiCardModel(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      imageUrl: json['imageUrl'],
      audioUrl: json['audioUrl'],
      interval: json['interval'] ?? 1,
      easeFactor: (json['easeFactor'] ?? 2.5).toDouble(),
      repetitions: json['repetitions'] ?? 0,
      nextReview: json['nextReview'] != null
          ? DateTime.parse(json['nextReview'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      sourceNodeId: json['sourceNodeId'],
      sourceMindmapId: json['sourceMindmapId'],
    );
  }

  // SM-2 Algorithm for spaced repetition
  void review(int quality) {
    // quality: 0-5 (0-2 = fail, 3-5 = pass)
    if (quality < 3) {
      // Failed - reset
      repetitions = 0;
      interval = 1;
    } else {
      // Passed
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    }

    // Update ease factor
    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    // Set next review date
    nextReview = DateTime.now().add(Duration(days: interval));
  }

  bool get isDue {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }
}