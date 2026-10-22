import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Flashcard decks generated from mindmap nodes.
///
/// Not implemented in the UI yet, but the engine is: `AnkiCardModel.review()`
/// already implements SM-2 spaced repetition and `NodeModel` carries
/// `isAnkiCard` / `ankiFront` / `ankiBack` / `ankiInterval` / `ankiNextReview`.
/// What is missing is this screen (deck list) + the review screen.
class AnkiDeckScreen extends StatelessWidget {
  const AnkiDeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      appBarTitle: 'Flashcards',
      icon: Icons.style_rounded,
      title: 'Flashcards from your mindmap',
      message:
          'Mark any node as a flashcard in the editor and it shows up here as a '
          'deck you can review with spaced repetition.',
      points: [
        'SM-2 scheduling is already implemented (AnkiCardModel.review)',
        'Deck = one mindmap; card = one node flagged "isAnkiCard"',
        'Due-today counter and review session',
      ],
    );
  }
}
