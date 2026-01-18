import 'package:flutter/material.dart';

import '../../../data/models/mindmap_model.dart';
import '../../../app/theme/app_colors.dart';

class ToolbarWidget extends StatelessWidget {
  final MindmapLayout currentLayout;
  final Function(MindmapLayout) onLayoutChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onZenMode;
  final VoidCallback? onPresent;

  const ToolbarWidget({
    super.key,
    required this.currentLayout,
    required this.onLayoutChanged,
    this.onUndo,
    this.onRedo,
    this.onZenMode,
    this.onPresent,
  });

  static const List<_LayoutOption> _layouts = [
    _LayoutOption(MindmapLayout.radial, Icons.blur_circular, 'Radial'),
    _LayoutOption(MindmapLayout.tree, Icons.account_tree, 'Tree'),
    _LayoutOption(MindmapLayout.orgChart, Icons.corporate_fare, 'Org Chart'),
    _LayoutOption(MindmapLayout.fishbone, Icons.call_split, 'Fishbone'),
    _LayoutOption(MindmapLayout.timeline, Icons.timeline, 'Timeline'),
    _LayoutOption(MindmapLayout.freeform, Icons.gesture, 'Freeform'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Undo / Redo Group
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.undo_rounded,
                onPressed: onUndo,
                tooltip: 'Undo (Ctrl+Z)',
              ),
              const SizedBox(width: 4),
              _ToolbarIconButton(
                icon: Icons.redo_rounded,
                onPressed: onRedo,
                tooltip: 'Redo (Ctrl+Y)',
              ),
            ],
          ),

          // Layout Selector
          Expanded(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: _layouts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final layout = _layouts[index];
                  final isSelected = currentLayout == layout.type;

                  return _LayoutButton(
                    icon: layout.icon,
                    label: layout.label,
                    isSelected: isSelected,
                    onTap: () => onLayoutChanged(layout.type),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.spa_rounded,
                onPressed: onZenMode,
                tooltip: 'Zen Mode',
                color: AppColors.calmGreen,
              ),
              const SizedBox(width: 4),
              _ToolbarIconButton(
                icon: Icons.slideshow_rounded,
                onPressed: onPresent,
                tooltip: 'Present',
                color: AppColors.creativePurple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LayoutOption {
  final MindmapLayout type;
  final IconData icon;
  final String label;

  const _LayoutOption(this.type, this.icon, this.label);
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  const _ToolbarIconButton({
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final buttonColor = color ?? AppColors.primaryBlue;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? buttonColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isEnabled ? buttonColor : AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayoutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
            color: AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}