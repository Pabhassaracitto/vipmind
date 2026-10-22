import 'package:flutter/material.dart';

import '../../../data/models/mindmap_model.dart';
import '../../../data/models/node_model.dart';
import '../../../app/theme/app_colors.dart';

class MinimapWidget extends StatelessWidget {
  final MindmapModel mindmap;
  final Offset currentOffset;
  final double currentScale;
  final Function(Offset) onNavigate;

  const MinimapWidget({
    super.key,
    required this.mindmap,
    required this.currentOffset,
    required this.currentScale,
    required this.onNavigate,
  });

  static const double _minimapSize = 120;
  static const double _padding = 8;

  @override
  Widget build(BuildContext context) {
    if (mindmap.nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate bounds of all nodes
    final bounds = _calculateBounds();
    if (bounds == null) return const SizedBox.shrink();

    final mapScale = _calculateMinimapScale(bounds);

    return GestureDetector(
      onPanUpdate: (details) {
        _handlePan(details.localPosition, bounds, mapScale);
      },
      onTapDown: (details) {
        _handlePan(details.localPosition, bounds, mapScale);
      },
      child: Container(
        width: _minimapSize,
        height: _minimapSize,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Nodes
              ...mindmap.nodes.values.map((node) {
                return _buildMinimapNode(node, bounds, mapScale);
              }),

              // Viewport indicator
              _buildViewportIndicator(bounds, mapScale, context),
            ],
          ),
        ),
      ),
    );
  }

  Rect? _calculateBounds() {
    if (mindmap.nodes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in mindmap.nodes.values) {
      minX = minX < node.position.dx ? minX : node.position.dx;
      minY = minY < node.position.dy ? minY : node.position.dy;
      maxX = maxX > (node.position.dx + node.size.width)
          ? maxX
          : (node.position.dx + node.size.width);
      maxY = maxY > (node.position.dy + node.size.height)
          ? maxY
          : (node.position.dy + node.size.height);
    }

    // Add padding
    const padding = 100.0;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  double _calculateMinimapScale(Rect bounds) {
    final scaleX = (_minimapSize - _padding * 2) / bounds.width;
    final scaleY = (_minimapSize - _padding * 2) / bounds.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  Widget _buildMinimapNode(NodeModel node, Rect bounds, double mapScale) {
    final x = (node.position.dx - bounds.left) * mapScale + _padding;
    final y = (node.position.dy - bounds.top) * mapScale + _padding;
    final width = node.size.width * mapScale;
    final height = node.size.height * mapScale;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: width.clamp(4.0, 20.0),
        height: height.clamp(3.0, 15.0),
        decoration: BoxDecoration(
          color: node.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildViewportIndicator(
      Rect bounds,
      double mapScale,
      BuildContext context,
      ) {
    // Calculate viewport rectangle
    final screenSize = MediaQuery.of(context).size;
    final viewportWidth = screenSize.width / currentScale;
    final viewportHeight = screenSize.height / currentScale;

    final viewportX = -currentOffset.dx / currentScale;
    final viewportY = -currentOffset.dy / currentScale;

    final x = (viewportX - bounds.left) * mapScale + _padding;
    final y = (viewportY - bounds.top) * mapScale + _padding;
    final width = viewportWidth * mapScale;
    final height = viewportHeight * mapScale;

    return Positioned(
      left: x.clamp(0, _minimapSize - 10),
      top: y.clamp(0, _minimapSize - 10),
      child: Container(
        width: width.clamp(20, _minimapSize - _padding * 2),
        height: height.clamp(15, _minimapSize - _padding * 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryBlue,
            width: 2,
          ),
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  void _handlePan(Offset localPosition, Rect bounds, double mapScale) {
    // Convert minimap position to canvas position
    final canvasX = (localPosition.dx - _padding) / mapScale + bounds.left;
    final canvasY = (localPosition.dy - _padding) / mapScale + bounds.top;

    // Calculate new offset to center on this position
    final screenSize = WidgetsBinding.instance.window.physicalSize /
        WidgetsBinding.instance.window.devicePixelRatio;

    final newOffset = Offset(
      -canvasX * currentScale + screenSize.width / 2,
      -canvasY * currentScale + screenSize.height / 2,
    );

    onNavigate(newOffset);
  }
}