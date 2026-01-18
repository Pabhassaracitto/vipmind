import 'package:uuid/uuid.dart';
import 'mindmap_model.dart';
import 'node_model.dart';

enum TemplateCategory {
  business,
  education,
  personal,
  creative,
  technical,
  planning,
  brainstorm,
  custom,
}

class TemplateModel {
  final String id;
  String name;
  String description;
  String? thumbnailUrl;
  TemplateCategory category;
  Map<String, NodeModel> nodes;
  String rootNodeId;
  MindmapLayout layout;
  MindmapStyle style;
  String creatorId;
  String? creatorName;
  int usageCount;
  double rating;
  bool isPremium;
  bool isOfficial;
  DateTime createdAt;
  List<String> tags;

  TemplateModel({
    String? id,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    this.category = TemplateCategory.custom,
    Map<String, NodeModel>? nodes,
    this.rootNodeId = '',
    this.layout = MindmapLayout.radial,
    this.style = MindmapStyle.modern,
    required this.creatorId,
    this.creatorName,
    this.usageCount = 0,
    this.rating = 0.0,
    this.isPremium = false,
    this.isOfficial = false,
    DateTime? createdAt,
    List<String>? tags,
  })  : id = id ?? const Uuid().v4(),
        nodes = nodes ?? {},
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  // Create mindmap from template
  MindmapModel createMindmap({
    required String title,
    required String ownerId,
  }) {
    // Deep copy nodes with new IDs
    final newNodes = <String, NodeModel>{};
    final idMapping = <String, String>{};

    // First pass: create new nodes with new IDs
    for (final entry in nodes.entries) {
      final newId = const Uuid().v4();
      idMapping[entry.key] = newId;
      newNodes[newId] = entry.value.copyWith(
        id: newId,
        childrenIds: [],
        parentId: null,
      );
    }

    // Second pass: update relationships
    for (final entry in nodes.entries) {
      final newId = idMapping[entry.key]!;
      final oldNode = entry.value;

      final newChildrenIds = oldNode.childrenIds
          .map((oldId) => idMapping[oldId])
          .whereType<String>()
          .toList();

      final newParentId =
      oldNode.parentId != null ? idMapping[oldNode.parentId] : null;

      newNodes[newId] = newNodes[newId]!.copyWith(
        childrenIds: newChildrenIds,
        parentId: newParentId,
      );
    }

    final newRootId = idMapping[rootNodeId] ?? '';

    return MindmapModel(
      title: title,
      ownerId: ownerId,
      nodes: newNodes,
      rootNodeId: newRootId,
      layout: layout,
      style: style,
      templateId: id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category.index,
      'nodes': nodes.map((key, value) => MapEntry(key, value.toJson())),
      'rootNodeId': rootNodeId,
      'layout': layout.index,
      'style': style.index,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'usageCount': usageCount,
      'rating': rating,
      'isPremium': isPremium,
      'isOfficial': isOfficial,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    final nodesMap = <String, NodeModel>{};
    if (json['nodes'] != null) {
      (json['nodes'] as Map<String, dynamic>).forEach((key, value) {
        nodesMap[key] = NodeModel.fromJson(value);
      });
    }

    return TemplateModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
      category: TemplateCategory.values[json['category'] ?? 7],
      nodes: nodesMap,
      rootNodeId: json['rootNodeId'] ?? '',
      layout: MindmapLayout.values[json['layout'] ?? 0],
      style: MindmapStyle.values[json['style'] ?? 0],
      creatorId: json['creatorId'],
      creatorName: json['creatorName'],
      usageCount: json['usageCount'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      isPremium: json['isPremium'] ?? false,
      isOfficial: json['isOfficial'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}