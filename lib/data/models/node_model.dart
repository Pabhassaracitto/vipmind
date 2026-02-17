import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'audio_note_model.dart';

enum NodeShape { rectangle, roundedRectangle, ellipse, diamond, hexagon }

enum NodeType { idea, task, question, note, image, audio, link }

class NodeModel {
  final String id;
  String text;
  String? description;
  Offset position;
  Size size;
  Color color;
  Color textColor;
  NodeShape shape;
  NodeType type;
  String? iconName;
  String? imageUrl;
  AudioNoteModel? audioNote;
  List<String> childrenIds;
  String? parentId;
  int depth;
  bool isExpanded;
  bool isSelected;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? metadata;

  // For Anki integration
  bool isAnkiCard;
  String? ankiFront;
  String? ankiBack;
  int? ankiInterval;
  DateTime? ankiNextReview;

  NodeModel({
    String? id,
    required this.text,
    this.description,
    required this.position,
    Size? size,
    Color? color,
    Color? textColor,
    this.shape = NodeShape.roundedRectangle,
    this.type = NodeType.idea,
    this.iconName,
    this.imageUrl,
    this.audioNote,
    List<String>? childrenIds,
    this.parentId,
    this.depth = 0,
    this.isExpanded = true,
    this.isSelected = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata,
    this.isAnkiCard = false,
    this.ankiFront,
    this.ankiBack,
    this.ankiInterval,
    this.ankiNextReview,
  })  : id = id ?? const Uuid().v4(),
        size = size ?? const Size(150, 60),
        color = color ?? const Color(0xFF4A6FA5),
        textColor = textColor ?? Colors.white,
        childrenIds = childrenIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Center point of the node
  Offset get center => Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );

  // Connection points
  Offset get topCenter => Offset(position.dx + size.width / 2, position.dy);
  Offset get bottomCenter =>
      Offset(position.dx + size.width / 2, position.dy + size.height);
  Offset get leftCenter => Offset(position.dx, position.dy + size.height / 2);
  Offset get rightCenter =>
      Offset(position.dx + size.width, position.dy + size.height / 2);

  // Bounding rect
  Rect get bounds => Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );

  // Copy with
  NodeModel copyWith({
    String? id,
    String? text,
    String? description,
    Offset? position,
    Size? size,
    Color? color,
    Color? textColor,
    NodeShape? shape,
    NodeType? type,
    String? iconName,
    String? imageUrl,
    AudioNoteModel? audioNote,
    List<String>? childrenIds,
    String? parentId,
    int? depth,
    bool? isExpanded,
    bool? isSelected,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool? isAnkiCard,
    String? ankiFront,
    String? ankiBack,
    int? ankiInterval,
    DateTime? ankiNextReview,
  }) {
    return NodeModel(
      id: id ?? this.id,
      text: text ?? this.text,
      description: description ?? this.description,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      shape: shape ?? this.shape,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      imageUrl: imageUrl ?? this.imageUrl,
      audioNote: audioNote ?? this.audioNote,
      childrenIds: childrenIds ?? List.from(this.childrenIds),
      parentId: parentId ?? this.parentId,
      depth: depth ?? this.depth,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
      isAnkiCard: isAnkiCard ?? this.isAnkiCard,
      ankiFront: ankiFront ?? this.ankiFront,
      ankiBack: ankiBack ?? this.ankiBack,
      ankiInterval: ankiInterval ?? this.ankiInterval,
      ankiNextReview: ankiNextReview ?? this.ankiNextReview,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'description': description,
      'positionX': position.dx,
      'positionY': position.dy,
      'width': size.width,
      'height': size.height,
      'color': color.value,
      'textColor': textColor.value,
      'shape': shape.index,
      'type': type.index,
      'iconName': iconName,
      'imageUrl': imageUrl,
      'audioNote': audioNote?.toJson(),
      'childrenIds': childrenIds,
      'parentId': parentId,
      'depth': depth,
      'isExpanded': isExpanded,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'isAnkiCard': isAnkiCard,
      'ankiFront': ankiFront,
      'ankiBack': ankiBack,
      'ankiInterval': ankiInterval,
      'ankiNextReview': ankiNextReview?.toIso8601String(),
    };
  }

  // From JSON
  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      id: json['id'],
      text: json['text'] ?? 'New Node',
      description: json['description'],
      position: Offset(
        (json['positionX'] ?? 0).toDouble(),
        (json['positionY'] ?? 0).toDouble(),
      ),
      size: Size(
        (json['width'] ?? 150).toDouble(),
        (json['height'] ?? 60).toDouble(),
      ),
      color: Color(json['color'] ?? 0xFF4A6FA5),
      textColor: Color(json['textColor'] ?? 0xFFFFFFFF),
      shape: NodeShape.values[json['shape'] ?? 1],
      type: NodeType.values[json['type'] ?? 0],
      iconName: json['iconName'],
      imageUrl: json['imageUrl'],
      audioNote: json['audioNote'] != null
          ? AudioNoteModel.fromJson(json['audioNote'])
          : null,
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
      parentId: json['parentId'],
      depth: json['depth'] ?? 0,
      isExpanded: json['isExpanded'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      metadata: json['metadata'],
      isAnkiCard: json['isAnkiCard'] ?? false,
      ankiFront: json['ankiFront'],
      ankiBack: json['ankiBack'],
      ankiInterval: json['ankiInterval'],
      ankiNextReview: json['ankiNextReview'] != null
          ? DateTime.parse(json['ankiNextReview'])
          : null,
    );
  }
}
