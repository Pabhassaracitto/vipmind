import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/mindmap_model.dart';
import '../../data/models/node_model.dart';

/// Pure auto-layout algorithms for a mindmap.
///
/// Extracted from `MindmapProvider` so they can be unit tested without
/// Firestore: every method mutates a plain `Map<String, NodeModel>` and returns
/// it, and nothing here touches providers, Firebase or `BuildContext`.
///
/// Differences from the original in-provider implementation (all deliberate):
/// * `dart:math` replaces the hand-written 10-term Taylor `sin`/`cos`
///   (approximation error + duplicated normalisation loops);
/// * the radial layout keeps the root where the user left it and recurses
///   around each child's real centre (it used to hard-code the root at
///   `(500, 400)` and recurse around the child's top-left corner);
/// * the tree layout advances the cursor by each subtree's height, so a leaf
///   sibling no longer gets a different gap than a subtree sibling.
class MindmapLayoutEngine {
  const MindmapLayoutEngine._();

  // Radial
  static const double radialRootRadius = 200;
  static const double radialRadiusFalloff = 0.7;
  static const double radialChildSpanFactor = 0.8;

  // Tree (left → right)
  static const double treeStartX = 100;
  static const double treeStartY = 50;
  static const double treeHorizontalSpacing = 250;
  static const double treeVerticalSpacing = 100;

  // Org chart (top → bottom)
  static const double orgCenterX = 500;
  static const double orgStartY = 50;
  static const double orgHorizontalSpacing = 180;
  static const double orgVerticalSpacing = 120;

  /// Applies [layout] to [nodes] in place and returns the same map.
  ///
  /// `freeform` (and any layout without an algorithm yet) leaves positions
  /// untouched — the user is in charge there.
  static Map<String, NodeModel> apply(
    MindmapLayout layout,
    Map<String, NodeModel> nodes,
    String rootNodeId,
  ) {
    final root = nodes[rootNodeId];
    if (root == null) return nodes;

    switch (layout) {
      case MindmapLayout.radial:
        _applyRadial(nodes, root);
        break;
      case MindmapLayout.tree:
        _applyTree(nodes, root);
        break;
      case MindmapLayout.orgChart:
        _applyOrgChart(nodes, root);
        break;
      case MindmapLayout.fishbone:
      case MindmapLayout.timeline:
      case MindmapLayout.freeform:
        break;
    }
    return nodes;
  }

  /// Convenience wrapper that reads the layout from the model itself.
  static MindmapModel applyToMindmap(MindmapModel mindmap) {
    apply(mindmap.layout, mindmap.nodes, mindmap.rootNodeId);
    return mindmap;
  }

  // ---------------------------------------------------------------- radial

  static void _applyRadial(Map<String, NodeModel> nodes, NodeModel root) {
    // Keep the root's centre where it currently is.
    final centre = root.center;
    nodes[root.id] = root.copyWith(
      position: Offset(
        centre.dx - root.size.width / 2,
        centre.dy - root.size.height / 2,
      ),
    );
    _layoutChildrenRadially(
      nodes,
      root.id,
      centre.dx,
      centre.dy,
      0,
      360,
      radialRootRadius,
    );
  }

  static void _layoutChildrenRadially(
    Map<String, NodeModel> nodes,
    String parentId,
    double centerX,
    double centerY,
    double startAngle,
    double endAngle,
    double radius,
  ) {
    final parent = nodes[parentId];
    if (parent == null || parent.childrenIds.isEmpty) return;

    final angleStep = (endAngle - startAngle) / parent.childrenIds.length;

    for (var i = 0; i < parent.childrenIds.length; i++) {
      final childId = parent.childrenIds[i];
      final child = nodes[childId];
      if (child == null) continue;

      final angleDegrees = startAngle + angleStep * (i + 0.5);
      final angle = angleDegrees * math.pi / 180.0;
      final x = centerX + radius * math.cos(angle) - child.size.width / 2;
      final y = centerY + radius * math.sin(angle) - child.size.height / 2;

      nodes[childId] = child.copyWith(position: Offset(x, y));

      final childSpan = angleStep * radialChildSpanFactor;
      final childStart = startAngle + angleStep * i + angleStep * 0.1;
      _layoutChildrenRadially(
        nodes,
        childId,
        x + child.size.width / 2,
        y + child.size.height / 2,
        childStart,
        childStart + childSpan,
        radius * radialRadiusFalloff,
      );
    }
  }

  // ------------------------------------------------------------------ tree

  static void _applyTree(Map<String, NodeModel> nodes, NodeModel root) {
    nodes[root.id] = root.copyWith(
      position: const Offset(treeStartX, treeStartY),
    );
    _layoutChildrenAsTree(
      nodes,
      root.id,
      treeStartX + treeHorizontalSpacing,
      treeStartY,
    );
  }

  /// Lays out the subtree of [parentId] and returns the bottom edge (in Y)
  /// used by that subtree, so the caller can place the next sibling below it.
  static double _layoutChildrenAsTree(
    Map<String, NodeModel> nodes,
    String parentId,
    double startX,
    double startY,
  ) {
    final parent = nodes[parentId];
    if (parent == null) return startY;
    if (parent.childrenIds.isEmpty) return startY + parent.size.height;

    var currentY = startY;
    var bottom = startY;

    for (final childId in parent.childrenIds) {
      final child = nodes[childId];
      if (child == null) continue;

      nodes[childId] = child.copyWith(position: Offset(startX, currentY));

      final subtreeBottom = _layoutChildrenAsTree(
        nodes,
        childId,
        startX + treeHorizontalSpacing,
        currentY,
      );

      bottom = math.max(bottom, subtreeBottom);
      currentY = subtreeBottom + treeVerticalSpacing;
    }

    return bottom;
  }

  // ------------------------------------------------------------- org chart

  static void _applyOrgChart(Map<String, NodeModel> nodes, NodeModel root) {
    nodes[root.id] = root.copyWith(
      position: Offset(orgCenterX - root.size.width / 2, orgStartY),
    );
    _layoutChildrenOrgChart(
      nodes,
      root.id,
      orgCenterX,
      orgStartY + root.size.height + orgVerticalSpacing,
    );
  }

  static void _layoutChildrenOrgChart(
    Map<String, NodeModel> nodes,
    String parentId,
    double centerX,
    double y,
  ) {
    final parent = nodes[parentId];
    if (parent == null || parent.childrenIds.isEmpty) return;

    final children = parent.childrenIds
        .map((id) => nodes[id])
        .whereType<NodeModel>()
        .toList();
    if (children.isEmpty) return;

    // Centre the row under the parent instead of starting half a row to the
    // left of it.
    final totalWidth = children.length * orgHorizontalSpacing;
    var currentX = centerX - totalWidth / 2 + orgHorizontalSpacing / 2;

    for (final child in children) {
      nodes[child.id] = child.copyWith(
        position: Offset(currentX - child.size.width / 2, y),
      );

      _layoutChildrenOrgChart(
        nodes,
        child.id,
        currentX,
        y + child.size.height + orgVerticalSpacing,
      );

      currentX += orgHorizontalSpacing;
    }
  }
}
