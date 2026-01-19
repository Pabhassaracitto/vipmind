import 'package:flutter/material.dart';

class ZenModeScreen extends StatelessWidget {
  const ZenModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: const Center(
        child: Text(
          'Zen Mode',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}