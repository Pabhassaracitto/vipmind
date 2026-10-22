import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Image → Mindmap (AI). Not implemented yet.
class ImageToMindmapScreen extends StatelessWidget {
  const ImageToMindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      appBarTitle: 'Image to Mindmap',
      icon: Icons.image_search_rounded,
      title: 'Scan a page into a mindmap',
      message:
          'Photograph a whiteboard, a book page or handwritten notes and '
          'VipMind extracts the structure.',
      points: [
        'Pick from gallery or take a photo',
        'OCR the image, then group lines into branches',
        'Attach the original image to the root node',
      ],
    );
  }
}
