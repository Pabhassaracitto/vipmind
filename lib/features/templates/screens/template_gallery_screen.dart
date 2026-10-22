import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/firestore_converters.dart';
import '../../../data/models/mindmap_model.dart';
import '../../../data/models/template_model.dart';
import '../../../data/providers/mindmap_provider.dart';

/// Template gallery.
///
/// Real (small) functionality: it loads the templates bundled in
/// `assets/templates/default_templates.json`, shows them as a grid and creates
/// a new mindmap from the one the user picks.
///
/// That asset used to be a 0-byte file and the screen used to be a
/// "Coming Soon" label, so the drawer entry did nothing.
/// Bundled template catalog (registered in pubspec.yaml → flutter: assets:).
const String kTemplatesAssetPath = 'assets/templates/default_templates.json';

class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  List<TemplateModel> _templates = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final raw = await rootBundle.loadString(kTemplatesAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('expected a JSON array of templates');
      }
      final templates = decoded
          .map((item) => TemplateModel.fromJson(firestoreMap(item)))
          .toList();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _useTemplate(TemplateModel template) async {
    final controller = TextEditingController(text: template.name);

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New mindmap from template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.description,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
              onSubmitted: (value) => Navigator.pop(dialogContext, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (title == null) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty || !mounted) return;

    final user = FirebaseService.currentUser;
    if (user == null) {
      _showMessage('Please sign in first — templates are saved to your account.');
      return;
    }

    final MindmapModel draft = template.createMindmap(
      title: trimmed,
      ownerId: user.uid,
    );

    final created = await context
        .read<MindmapProvider>()
        .createMindmapFromModel(draft);

    if (!mounted) return;
    if (created == null) {
      _showMessage('Could not save the mindmap. Check your connection.');
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.mindmapEditor,
      arguments: {'mindmapId': created.id},
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadTemplates();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.errorRed),
              const SizedBox(height: 16),
              const Text('Could not load the templates'),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    if (_templates.isEmpty) {
      return const Center(child: Text('No templates available yet.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) =>
          _TemplateCard(template: _templates[index], onTap: _useTemplate),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final TemplateModel template;
  final void Function(TemplateModel) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(Icons.account_tree_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (template.isOfficial)
                    const Icon(Icons.verified_rounded,
                        size: 18, color: AppColors.primaryBlue),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  template.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                ),
              ),
              Row(
                children: [
                  _Chip(label: '${template.nodes.length} nodes'),
                  const SizedBox(width: 8),
                  _Chip(label: template.category.name),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
