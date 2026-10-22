import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Full-screen presentation of a mindmap. Not implemented yet.
///
/// The editor already navigates here with `{'mindmapId': id}`.
class PresentationScreen extends StatelessWidget {
  const PresentationScreen({super.key, required this.mindmapId});

  final String mindmapId;

  @override
  Widget build(BuildContext context) {
    const String baseMessage =
        'Walk the audience through the map branch by branch, full screen.';

    return ComingSoonScreen(
      appBarTitle: 'Presentation',
      icon: Icons.slideshow_rounded,
      title: 'Present this mindmap',
      message: mindmapId.isEmpty ? baseMessage : '$baseMessage ($mindmapId)',
      points: const [
        'Step through nodes in depth-first order',
        'Collapse/expand a branch with a tap or arrow keys',
        'Timer and speaker notes per node',
      ],
    );
  }
}
