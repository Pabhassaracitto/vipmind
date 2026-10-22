import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Voice → Mindmap (AI). Not implemented yet.
///
/// Needs a speech-to-text engine; `speech_to_text` was removed from pubspec
/// because nothing used it — add it back in the commit that implements this.
class VoiceToMindmapScreen extends StatelessWidget {
  const VoiceToMindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      appBarTitle: 'Voice to Mindmap',
      icon: Icons.mic_rounded,
      title: 'Speak your ideas, get a map',
      message:
          'Record yourself explaining a topic and VipMind turns the transcript '
          'into a structured mindmap.',
      points: [
        'Record with the microphone permission already declared on Android',
        'Transcribe on device or via an API (decision pending)',
        'Show the transcript for editing before generating nodes',
      ],
    );
  }
}
