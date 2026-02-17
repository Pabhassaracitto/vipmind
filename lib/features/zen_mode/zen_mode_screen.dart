import 'package:flutter/material.dart';

class ZenModeScreen extends StatelessWidget {
  const ZenModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: Text(
          'Zen Mode',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
