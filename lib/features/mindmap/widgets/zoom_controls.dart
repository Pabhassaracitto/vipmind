import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class ZoomControls extends StatelessWidget {
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const ZoomControls({
    super.key,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (scale * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In
          _ZoomButton(
            icon: Icons.add,
            onTap: onZoomIn,
            tooltip: 'Zoom In',
            isTop: true,
          ),

          // Percentage Display
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Zoom Out
          _ZoomButton(
            icon: Icons.remove,
            onTap: onZoomOut,
            tooltip: 'Zoom Out',
            isBottom: true,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isTop;
  final bool isBottom;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isTop = false,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isTop ? const Radius.circular(16) : Radius.zero,
            bottom: isBottom ? const Radius.circular(16) : Radius.zero,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}
