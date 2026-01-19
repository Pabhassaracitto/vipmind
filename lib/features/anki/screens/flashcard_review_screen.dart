import 'package:flutter/material.dart';

class FlashcardReviewScreen extends StatelessWidget {
  final String deckId;
  const FlashcardReviewScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}