// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lshare/app.dart';

void main() {
  testWidgets('LShare app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LShareApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
