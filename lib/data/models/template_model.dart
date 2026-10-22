import 'package:uuid/uuid.dart';
import 'mindmap_model.dart';
import 'node_model.dart';
import '../../core/utils/firestore_converters.dart';

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

    // Third pass: recompute `depth` from the new root. `copyWith` alone would
    // keep the template's depth values, and depth drives node styling in the
    // editor — a flat map otherwise.
    if (newRootId.isNotEmpty) {
      final queue = <String>[newRootId];
      final depths = <String, int>{newRootId: 0};
      while (queue.isNotEmpty) {
        final currentId = queue.removeAt(0);
        final current = newNodes[currentId];
        if (current == null) continue;
        final currentDepth = depths[currentId] ?? 0;
        newNodes[currentId] = current.copyWith(depth: currentDepth);
        for (final childId in current.childrenIds) {
          if (depths.containsKey(childId)) continue; // guard against cycles
          depths[childId] = currentDepth + 1;
          queue.add(childId);
        }
      }
    }

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
    final rawNodes = json['nodes'];
    if (rawNodes is Map) {
      rawNodes.forEach((key, value) {
        nodesMap[key.toString()] = NodeModel.fromJson(firestoreMap(value));
      });
    }

    return TemplateModel(
      id: json['id'] as String,
      name: (json['name'] ?? 'Template') as String,
      description: (json['description'] ?? '') as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      category: firestoreEnum(json['category'], TemplateCategory.values,
          fallback: TemplateCategory.custom),
      nodes: nodesMap,
      rootNodeId: (json['rootNodeId'] ?? '') as String,
      layout: firestoreEnum(json['layout'], MindmapLayout.values,
          fallback: MindmapLayout.radial),
      style: firestoreEnum(json['style'], MindmapStyle.values,
          fallback: MindmapStyle.modern),
      creatorId: (json['creatorId'] ?? 'system') as String,
      creatorName: json['creatorName'] as String?,
      usageCount: firestoreInt(json['usageCount']),
      rating: firestoreDouble(json['rating']),
      isPremium: (json['isPremium'] ?? false) as bool,
      isOfficial: (json['isOfficial'] ?? false) as bool,
      createdAt: firestoreDateOr(json['createdAt'], DateTime.now()),
      tags: firestoreStringList(json['tags']),
    );
  }
}
