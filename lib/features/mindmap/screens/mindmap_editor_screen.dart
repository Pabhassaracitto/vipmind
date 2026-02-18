import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/models/mindmap_model.dart';
import '../../../data/models/node_model.dart';
import '../../../data/providers/mindmap_provider.dart';
import '../widgets/mindmap_canvas.dart';
import '../widgets/minimap_widget.dart';
import '../widgets/node_editor_panel.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/zoom_controls.dart';

class MindmapEditorScreen extends StatefulWidget {
  final String? mindmapId;

  const MindmapEditorScreen({super.key, this.mindmapId});

  @override
  State<MindmapEditorScreen> createState() => _MindmapEditorScreenState();
}

class _MindmapEditorScreenState extends State<MindmapEditorScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _panelController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _panelSlideAnimation;

  bool _isToolbarVisible = true;
  bool _isPanelOpen = false;
  bool _isZenMode = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMindmap();
    _setupKeyboardShortcuts();
  }

  void _setupAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _panelController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _panelSlideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    ));

    // Delay FAB entrance animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  void _setupKeyboardShortcuts() {
    // Keyboard shortcuts for desktop
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final provider = context.read<MindmapProvider>();

      // Ctrl/Cmd + Z = Undo
      if (event.logicalKey == LogicalKeyboardKey.keyZ &&
          HardwareKeyboard.instance.isControlPressed) {
        provider.undo();
        return true;
      }

      // Ctrl/Cmd + Y = Redo
      if (event.logicalKey == LogicalKeyboardKey.keyY &&
          HardwareKeyboard.instance.isControlPressed) {
        provider.redo();
        return true;
      }

      // Delete = Delete selected node
      if (event.logicalKey == LogicalKeyboardKey.delete) {
        final selectedId = provider.selectedNodeId;
        if (selectedId != null) {
          provider.deleteNode(selectedId);
        }
        return true;
      }

      // Escape = Deselect
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        provider.selectNode(null);
        _closePanel();
        return true;
      }
    }
    return false;
  }

  Future<void> _loadMindmap() async {
    if (widget.mindmapId != null) {
      final provider = context.read<MindmapProvider>();

      // Check if mindmap is already loaded (from createMindmap)
      if (provider.currentMindmap?.id == widget.mindmapId) {
        // Mindmap already loaded, no need to reload
        debugPrint('Mindmap already loaded: ${widget.mindmapId}');
        return;
      }

      // Load from Firestore
      debugPrint('Loading mindmap from Firestore: ${widget.mindmapId}');
      await provider.loadMindmap(widget.mindmapId!);
    }
  }

  void _openPanel() {
    if (!_isPanelOpen) {
      setState(() => _isPanelOpen = true);
      _panelController.forward();
    }
  }

  void _closePanel() {
    if (_isPanelOpen) {
      setState(() => _isPanelOpen = false);
      _panelController.reverse();
    }
  }

  void _toggleZenMode() {
    setState(() {
      _isZenMode = !_isZenMode;
      _isToolbarVisible = !_isZenMode;
    });
    HapticService.mediumImpact();

    if (_isZenMode) {
      AudioService.playAmbient('forest');
    } else {
      AudioService.stopAmbient();
    }
  }

  void _onNodeSelected(NodeModel? node) {
    if (node != null) {
      HapticService.lightImpact();
      _openPanel();
    }
  }

  void _addNewNode({Offset? position}) {
    final provider = context.read<MindmapProvider>();
    final selectedId = provider.selectedNodeId;

    provider.addNode(
      text: 'New Idea',
      parentId: selectedId,
      position: position,
    );

    HapticService.mediumImpact();
    AudioService.playNodeCreate();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _panelController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _isZenMode
          ? AppColors.backgroundDark
          : Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<MindmapProvider>(
        builder: (context, provider, child) {
          final mindmap = provider.currentMindmap;

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (mindmap == null) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              // Main Canvas
              MindmapCanvas(
                mindmap: mindmap,
                selectedNodeId: provider.selectedNodeId,
                canvasOffset: provider.canvasOffset,
                canvasScale: provider.canvasScale,
                onNodeSelected: (node) {
                  provider.selectNode(node?.id);
                  _onNodeSelected(node);
                },
                onNodeMoved: (nodeId, position) {
                  provider.moveNode(nodeId, position);
                },
                onCanvasOffsetChanged: provider.setCanvasOffset,
                onCanvasScaleChanged: provider.setCanvasScale,
                onDoubleTap: (position) => _addNewNode(position: position),
                onEmptyTap: () {
                  provider.selectNode(null);
                  _closePanel();
                },
                isZenMode: _isZenMode,
              ),

              // Top App Bar
              if (!_isZenMode) _buildAppBar(mindmap),

              // Bottom Toolbar
              if (_isToolbarVisible && !_isZenMode)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: ToolbarWidget(
                    currentLayout: mindmap.layout,
                    onLayoutChanged: (layout) {
                      provider.changeLayout(layout);
                      HapticService.selectionClick();
                    },
                    onUndo: provider.canUndo ? provider.undo : null,
                    onRedo: provider.canRedo ? provider.redo : null,
                    onZenMode: _toggleZenMode,
                    onPresent: () => _navigateToPresentation(mindmap.id),
                  ),
                ),

              // Zoom Controls
              if (!_isZenMode)
                Positioned(
                  right: 20,
                  bottom: 120,
                  child: ZoomControls(
                    scale: provider.canvasScale,
                    onZoomIn: () {
                      provider.setCanvasScale(provider.canvasScale + 0.2);
                      HapticService.lightImpact();
                    },
                    onZoomOut: () {
                      provider.setCanvasScale(provider.canvasScale - 0.2);
                      HapticService.lightImpact();
                    },
                    onReset: () {
                      provider.resetCanvas();
                      HapticService.mediumImpact();
                    },
                  ),
                ),

              // Minimap
              if (!_isZenMode)
                Positioned(
                  left: 20,
                  bottom: 120,
                  child: MinimapWidget(
                    mindmap: mindmap,
                    currentOffset: provider.canvasOffset,
                    currentScale: provider.canvasScale,
                    onNavigate: provider.setCanvasOffset,
                  ),
                ),

              // Node Editor Panel (Slide from right)
              if (_isPanelOpen)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: _panelSlideAnimation,
                    child: NodeEditorPanel(
                      node: provider.selectedNode,
                      onClose: () {
                        provider.selectNode(null);
                        _closePanel();
                      },
                      onUpdate: (updatedNode) {
                        provider.updateNode(updatedNode);
                      },
                      onDelete: () {
                        if (provider.selectedNodeId != null) {
                          provider.deleteNode(provider.selectedNodeId!);
                          _closePanel();
                        }
                      },
                      onAddChild: () {
                        _addNewNode();
                      },
                    ),
                  ),
                ),

              // Floating Action Buttons
              if (!_isZenMode)
                Positioned(
                  right: 20,
                  bottom: 220,
                  child: ScaleTransition(
                    scale: _fabScaleAnimation,
                    child: _buildFABColumn(provider),
                  ),
                ),

              // Zen Mode Exit Button
              if (_isZenMode)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: IconButton(
                    onPressed: _toggleZenMode,
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Mindmap not found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(MindmapModel mindmap) {
    return Positioned(
      top: 0,
      left: 0,
      right: _isPanelOpen ? 340 : 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
            ],
          ),
        ),
        child: Row(
          children: [
            // Back Button
            IconButton(
              onPressed: () {
                context.read<MindmapProvider>().saveMindmap();
                Navigator.pop(context);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),

            const SizedBox(width: 8),

            // Title (Editable)
            Expanded(
              child: GestureDetector(
                onTap: () => _showRenameDialog(mindmap),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          mindmap.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Save Status
            Consumer<MindmapProvider>(
              builder: (context, provider, _) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        size: 16,
                        color: AppColors.successGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(width: 8),

            // More Options
            IconButton(
              onPressed: () => _showMoreOptions(mindmap),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.more_horiz_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFABColumn(MindmapProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Suggest
        _MiniFloatingButton(
          icon: Icons.auto_awesome,
          color: AppColors.creativePurple,
          tooltip: 'AI Suggestions',
          onPressed: () => _showAISuggestions(),
        ),
        const SizedBox(height: 12),

        // Voice Note
        _MiniFloatingButton(
          icon: Icons.mic_rounded,
          color: AppColors.accentYellow,
          tooltip: 'Voice Note',
          onPressed: () => _showVoiceRecorder(),
        ),
        const SizedBox(height: 12),

        // Add Image
        _MiniFloatingButton(
          icon: Icons.image_rounded,
          color: AppColors.calmGreen,
          tooltip: 'Add Image',
          onPressed: () => _showImagePicker(),
        ),
        const SizedBox(height: 16),

        // Main Add Button
        FloatingActionButton(
          onPressed: () => _addNewNode(),
          backgroundColor: AppColors.primaryBlue,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  void _showRenameDialog(MindmapModel mindmap) {
    final controller = TextEditingController(text: mindmap.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Mindmap'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context
                    .read<MindmapProvider>()
                    .updateMindmapTitle(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(MindmapModel mindmap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.slideshow_rounded,
                title: 'Present',
                subtitle: 'Cinematic presentation mode',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPresentation(mindmap.id);
                },
              ),
              _OptionTile(
                icon: Icons.share_rounded,
                title: 'Share',
                subtitle: 'Collaborate with others',
                onTap: () {
                  Navigator.pop(context);
                  _showShareDialog();
                },
              ),
              _OptionTile(
                icon: Icons.download_rounded,
                title: 'Export',
                subtitle: 'PDF, PNG, Markdown',
                onTap: () {
                  Navigator.pop(context);
                  _showExportOptions();
                },
              ),
              _OptionTile(
                icon: Icons.style_rounded,
                title: 'Create Flashcards',
                subtitle: 'Generate Anki cards from nodes',
                onTap: () {
                  Navigator.pop(context);
                  _createFlashcards();
                },
              ),
              _OptionTile(
                icon: Icons.copy_rounded,
                title: 'Duplicate',
                subtitle: 'Create a copy',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _OptionTile(
                icon: Icons.delete_rounded,
                title: 'Delete',
                subtitle: 'Remove this mindmap',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPresentation(String mindmapId) {
    Navigator.pushNamed(
      context,
      AppRoutes.presentation,
      arguments: {'mindmapId': mindmapId},
    );
  }

  void _showAISuggestions() {
    // Ví dụ cách truy cập key của bạn
    final zaloKey = dotenv.env['ZALO_AI_KEY'];
    final fptKey = dotenv.env['FPT_AI_KEY'];

    debugPrint('Zalo AI Key: $zaloKey');
    debugPrint('FPT AI Key: $fptKey');

    // TODO: Implement AI suggestions using the keys
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Suggestions coming soon!')),
    );
  }

  void _showVoiceRecorder() {
    // TODO: Implement voice recorder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice Recorder coming soon!')),
    );
  }

  void _showImagePicker() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image Picker coming soon!')),
    );
  }

  void _showShareDialog() {
    // TODO: Implement share
  }

  void _showExportOptions() {
    // TODO: Implement export
  }

  void _createFlashcards() {
    Navigator.pushNamed(context, AppRoutes.ankiDeck);
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mindmap'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this mindmap?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              context.read<MindmapProvider>().deleteMindmap(widget.mindmapId!);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MiniFloatingButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _MiniFloatingButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FloatingActionButton.small(
        heroTag: tooltip,
        onPressed: onPressed,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorRed : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: color?.withValues(alpha: 0.7))),
      onTap: onTap,
    );
  }
}
