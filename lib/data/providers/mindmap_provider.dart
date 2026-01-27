import 'package:flutter/material.dart';
import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../models/connection_model.dart';
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
      final childCount = parent.childrenIds.length;
      final angle = (childCount * 45) * (3.14159 / 180);
      const distance = 200.0;
      nodePosition = Offset(
        parent.center.dx + distance * cos(angle),
        parent.center.dy + distance * sin(angle),
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

  // Apply layout algorithm
  void _applyLayout() {
    if (_currentMindmap == null) return;

    switch (_currentMindmap!.layout) {
      case MindmapLayout.radial:
        _applyRadialLayout();
        break;
      case MindmapLayout.tree:
        _applyTreeLayout();
        break;
      case MindmapLayout.orgChart:
        _applyOrgChartLayout();
        break;
      default:
        break;
    }
  }

  void _applyRadialLayout() {
    // Radial layout implementation
    final root = _currentMindmap!.rootNode;
    if (root == null) return;

    const centerX = 500.0;
    const centerY = 400.0;

    _currentMindmap!.nodes[root.id] = root.copyWith(
      position: const Offset(centerX - 90, centerY - 40),
    );

    _layoutChildrenRadially(root.id, centerX, centerY, 0, 360, 200);
  }

  void _layoutChildrenRadially(
    String parentId,
    double centerX,
    double centerY,
    double startAngle,
    double endAngle,
    double radius,
  ) {
    final parent = _currentMindmap!.nodes[parentId];
    if (parent == null || parent.childrenIds.isEmpty) return;

    final angleStep = (endAngle - startAngle) / parent.childrenIds.length;

    for (var i = 0; i < parent.childrenIds.length; i++) {
      final childId = parent.childrenIds[i];
      final child = _currentMindmap!.nodes[childId];
      if (child == null) continue;

      final angle = (startAngle + angleStep * (i + 0.5)) * (3.14159 / 180);
      final x = centerX + radius * cos(angle) - child.size.width / 2;
      final y = centerY + radius * sin(angle) - child.size.height / 2;

      _currentMindmap!.nodes[childId] = child.copyWith(
        position: Offset(x, y),
      );

      // Recursively layout children
      final childAngleSpan = angleStep * 0.8;
      final childStartAngle = startAngle + angleStep * i + angleStep * 0.1;
      _layoutChildrenRadially(
        childId,
        x + child.size.width / 2,
        y + child.size.height / 2,
        childStartAngle,
        childStartAngle + childAngleSpan,
        radius * 0.7,
      );
    }
  }

  void _applyTreeLayout() {
    // Tree layout implementation
    final root = _currentMindmap!.rootNode;
    if (root == null) return;

    const startX = 100.0;
    const startY = 50.0;
    const horizontalSpacing = 250.0;
    const verticalSpacing = 100.0;

    _currentMindmap!.nodes[root.id] = root.copyWith(
      position: const Offset(startX, startY),
    );

    _layoutChildrenAsTree(
      root.id,
      startX + horizontalSpacing,
      startY,
      horizontalSpacing,
      verticalSpacing,
    );
  }

  double _layoutChildrenAsTree(
    String parentId,
    double startX,
    double startY,
    double horizontalSpacing,
    double verticalSpacing,
  ) {
    final parent = _currentMindmap!.nodes[parentId];
    if (parent == null || parent.childrenIds.isEmpty) return startY;

    var currentY = startY;

    for (final childId in parent.childrenIds) {
      final child = _currentMindmap!.nodes[childId];
      if (child == null) continue;

      _currentMindmap!.nodes[childId] = child.copyWith(
        position: Offset(startX, currentY),
      );

      final subtreeHeight = _layoutChildrenAsTree(
        childId,
        startX + horizontalSpacing,
        currentY,
        horizontalSpacing,
        verticalSpacing,
      );

      currentY = subtreeHeight + verticalSpacing;
    }

    return currentY - verticalSpacing;
  }

  void _applyOrgChartLayout() {
    // Org chart layout (top-down tree)
    final root = _currentMindmap!.rootNode;
    if (root == null) return;

    const centerX = 500.0;
    const startY = 50.0;
    const verticalSpacing = 120.0;

    _currentMindmap!.nodes[root.id] = root.copyWith(
      position: Offset(centerX - root.size.width / 2, startY),
    );

    _layoutChildrenOrgChart(
        root.id, centerX, startY + root.size.height + verticalSpacing);
  }

  void _layoutChildrenOrgChart(String parentId, double centerX, double y) {
    final parent = _currentMindmap!.nodes[parentId];
    if (parent == null || parent.childrenIds.isEmpty) return;

    const horizontalSpacing = 180.0;
    const verticalSpacing = 120.0;

    final totalWidth = parent.childrenIds.length * horizontalSpacing;
    var currentX = centerX - totalWidth / 2;

    for (final childId in parent.childrenIds) {
      final child = _currentMindmap!.nodes[childId];
      if (child == null) continue;

      _currentMindmap!.nodes[childId] = child.copyWith(
        position: Offset(currentX, y),
      );

      _layoutChildrenOrgChart(
        childId,
        currentX + child.size.width / 2,
        y + child.size.height + verticalSpacing,
      );

      currentX += horizontalSpacing;
    }
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

  // Math helper
  double cos(double radians) => _cos(radians);
  double sin(double radians) => _sin(radians);

  double _cos(double x) {
    return _taylorCos(x);
  }

  double _sin(double x) {
    return _taylorSin(x);
  }

  double _taylorCos(double x) {
    // Normalize to [0, 2π]
    while (x < 0) {
      x += 2 * 3.14159265359;
    }
    while (x > 2 * 3.14159265359) {
      x -= 2 * 3.14159265359;
    }

    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _taylorSin(double x) {
    // Normalize to [0, 2π]
    while (x < 0) {
      x += 2 * 3.14159265359;
    }
    while (x > 2 * 3.14159265359) {
      x -= 2 * 3.14159265359;
    }

    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}
