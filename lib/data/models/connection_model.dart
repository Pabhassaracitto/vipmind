import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ConnectionStyle { straight, curved, orthogonal, bezier }
enum ConnectionType { parent, sibling, reference, dependency }

class ConnectionModel {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  Color color;
  double strokeWidth;
  ConnectionStyle style;
  ConnectionType type;
  String? label;
  bool isAnimated;

  ConnectionModel({
    String? id,
    required this.fromNodeId,
    required this.toNodeId,
    Color? color,
    this.strokeWidth = 2.0,
    this.style = ConnectionStyle.curved,
    this.type = ConnectionType.parent,
    this.label,
    this.isAnimated = false,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? const Color(0xFF4A6FA5);

  ConnectionModel copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    Color? color,
    double? strokeWidth,
    ConnectionStyle? style,
    ConnectionType? type,
    String? label,
    bool? isAnimated,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
      type: type ?? this.type,
      label: label ?? this.label,
      isAnimated: isAnimated ?? this.isAnimated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'style': style.index,
      'type': type.index,
      'label': label,
      'isAnimated': isAnimated,
    };
  }

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'],
      fromNodeId: json['fromNodeId'],
      toNodeId: json['toNodeId'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
      style: ConnectionStyle.values[json['style'] ?? 1],
      type: ConnectionType.values[json['type'] ?? 0],
      label: json['label'],
      isAnimated: json['isAnimated'] ?? false,
    );
  }
}