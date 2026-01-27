import 'package:uuid/uuid.dart';

class AudioNoteModel {
  final String id;
  String? filePath;
  String? url;
  Duration duration;
  String? transcription;
  DateTime createdAt;
  bool isProcessing;

  AudioNoteModel({
    String? id,
    this.filePath,
    this.url,
    Duration? duration,
    this.transcription,
    DateTime? createdAt,
    this.isProcessing = false,
  })  : id = id ?? const Uuid().v4(),
        duration = duration ?? Duration.zero,
        createdAt = createdAt ?? DateTime.now();

  AudioNoteModel copyWith({
    String? id,
    String? filePath,
    String? url,
    Duration? duration,
    String? transcription,
    DateTime? createdAt,
    bool? isProcessing,
  }) {
    return AudioNoteModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      transcription: transcription ?? this.transcription,
      createdAt: createdAt ?? this.createdAt,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'url': url,
      'durationMs': duration.inMilliseconds,
      'transcription': transcription,
      'createdAt': createdAt.toIso8601String(),
      'isProcessing': isProcessing,
    };
  }

  factory AudioNoteModel.fromJson(Map<String, dynamic> json) {
    return AudioNoteModel(
      id: json['id'],
      filePath: json['filePath'],
      url: json['url'],
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      transcription: json['transcription'],
      createdAt: DateTime.parse(json['createdAt']),
      isProcessing: json['isProcessing'] ?? false,
    );
  }
}