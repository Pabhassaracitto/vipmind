import 'package:uuid/uuid.dart';
import '../../core/utils/firestore_converters.dart';

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
      id: json['id'] as String,
      front: (json['front'] ?? '') as String,
      back: (json['back'] ?? '') as String,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      interval: firestoreInt(json['interval'], fallback: 1),
      easeFactor: firestoreDouble(json['easeFactor'], fallback: 2.5),
      repetitions: firestoreInt(json['repetitions']),
      nextReview: firestoreDate(json['nextReview']),
      createdAt: firestoreDateOr(json['createdAt'], DateTime.now()),
      sourceNodeId: json['sourceNodeId'] as String?,
      sourceMindmapId: json['sourceMindmapId'] as String?,
    );
  }
  /// SM-2 spaced repetition.
  ///
  /// [quality] is the learner's self-grade from 0 to 5: 0-2 = failed,
  /// 3-5 = passed. Pinned by `test/anki_sm2_test.dart` — the (not yet built)
  /// review UI must not change this scheduling.
  void review(int quality) {
    if (quality < 3) {
      // Failed: start the ladder over.
      repetitions = 0;
      interval = 1;
    } else {
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    }

    // SM-2 ease adjustment.
    easeFactor =
        easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    nextReview = DateTime.now().add(Duration(days: interval));
  }

  /// A card with no scheduled review is due immediately.
  bool get isDue {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }
}
