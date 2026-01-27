import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/mindmap_model.dart';

class MindmapCard extends StatelessWidget {
  final MindmapModel mindmap;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final bool isListView;

  const MindmapCard({
    super.key,
    required this.mindmap,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListView) {
      return _buildListTile(context);
    }
    return _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: _getLayoutColor().withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    // Preview placeholder
                    Center(
                      child: Icon(
                        _getLayoutIcon(),
                        size: 48,
                        color: _getLayoutColor().withOpacity(0.5),
                      ),
                    ),

                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            mindmap.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: mindmap.isFavorite
                                ? AppColors.errorRed
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    // Node count badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${mindmap.nodes.length} nodes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mindmap.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(mindmap.updatedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildMenuButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getLayoutColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getLayoutIcon(),
                color: _getLayoutColor(),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mindmap.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${mindmap.nodes.length} nodes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(mindmap.updatedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                mindmap.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: mindmap.isFavorite
                    ? AppColors.errorRed
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),

            _buildMenuButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'delete':
            onDelete();
            break;
          case 'share':
            // Implement share
            break;
          case 'duplicate':
            // Implement duplicate
            break;
        }
      },
      icon: const Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textSecondary,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 8),
              Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: AppColors.errorRed),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppColors.errorRed)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLayoutColor() {
    switch (mindmap.layout) {
      case MindmapLayout.radial:
        return AppColors.primaryBlue;
      case MindmapLayout.tree:
        return AppColors.calmGreen;
      case MindmapLayout.orgChart:
        return AppColors.creativePurple;
      case MindmapLayout.fishbone:
        return AppColors.warningOrange;
      case MindmapLayout.timeline:
        return AppColors.accentYellow;
      case MindmapLayout.freeform:
        return AppColors.infoBlue;
    }
  }

  IconData _getLayoutIcon() {
    switch (mindmap.layout) {
      case MindmapLayout.radial:
        return Icons.blur_circular;
      case MindmapLayout.tree:
        return Icons.account_tree;
      case MindmapLayout.orgChart:
        return Icons.corporate_fare;
      case MindmapLayout.fishbone:
        return Icons.call_split;
      case MindmapLayout.timeline:
        return Icons.timeline;
      case MindmapLayout.freeform:
        return Icons.gesture;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
