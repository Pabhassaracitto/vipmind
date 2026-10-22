import 'package:uuid/uuid.dart';
import '../../core/utils/firestore_converters.dart';

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
      id: json['id'] as String,
      filePath: json['filePath'] as String?,
      url: json['url'] as String?,
      duration: Duration(milliseconds: firestoreInt(json['durationMs'])),
      transcription: json['transcription'] as String?,
      createdAt: firestoreDateOr(json['createdAt'], DateTime.now()),
      isProcessing: (json['isProcessing'] ?? false) as bool,
    );
  }
}