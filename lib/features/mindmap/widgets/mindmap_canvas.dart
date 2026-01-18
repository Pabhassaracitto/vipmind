import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../../data/models/mindmap_model.dart';
import '../../../data/models/node_model.dart';
import '../../../app/theme/app_colors.dart';
import 'node_widget.dart';
import 'connection_painter.dart';

class MindmapCanvas extends StatefulWidget {
  final MindmapModel mindmap;
  final String? selectedNodeId;
  final Offset canvasOffset;
  final double canvasScale;
  final Function(NodeModel?) onNodeSelected;
  final Function(String, Offset) onNodeMoved;
  final Function(Offset) onCanvasOffsetChanged;
  final Function(double) onCanvasScaleChanged;
  final Function(Offset) onDoubleTap;
  final VoidCallback onEmptyTap;
  final bool isZenMode;

  const MindmapCanvas({
    super.key,
    required this.mindmap,
    required this.selectedNodeId,
    required this.canvasOffset,
    required this.canvasScale,
    required this.onNodeSelected,
    required this.onNodeMoved,
    required this.onCanvasOffsetChanged,
    required this.onCanvasScaleChanged,
    required this.onDoubleTap,
    required this.onEmptyTap,
    this.isZenMode = false,
  });

  @override
  State<MindmapCanvas> createState() => _MindmapCanvasState();
}

class _MindmapCanvasState extends State<MindmapCanvas>
    with SingleTickerProviderStateMixin {
  Offset? _lastFocalPoint;
  double? _lastScale;
  String? _draggingNodeId;
  Offset? _dragStartPosition;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastScale = widget.canvasScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Pan
    if (details.pointerCount == 1 && _draggingNodeId == null) {
      final delta = details.focalPoint - _lastFocalPoint!;
      widget.onCanvasOffsetChanged(widget.canvasOffset + delta);
      _lastFocalPoint = details.focalPoint;
    }
    // Zoom
    else if (details.pointerCount == 2) {
      final newScale = (_lastScale! * details.scale).clamp(0.2, 3.0);
      widget.onCanvasScaleChanged(newScale);
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    // Calculate position in canvas coordinates
    final canvasPosition = _screenToCanvas(details.localPosition);
    widget.onDoubleTap(canvasPosition);
  }

  Offset _screenToCanvas(Offset screenPosition) {
    return (screenPosition - widget.canvasOffset) / widget.canvasScale;
  }

  Offset _canvasToScreen(Offset canvasPosition) {
    return canvasPosition * widget.canvasScale + widget.canvasOffset;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.mindmap.nodes.values.toList();

    // Sort nodes by depth for proper z-ordering
    nodes.sort((a, b) => a.depth.compareTo(b.depth));

    return GestureDetector(
      onTap: widget.onEmptyTap,
      onDoubleTapDown: _onDoubleTapDown,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Listener(
        onPointerSignal: (event) {
          // Mouse wheel zoom for desktop
          if (event is PointerScrollEvent) {
            final delta = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
            final newScale = (widget.canvasScale + delta).clamp(0.2, 3.0);
            widget.onCanvasScaleChanged(newScale);
          }
        },
        child: Container(
          color: widget.isZenMode
              ? AppColors.backgroundDark
              : Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            children: [
              // Background Grid
              if (!widget.isZenMode) _buildGrid(),

              // Connections Layer
              CustomPaint(
                size: Size.infinite,
                painter: ConnectionPainter(
                  mindmap: widget.mindmap,
                  offset: widget.canvasOffset,
                  scale: widget.canvasScale,
                  selectedNodeId: widget.selectedNodeId,
                  isZenMode: widget.isZenMode,
                ),
              ),

              // Nodes Layer
              ...nodes.map((node) => _buildNodeWidget(node)),

              // Empty State
              if (nodes.isEmpty) _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(
        offset: widget.canvasOffset,
        scale: widget.canvasScale,
        color: AppColors.textSecondary.withOpacity(0.05),
      ),
    );
  }

  Widget _buildNodeWidget(NodeModel node) {
    final screenPosition = _canvasToScreen(node.position);
    final isSelected = node.id == widget.selectedNodeId;

    return Positioned(
      left: screenPosition.dx,
      top: screenPosition.dy,
      child: Transform.scale(
        scale: widget.canvasScale,
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () {
            widget.onNodeSelected(node);
          },
          onPanStart: (details) {
            setState(() {
              _draggingNodeId = node.id;
              _dragStartPosition = node.position;
            });
          },
          onPanUpdate: (details) {
            if (_draggingNodeId == node.id) {
              final delta = details.delta / widget.canvasScale;
              widget.onNodeMoved(node.id, node.position + delta);
            }
          },
          onPanEnd: (details) {
            setState(() {
              _draggingNodeId = null;
              _dragStartPosition = null;
            });
          },
          child: NodeWidget(
            node: node,
            isSelected: isSelected,
            isDragging: _draggingNodeId == node.id,
            isZenMode: widget.isZenMode,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Double-tap to create your first idea',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: widget.isZenMode ? Colors.white70 : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Or use the + button below',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isZenMode
                        ? Colors.white38
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final Color color;

  _GridPainter({
    required this.offset,
    required this.scale,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const gridSize = 50.0;
    final scaledGridSize = gridSize * scale;

    // Vertical lines
    double x = offset.dx % scaledGridSize;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += scaledGridSize;
    }

    // Horizontal lines
    double y = offset.dy % scaledGridSize;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += scaledGridSize;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return offset != oldDelegate.offset || scale != oldDelegate.scale;
  }
}