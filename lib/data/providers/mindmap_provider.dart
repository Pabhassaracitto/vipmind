import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../models/connection_model.dart';
import '../../core/utils/mindmap_layout.dart';
import '../repositories/mindmap_repository.dart';

class MindmapProvider extends ChangeNotifier {
  final MindmapRepository _repository = MindmapRepository();

  MindmapModel? _currentMindmap;
  List<MindmapModel> _mindmaps = [];
  String? _selectedNodeId;
  bool _isLoading = false;
  String? _error;

  // Undo/Redo stacks
  final List<MindmapModel> _undoStack = [];
  final List<MindmapModel> _redoStack = [];

  // Canvas state
  Offset _canvasOffset = Offset.zero;
  double _canvasScale = 1.0;

  // Getters
  MindmapModel? get currentMindmap => _currentMindmap;
  List<MindmapModel> get mindmaps => _mindmaps;
  String? get selectedNodeId => _selectedNodeId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Offset get canvasOffset => _canvasOffset;
  double get canvasScale => _canvasScale;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  NodeModel? get selectedNode {
    if (_selectedNodeId == null || _currentMindmap == null) return null;
    return _currentMindmap!.nodes[_selectedNodeId];
  }

  // Load all mindmaps for user
  Future<void> loadMindmaps(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mindmaps = await _repository.getMindmaps(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load single mindmap
  Future<void> loadMindmap(String mindmapId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentMindmap = await _repository.getMindmap(mindmapId);
      _undoStack.clear();
      _redoStack.clear();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create new mindmap
  Future<MindmapModel?> createMindmap({
    required String title,
    required String ownerId,
    String rootText = 'Central Idea',
  }) async {
    try {
      final mindmap = MindmapModel.createNew(
        title: title,
        ownerId: ownerId,
        rootText: rootText,
      );
      await _repository.saveMindmap(mindmap);
      _mindmaps.insert(0, mindmap);
      _currentMindmap = mindmap;
      notifyListeners();
      return mindmap;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Renames a map in the list and persists it.
  ///
  /// The editor's rename dialog used to build an `updated` copy and then
  /// reference `updateNode` without calling it, so pressing Save did nothing at
  /// all. `MindmapModel.title` is mutable and the list holds the same instance,
  /// so setting it + saving is enough.
  Future<void> renameTitle(String mindmapId, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    MindmapModel? target;
    if (_currentMindmap?.id == mindmapId) {
      target = _currentMindmap;
    } else {
      for (final map in _mindmaps) {
        if (map.id == mindmapId) {
          target = map;
          break;
        }
      }
    }
    if (target == null) return;

    _saveState();
    target.title = trimmed;
    notifyListeners();

    try {
      await _repository.updateTitle(mindmapId, trimmed);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Inserts an already-built [MindmapModel] (e.g. created from a template),
  /// persists it and makes it the current map.
  Future<MindmapModel?> createMindmapFromModel(MindmapModel mindmap) async {
    try {
      await _repository.saveMindmap(mindmap);
      _mindmaps.insert(0, mindmap);
      _currentMindmap = mindmap;
      _undoStack.clear();
      _redoStack.clear();
      notifyListeners();
      return mindmap;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Save current mindmap
  Future<void> saveMindmap() async {
    if (_currentMindmap == null) return;
    try {
      await _repository.saveMindmap(_currentMindmap!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete mindmap
  Future<void> deleteMindmap(String mindmapId) async {
    try {
      await _repository.deleteMindmap(mindmapId);
      _mindmaps.removeWhere((m) => m.id == mindmapId);
      if (_currentMindmap?.id == mindmapId) {
        _currentMindmap = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Save state for undo
  void _saveState() {
    if (_currentMindmap != null) {
      _undoStack.add(_currentMindmap!.copyWith());
      _redoStack.clear();
      // Keep stack size manageable
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
    }
  }

  // Undo
  void undo() {
    if (_undoStack.isEmpty || _currentMindmap == null) return;
    _redoStack.add(_currentMindmap!.copyWith());
    _currentMindmap = _undoStack.removeLast();
    notifyListeners();
  }

  // Redo
  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_currentMindmap!.copyWith());
    _currentMindmap = _redoStack.removeLast();
    notifyListeners();
  }

  // Select node
  void selectNode(String? nodeId) {
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  // Add node
  void addNode({
    required String text,
    String? parentId,
    Offset? position,
    Color? color,
  }) {
    if (_currentMindmap == null) return;
    _saveState();

    final parent = parentId != null ? _currentMindmap!.nodes[parentId] : null;

    // Calculate position
    Offset nodePosition;
    if (position != null) {
      nodePosition = position;
    } else if (parent != null) {
      // Position relative to parent
      // Spread children on a 45° fan around the parent.
      final childCount = parent.childrenIds.length;
      final angle = math.pi / 4 * childCount;
      const distance = 200.0;
      nodePosition = Offset(
        parent.center.dx + distance * math.cos(angle),
        parent.center.dy + distance * math.sin(angle),
      );
    } else {
      nodePosition = const Offset(400, 300);
    }

    final node = NodeModel(
      text: text,
      position: nodePosition,
      color: color ?? _getNextColor(),
      parentId: parentId,
      depth: parent != null ? parent.depth + 1 : 0,
    );

    _currentMindmap!.addNode(node, parentId: parentId);
    _selectedNodeId = node.id;
    notifyListeners();
  }

  // Update node
  void updateNode(NodeModel updatedNode) {
    if (_currentMindmap == null) return;
    _saveState();
    _currentMindmap!.updateNode(updatedNode);
    notifyListeners();
  }

  // Move node
  void moveNode(String nodeId, Offset newPosition) {
    if (_currentMindmap == null) return;
    final node = _currentMindmap!.nodes[nodeId];
    if (node == null) return;

    _currentMindmap!.nodes[nodeId] = node.copyWith(position: newPosition);
    notifyListeners();
  }

  // Delete node
  void deleteNode(String nodeId) {
    if (_currentMindmap == null) return;
    if (nodeId == _currentMindmap!.rootNodeId) return; // Can't delete root

    _saveState();
    _currentMindmap!.removeNode(nodeId);
    if (_selectedNodeId == nodeId) {
      _selectedNodeId = null;
    }
    notifyListeners();
  }

  // Toggle node expansion
  void toggleNodeExpansion(String nodeId) {
    if (_currentMindmap == null) return;
    final node = _currentMindmap!.nodes[nodeId];
    if (node == null) return;

    _currentMindmap!.nodes[nodeId] = node.copyWith(
      isExpanded: !node.isExpanded,
    );
    notifyListeners();
  }

  // Add connection
  void addConnection({
    required String fromNodeId,
    required String toNodeId,
    ConnectionStyle style = ConnectionStyle.curved,
  }) {
    if (_currentMindmap == null) return;
    _saveState();

    final connection = ConnectionModel(
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      style: style,
    );
    _currentMindmap!.connections.add(connection);
    notifyListeners();
  }

  // Remove connection
  void removeConnection(String connectionId) {
    if (_currentMindmap == null) return;
    _saveState();
    _currentMindmap!.connections.removeWhere((c) => c.id == connectionId);
    notifyListeners();
  }

  // Canvas controls
  void setCanvasOffset(Offset offset) {
    _canvasOffset = offset;
    notifyListeners();
  }

  void setCanvasScale(double scale) {
    _canvasScale = scale.clamp(0.1, 3.0);
    notifyListeners();
  }

  void resetCanvas() {
    _canvasOffset = Offset.zero;
    _canvasScale = 1.0;
    notifyListeners();
  }

  // Change layout
  void changeLayout(MindmapLayout layout) {
    if (_currentMindmap == null) return;
    _saveState();
    _currentMindmap = _currentMindmap!.copyWith(layout: layout);
    _applyLayout();
    notifyListeners();
  }

  /// Re-runs the auto-layout of the current map (public: the editor toolbar
  /// can call it after bulk edits).
  void reapplyLayout() {
    if (_currentMindmap == null) return;
    _saveState();
    _applyLayout();
    notifyListeners();
  }

  // Apply layout algorithm.
  // The algorithms themselves live in MindmapLayoutEngine (pure + unit tested);
  // this provider only owns state, undo history and notifications.
  void _applyLayout() {
    final mindmap = _currentMindmap;
    if (mindmap == null) return;
    MindmapLayoutEngine.apply(mindmap.layout, mindmap.nodes, mindmap.rootNodeId);
  }

  // Helper to get next color
  Color _getNextColor() {
    if (_currentMindmap == null) return const Color(0xFF4A6FA5);
    final nodeCount = _currentMindmap!.nodes.length;
    const colors = [
      Color(0xFF4A6FA5),
      Color(0xFF06D6A0),
      Color(0xFFFFD166),
      Color(0xFF9D4EDD),
      Color(0xFFEF476F),
      Color(0xFFF77F00),
      Color(0xFF118AB2),
    ];
    return colors[nodeCount % colors.length];
  }

}
