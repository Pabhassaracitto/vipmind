import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/models/mindmap_model.dart';
import '../../../data/models/node_model.dart';
import '../../../data/models/connection_model.dart';
import '../../../app/theme/app_colors.dart';

class ConnectionPainter extends CustomPainter {
  final MindmapModel mindmap;
  final Offset offset;
  final double scale;
  final String? selectedNodeId;
  final bool isZenMode;

  ConnectionPainter({
    required this.mindmap,
    required this.offset,
    required this.scale,
    this.selectedNodeId,
    this.isZenMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw parent-child connections
    for (final node in mindmap.nodes.values) {
      if (node.parentId != null) {
        final parent = mindmap.nodes[node.parentId];
        if (parent != null) {
          _drawConnection(
            canvas,
            parent,
            node,
            isHighlighted: selectedNodeId == node.id ||
                selectedNodeId == parent.id,
          );
        }
      }
    }

    // Draw custom connections
    for (final connection in mindmap.connections) {
      final fromNode = mindmap.nodes[connection.fromNodeId];
      final toNode = mindmap.nodes[connection.toNodeId];
      if (fromNode != null && toNode != null) {
        _drawCustomConnection(canvas, connection, fromNode, toNode);
      }
    }
  }

  void _drawConnection(
      Canvas canvas,
      NodeModel from,
      NodeModel to, {
        bool isHighlighted = false,
      }) {
    final fromCenter = _transformPoint(from.center);
    final toCenter = _transformPoint(to.center);

    // Calculate connection points on node edges
    final fromPoint = _getEdgePoint(from, toCenter);
    final toPoint = _getEdgePoint(to, fromCenter);

    final paint = Paint()
      ..color = isHighlighted
          ? Colors.white
          : (isZenMode ? Colors.white38 : from.color.withValues(alpha: 0.6))
      ..strokeWidth = (isHighlighted ? 3.0 : 2.0) * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw curved connection
    final path = _createCurvedPath(fromPoint, toPoint);
    canvas.drawPath(path, paint);

    // Draw arrow at the end
    if (!isZenMode) {
      _drawArrow(canvas, toPoint, fromPoint, paint.color);
    }

    // Draw glow effect for highlighted connections
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 8.0 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }
  }

  void _drawCustomConnection(
      Canvas canvas,
      ConnectionModel connection,
      NodeModel from,
      NodeModel to,
      ) {
    final fromCenter = _transformPoint(from.center);
    final toCenter = _transformPoint(to.center);

    final fromPoint = _getEdgePoint(from, toCenter);
    final toPoint = _getEdgePoint(to, fromCenter);

    final paint = Paint()
      ..color = connection.color.withValues(alpha: 0.8)
      ..strokeWidth = connection.strokeWidth * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path path;
    switch (connection.style) {
      case ConnectionStyle.straight:
        path = Path()
          ..moveTo(fromPoint.dx, fromPoint.dy)
          ..lineTo(toPoint.dx, toPoint.dy);
        break;
      case ConnectionStyle.curved:
        path = _createCurvedPath(fromPoint, toPoint);
        break;
      case ConnectionStyle.orthogonal:
        path = _createOrthogonalPath(fromPoint, toPoint);
        break;
      case ConnectionStyle.bezier:
        path = _createBezierPath(fromPoint, toPoint);
        break;
    }

    // Dashed line for reference connections
    if (connection.type == ConnectionType.reference) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw label if exists
    if (connection.label != null) {
      _drawLabel(canvas, connection.label!, fromPoint, toPoint);
    }
  }

  Path _createCurvedPath(Offset from, Offset to) {
    final path = Path();
    path.moveTo(from.dx, from.dy);

    final midX = (from.dx + to.dx) / 2;
    final midY = (from.dy + to.dy) / 2;

    // Determine curve direction based on relative positions
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;

    Offset control1, control2;

    if (dx.abs() > dy.abs()) {
      // More horizontal
      control1 = Offset(midX, from.dy);
      control2 = Offset(midX, to.dy);
    } else {
      // More vertical
      control1 = Offset(from.dx, midY);
      control2 = Offset(to.dx, midY);
    }

    path.cubicTo(
      control1.dx, control1.dy,
      control2.dx, control2.dy,
      to.dx, to.dy,
    );

    return path;
  }

  Path _createOrthogonalPath(Offset from, Offset to) {
    final path = Path();
    path.moveTo(from.dx, from.dy);

    final midX = (from.dx + to.dx) / 2;

    path.lineTo(midX, from.dy);
    path.lineTo(midX, to.dy);
    path.lineTo(to.dx, to.dy);

    return path;
  }

  Path _createBezierPath(Offset from, Offset to) {
    final path = Path();
    path.moveTo(from.dx, from.dy);

    final dx = (to.dx - from.dx).abs() * 0.5;

    path.cubicTo(
      from.dx + dx, from.dy,
      to.dx - dx, to.dy,
      to.dx, to.dy,
    );

    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashWidth = 8.0 * scale;
    final dashSpace = 4.0 * scale;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset from, Color color) {
    final direction = (tip - from).direction;
    const arrowSize = 10.0;

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(direction - math.pi / 6),
      tip.dy - arrowSize * math.sin(direction - math.pi / 6),
    );
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(direction + math.pi / 6),
      tip.dy - arrowSize * math.sin(direction + math.pi / 6),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, String label, Offset from, Offset to) {
    final midPoint = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2,
    );

    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: isZenMode ? Colors.white54 : AppColors.textSecondary,
        fontSize: 10 * scale,
        backgroundColor: isZenMode
            ? Colors.black54
            : Colors.white.withValues(alpha: 0.9),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
  }

  Offset _transformPoint(Offset point) {
    return point * scale + offset;
  }

  Offset _getEdgePoint(NodeModel node, Offset targetPoint) {
    final center = _transformPoint(node.center);
    final scaledSize = node.size * scale;

    final direction = (targetPoint - center).direction;

    // Calculate intersection with node boundary
    final halfWidth = scaledSize.width / 2;
    final halfHeight = scaledSize.height / 2;

    double x, y;

    if (direction.abs() < math.pi / 4 || direction.abs() > 3 * math.pi / 4) {
      // Left or right edge
      x = direction.abs() < math.pi / 2 ? halfWidth : -halfWidth;
      y = x * math.tan(direction);
      y = y.clamp(-halfHeight, halfHeight);
    } else {
      // Top or bottom edge
      y = direction > 0 ? halfHeight : -halfHeight;
      x = y / math.tan(direction);
      x = x.clamp(-halfWidth, halfWidth);
    }

    return center + Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return mindmap != oldDelegate.mindmap ||
        offset != oldDelegate.offset ||
        scale != oldDelegate.scale ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        isZenMode != oldDelegate.isZenMode;
  }
}