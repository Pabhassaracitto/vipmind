import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/app/app.dart';  // Import đúng

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeuroMindmapApp());  // Dùng tên đúng

    // Verify something shows up
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}