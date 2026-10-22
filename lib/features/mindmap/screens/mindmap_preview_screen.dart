import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/mindmap_model.dart';
import '../../../data/models/node_model.dart';
import '../../../data/providers/mindmap_provider.dart';

/// Read-only view of a mindmap: an indented outline of every branch plus a
/// button to jump into the editor.
///
/// Used by `AppRoutes.mindmapPreview` (`{'mindmapId': id}`). It was previously a
/// one-line "Preview: id" label.
class MindmapPreviewScreen extends StatefulWidget {
  const MindmapPreviewScreen({super.key, required this.mindmapId});

  final String mindmapId;

  @override
  State<MindmapPreviewScreen> createState() => _MindmapPreviewScreenState();
}

class _MindmapPreviewScreenState extends State<MindmapPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<MindmapProvider>();
    if (provider.currentMindmap?.id == widget.mindmapId) return;
    await provider.loadMindmap(widget.mindmapId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            tooltip: 'Open in editor',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.mindmapEditor,
              arguments: {'mindmapId': widget.mindmapId},
            ),
          ),
        ],
      ),
      body: Consumer<MindmapProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final mindmap = provider.currentMindmap;
          if (mindmap == null || mindmap.id != widget.mindmapId) {
            return _Empty(
              icon: Icons.travel_explore_rounded,
              title: 'Mindmap not found',
              message: provider.error ??
                  'It may have been deleted, or you are offline and it is not '
                      'cached on this device.',
            );
          }

          return _Outline(mindmap: mindmap);
        },
      ),
    );
  }
}

class _Outline extends StatelessWidget {
  const _Outline({required this.mindmap});

  final MindmapModel mindmap;

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(mindmap.rootNode, mindmap, 0, <String>{});

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          mindmap.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${mindmap.nodes.length} nodes · ${mindmap.connections.length} links · '
          'layout: ${mindmap.layout.name}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (rows.isEmpty)
          const _Empty(
            icon: Icons.account_tree_outlined,
            title: 'Empty map',
            message: 'This mindmap has no nodes yet.',
          )
        else
          for (final row in rows) _OutlineRow(row: row),
      ],
    );
  }

  /// Depth-first walk of the tree; [visited] guards against cycles that would
  /// otherwise hang the build.
  List<_OutlineItem> _flatten(
    NodeModel? node,
    MindmapModel mindmap,
    int depth,
    Set<String> visited,
  ) {
    if (node == null || !visited.add(node.id)) return const [];

    final items = <_OutlineItem>[_OutlineItem(node: node, depth: depth)];
    for (final childId in node.childrenIds) {
      items.addAll(
        _flatten(mindmap.nodes[childId], mindmap, depth + 1, visited),
      );
    }
    return items;
  }
}

class _OutlineItem {
  const _OutlineItem({required this.node, required this.depth});

  final NodeModel node;
  final int depth;
}

class _OutlineRow extends StatelessWidget {
  const _OutlineRow({required this.row});

  final _OutlineItem row;

  @override
  Widget build(BuildContext context) {
    final node = row.node;

    return Padding(
      padding: EdgeInsets.only(left: row.depth * 20.0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: node.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.text.isEmpty ? '(no text)' : node.text,
                  style: TextStyle(
                    fontSize: row.depth == 0 ? 16 : 14,
                    fontWeight: row.depth == 0 ? FontWeight.w700 : null,
                  ),
                ),
                if (node.description != null && node.description!.isNotEmpty)
                  Text(
                    node.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (node.isAnkiCard)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'flashcard',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.creativePurple,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
