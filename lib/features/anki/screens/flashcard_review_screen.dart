import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Review session for one deck. Not implemented yet.
///
/// Reached from [AnkiDeckScreen] with `{'deckId': id}`.
class FlashcardReviewScreen extends StatelessWidget {
  const FlashcardReviewScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return ComingSoonScreen(
      appBarTitle: 'Review',
      icon: Icons.psychology_alt_rounded,
      title: deckId.isEmpty ? 'Review session' : 'Review "$deckId"',
      message:
          'Flip through the due cards, grade your recall from 0 to 5, and the '
          'SM-2 algorithm schedules the next review.',
      points: const [
        'Tap to reveal the back of the card',
        'Grade buttons: Again / Hard / Good / Easy',
        'Session summary: kept, missed, next due date',
      ],
    );
  }
}
