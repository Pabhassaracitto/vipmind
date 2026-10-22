import 'package:flutter/material.dart';

import '../../../data/models/node_model.dart';
import '../../../app/theme/app_colors.dart';

class NodeEditorPanel extends StatefulWidget {
  final NodeModel? node;
  final VoidCallback onClose;
  final Function(NodeModel) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;

  const NodeEditorPanel({
    super.key,
    required this.node,
    required this.onClose,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddChild,
  });

  @override
  State<NodeEditorPanel> createState() => _NodeEditorPanelState();
}

class _NodeEditorPanelState extends State<NodeEditorPanel> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node?.text ?? '');
    _descriptionController =
        TextEditingController(text: widget.node?.description ?? '');
  }

  @override
  void didUpdateWidget(NodeEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node?.id != oldWidget.node?.id) {
      _titleController.text = widget.node?.text ?? '';
      _descriptionController.text = widget.node?.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateNode(NodeModel Function(NodeModel) updater) {
    if (widget.node != null) {
      widget.onUpdate(updater(widget.node!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    if (node == null) return const SizedBox.shrink();

    return Container(
      width: 340,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 12,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [node.color, node.color.withValues(alpha: 0.8)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Node',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: node.textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: node.textColor),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Title
                const _SectionTitle(title: 'Title'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter node title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _updateNode((n) => n.copyWith(text: value));
                  },
                ),

                const SizedBox(height: 24),

                // Description
                const _SectionTitle(title: 'Description'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _updateNode((n) => n.copyWith(description: value));
                  },
                ),

                const SizedBox(height: 24),

                // Color
                const _SectionTitle(title: 'Color'),
                const SizedBox(height: 12),
                _ColorPicker(
                  selectedColor: node.color,
                  onColorSelected: (color) {
                    _updateNode((n) => n.copyWith(color: color));
                  },
                ),

                const SizedBox(height: 24),

                // Shape
                const _SectionTitle(title: 'Shape'),
                const SizedBox(height: 12),
                _ShapePicker(
                  selectedShape: node.shape,
                  onShapeSelected: (shape) {
                    _updateNode((n) => n.copyWith(shape: shape));
                  },
                ),

                const SizedBox(height: 24),

                // Type
                const _SectionTitle(title: 'Node Type'),
                const SizedBox(height: 12),
                _TypePicker(
                  selectedType: node.type,
                  onTypeSelected: (type) {
                    _updateNode((n) => n.copyWith(type: type));
                  },
                ),

                const SizedBox(height: 24),

                // Anki Toggle
                SwitchListTile(
                  title: const Text('Add to Flashcards'),
                  subtitle: const Text('Create Anki card from this node'),
                  value: node.isAnkiCard,
                  onChanged: (value) {
                    _updateNode((n) => n.copyWith(
                          isAnkiCard: value,
                          ankiFront: value ? n.text : null,
                          ankiBack: value ? n.description : null,
                        ));
                  },
                  activeThumbColor: AppColors.primaryBlue,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onAddChild,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Child'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Delete Button
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Node'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const _ColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppColors.nodeColors.map((color) {
        final isSelected = selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border:
                  isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isSelected ? 0.5 : 0.3),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _ShapePicker extends StatelessWidget {
  final NodeShape selectedShape;
  final Function(NodeShape) onShapeSelected;

  const _ShapePicker({
    required this.selectedShape,
    required this.onShapeSelected,
  });

  static const Map<NodeShape, IconData> _shapeIcons = {
    NodeShape.rectangle: Icons.crop_square,
    NodeShape.roundedRectangle: Icons.rounded_corner,
    NodeShape.ellipse: Icons.circle_outlined,
    NodeShape.diamond: Icons.diamond_outlined,
    NodeShape.hexagon: Icons.hexagon_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: NodeShape.values.map((shape) {
        final isSelected = selectedShape == shape;
        return GestureDetector(
          onTap: () => onShapeSelected(shape),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              _shapeIcons[shape],
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TypePicker extends StatelessWidget {
  final NodeType selectedType;
  final Function(NodeType) onTypeSelected;

  const _TypePicker({
    required this.selectedType,
    required this.onTypeSelected,
  });

  static const Map<NodeType, _TypeInfo> _typeInfo = {
    NodeType.idea:
        _TypeInfo(Icons.lightbulb_outline, 'Idea', AppColors.accentYellow),
    NodeType.task:
        _TypeInfo(Icons.check_circle_outline, 'Task', AppColors.calmGreen),
    NodeType.question:
        _TypeInfo(Icons.help_outline, 'Question', AppColors.warningOrange),
    NodeType.note:
        _TypeInfo(Icons.note_outlined, 'Note', AppColors.primaryBlue),
    NodeType.image:
        _TypeInfo(Icons.image_outlined, 'Image', AppColors.creativePurple),
    NodeType.audio: _TypeInfo(Icons.mic_outlined, 'Audio', AppColors.errorRed),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NodeType.values.map((type) {
        final info = _typeInfo[type]!;
        final isSelected = selectedType == type;

        return GestureDetector(
          onTap: () => onTypeSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? info.color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? info.color : info.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  info.icon,
                  size: 18,
                  color: isSelected ? Colors.white : info.color,
                ),
                const SizedBox(width: 6),
                Text(
                  info.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : info.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TypeInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeInfo(this.icon, this.label, this.color);
}
