import 'package:flutter/material.dart';
import '../../../app/theme/app_fonts.dart';

import '../../../data/models/node_model.dart';

class NodeWidget extends StatefulWidget {
  final NodeModel node;
  final bool isSelected;
  final bool isDragging;
  final bool isZenMode;

  const NodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isDragging = false,
    this.isZenMode = false,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isDragging
                ? 1.1
                : (widget.isSelected ? 1.02 : _scaleAnimation.value),
            child: Container(
              width: widget.node.size.width,
              constraints: BoxConstraints(
                minHeight: widget.node.size.height,
              ),
              decoration: _buildDecoration(),
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    final baseColor = widget.node.color;
    final isHighlighted = widget.isSelected || _isHovered || widget.isDragging;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor,
          baseColor.withValues(alpha: 0.85),
        ],
      ),
      borderRadius: _getBorderRadius(),
      border: widget.isSelected
          ? Border.all(color: Colors.white, width: 3)
          : widget.isDragging
              ? Border.all(color: Colors.white70, width: 2)
              : null,
      boxShadow: [
        // Base shadow
        BoxShadow(
          color: baseColor.withValues(alpha: widget.isZenMode ? 0.5 : 0.3),
          blurRadius: isHighlighted ? 20 : 12,
          spreadRadius: isHighlighted ? 4 : 2,
          offset: const Offset(0, 4),
        ),
        // Glow effect on hover
        if (_isHovered || widget.isSelected)
          BoxShadow(
            color: baseColor.withValues(alpha: 0.4 * _glowAnimation.value),
            blurRadius: 30,
            spreadRadius: 8,
          ),
      ],
    );
  }

  BorderRadius _getBorderRadius() {
    switch (widget.node.shape) {
      case NodeShape.rectangle:
        return BorderRadius.circular(8);
      case NodeShape.roundedRectangle:
        return BorderRadius.circular(16);
      case NodeShape.ellipse:
        return BorderRadius.circular(100);
      case NodeShape.diamond:
        return BorderRadius.circular(4);
      case NodeShape.hexagon:
        return BorderRadius.circular(12);
    }
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Row
          if (widget.node.iconName != null || _getTypeIcon() != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (widget.node.iconName != null)
                    Text(
                      widget.node.iconName!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  if (_getTypeIcon() != null) ...[
                    if (widget.node.iconName != null) const SizedBox(width: 8),
                    Icon(_getTypeIcon(), size: 16, color: Colors.white70),
                  ],
                ],
              ),
            ),

          // Title
          Text(
            widget.node.text,
            style: AppFonts.inter(
              fontSize: _getTitleFontSize(),
              fontWeight: FontWeight.w600,
              color: widget.node.textColor,
              height: 1.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          // Description
          if (widget.node.description != null &&
              widget.node.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.node.description!,
              style: AppFonts.inter(
                fontSize: 12,
                color: widget.node.textColor.withValues(alpha: 0.8),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Indicators Row
          if (_hasIndicators()) ...[
            const SizedBox(height: 12),
            _buildIndicatorsRow(),
          ],
        ],
      ),
    );
  }

  double _getTitleFontSize() {
    final textLength = widget.node.text.length;
    if (textLength > 50) return 12;
    if (textLength > 30) return 14;
    return 16;
  }

  IconData? _getTypeIcon() {
    switch (widget.node.type) {
      case NodeType.task:
        return Icons.check_circle_outline;
      case NodeType.question:
        return Icons.help_outline;
      case NodeType.audio:
        return Icons.mic;
      case NodeType.image:
        return Icons.image;
      case NodeType.link:
        return Icons.link;
      default:
        return null;
    }
  }

  bool _hasIndicators() {
    return widget.node.audioNote != null ||
        widget.node.childrenIds.isNotEmpty ||
        widget.node.isAnkiCard;
  }

  Widget _buildIndicatorsRow() {
    return Row(
      children: [
        // Audio indicator
        if (widget.node.audioNote != null)
          _IndicatorBadge(
            icon: Icons.record_voice_over,
            label: _formatDuration(widget.node.audioNote!.duration),
          ),

        // Children count
        if (widget.node.childrenIds.isNotEmpty)
          _IndicatorBadge(
            icon: Icons.account_tree,
            label: '${widget.node.childrenIds.length}',
          ),

        // Anki indicator
        if (widget.node.isAnkiCard)
          const _IndicatorBadge(
            icon: Icons.style,
            label: 'Anki',
          ),

        const Spacer(),

        // Expand/Collapse button
        if (widget.node.childrenIds.isNotEmpty)
          Icon(
            widget.node.isExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
            size: 20,
            color: Colors.white70,
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _IndicatorBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IndicatorBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
