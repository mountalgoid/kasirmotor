import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bengkel_pro/main.dart';

void main() {
  testWidgets('App basic navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BengkelProApp());

    // Verify splash screen content.
    expect(find.text('Bengkel Pro'), findsOneWidget);

    // Pump for splash screen delay (3 seconds + some extra)
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Verify that dashboard content is shown.
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
  });
}
