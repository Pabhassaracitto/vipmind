import 'package:flutter/material.dart';

class MindmapPreviewScreen extends StatelessWidget {
  final String mindmapId;

  const MindmapPreviewScreen({super.key, required this.mindmapId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
      ),
      body: Center(
        child: Text('Preview for Mindmap: $mindmapId'),
      ),
    );
  }
}