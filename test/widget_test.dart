import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bengkel_pro/main.dart';

void main() {
  testWidgets('App basic navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BengkelProApp());

    // Verify that dashboard content is shown.
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
    expect(find.text('Selamat datang kembali di Bengkel Pro'), findsOneWidget);
  });
}
