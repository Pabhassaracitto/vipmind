import 'package:flutter/material.dart';

class PresentationScreen extends StatelessWidget {
  final String mindmapId;
  const PresentationScreen({super.key, required this.mindmapId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentation')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}