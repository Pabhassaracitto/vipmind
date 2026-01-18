import 'package:uuid/uuid.dart';
import 'node_model.dart';
import 'connection_model.dart';

enum MindmapLayout { radial, tree, orgChart, fishbone, timeline, freeform }
enum MindmapStyle { modern, classic, minimal, colorful, dark, nature }

class MindmapModel {
  final String id;
  String title;
  String? description;
  String? thumbnailUrl;
  Map<String, NodeModel> nodes;
  List<ConnectionModel> connections;
  String rootNodeId;
  MindmapLayout layout;
  MindmapStyle style;
  String? templateId;
  String ownerId;
  List<String> collaboratorIds;
  bool isPublic;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? settings;
  List<String> tags;

  MindmapModel({
    String? id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    Map<String, NodeModel>? nodes,
    List<ConnectionModel>? connections,
    String? rootNodeId,
    this.layout = MindmapLayout.radial,
    this.style = MindmapStyle.modern,
    this.templateId,
    required this.ownerId,
    List<String>? collaboratorIds,
    this.isPublic = false,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.settings,
    List<String>? tags,
  })  : id = id ?? const Uuid().v4(),
        nodes = nodes ?? {},
        connections = connections ?? [],
        rootNodeId = rootNodeId ?? '',
        collaboratorIds = collaboratorIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  // Get root node
  NodeModel? get rootNode => nodes[rootNodeId];

  // Get all child nodes of a node
  List<NodeModel> getChildren(String nodeId) {
    final node = nodes[nodeId];
    if (node == null) return [];
    return node.childrenIds
        .map((id) => nodes[id])
        .whereType<NodeModel>()
        .toList();
  }

  // Get parent node
  NodeModel? getParent(String nodeId) {
    final node = nodes[nodeId];
    if (node == null || node.parentId == null) return null;
    return nodes[node.parentId];
  }

  // Add node
  void addNode(NodeModel node, {String? parentId}) {
    nodes[node.id] = node;
    if (parentId != null && nodes.containsKey(parentId)) {
      final parent = nodes[parentId]!;
      parent.childrenIds.add(node.id);
      nodes[parentId] = parent.copyWith(
        childrenIds: parent.childrenIds,
      );
      nodes[node.id] = node.copyWith(
        parentId: parentId,
        depth: parent.depth + 1,
      );
    }
  }

  // Remove node and all children
  void removeNode(String nodeId) {
    final node = nodes[nodeId];
    if (node == null) return;

    // Remove from parent's children
    if (node.parentId != null && nodes.containsKey(node.parentId)) {
      final parent = nodes[node.parentId]!;
      parent.childrenIds.remove(nodeId);
      nodes[node.parentId!] = parent.copyWith(
        childrenIds: parent.childrenIds,
      );
    }

    // Recursively remove children
    for (final childId in node.childrenIds) {
      removeNode(childId);
    }

    // Remove connections
    connections.removeWhere(
          (c) => c.fromNodeId == nodeId || c.toNodeId == nodeId,
    );

    // Remove node
    nodes.remove(nodeId);
  }

  // Update node
  void updateNode(NodeModel updatedNode) {
    if (nodes.containsKey(updatedNode.id)) {
      nodes[updatedNode.id] = updatedNode;
    }
  }

  // Copy with
  MindmapModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    Map<String, NodeModel>? nodes,
    List<ConnectionModel>? connections,
    String? rootNodeId,
    MindmapLayout? layout,
    MindmapStyle? style,
    String? templateId,
    String? ownerId,
    List<String>? collaboratorIds,
    bool? isPublic,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
    List<String>? tags,
  }) {
    return MindmapModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      nodes: nodes ?? Map.from(this.nodes),
      connections: connections ?? List.from(this.connections),
      rootNodeId: rootNodeId ?? this.rootNodeId,
      layout: layout ?? this.layout,
      style: style ?? this.style,
      templateId: templateId ?? this.templateId,
      ownerId: ownerId ?? this.ownerId,
      collaboratorIds: collaboratorIds ?? List.from(this.collaboratorIds),
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      settings: settings ?? this.settings,
      tags: tags ?? List.from(this.tags),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'nodes': nodes.map((key, value) => MapEntry(key, value.toJson())),
      'connections': connections.map((c) => c.toJson()).toList(),
      'rootNodeId': rootNodeId,
      'layout': layout.index,
      'style': style.index,
      'templateId': templateId,
      'ownerId': ownerId,
      'collaboratorIds': collaboratorIds,
      'isPublic': isPublic,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'settings': settings,
      'tags': tags,
    };
  }

  // From JSON
  factory MindmapModel.fromJson(Map<String, dynamic> json) {
    final nodesMap = <String, NodeModel>{};
    if (json['nodes'] != null) {
      (json['nodes'] as Map<String, dynamic>).forEach((key, value) {
        nodesMap[key] = NodeModel.fromJson(value);
      });
    }

    return MindmapModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
      nodes: nodesMap,
      connections: (json['connections'] as List?)
          ?.map((c) => ConnectionModel.fromJson(c))
          .toList() ??
          [],
      rootNodeId: json['rootNodeId'],
      layout: MindmapLayout.values[json['layout'] ?? 0],
      style: MindmapStyle.values[json['style'] ?? 0],
      templateId: json['templateId'],
      ownerId: json['ownerId'],
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      isPublic: json['isPublic'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      settings: json['settings'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Create empty mindmap with root node
  factory MindmapModel.createNew({
    required String title,
    required String ownerId,
    String rootText = 'Central Idea',
  }) {
    final rootNode = NodeModel(
      text: rootText,
      position: const Offset(400, 300),
      size: const Size(180, 80),
      depth: 0,
    );

    return MindmapModel(
      title: title,
      ownerId: ownerId,
      nodes: {rootNode.id: rootNode},
      rootNodeId: rootNode.id,
    );
  }
}