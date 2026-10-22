import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Text → Mindmap (AI). Not implemented yet.
///
/// Planned pipeline: paste/import text → split into headings & bullets →
/// create nodes/connections → open the editor.
class TextToMindmapScreen extends StatelessWidget {
  const TextToMindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      appBarTitle: 'Text to Mindmap',
      icon: Icons.notes_rounded,
      title: 'Turn text into a mindmap',
      message:
          'Paste an article, lecture note or outline and VipMind builds the '
          'node tree for you.',
      points: [
        'Paste text or import a .txt / .md file',
        'Detect headings and bullet levels → node depth',
        'Choose layout (radial / tree / org chart) before opening the editor',
      ],
    );
  }
}
