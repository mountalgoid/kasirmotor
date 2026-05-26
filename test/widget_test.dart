import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bengkel_pro/main.dart';

void main() {
  testWidgets('App branding test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BengkelProApp());

    // Verify that splash screen content is shown.
    expect(find.text('Ibrahim Part'), findsOneWidget);
    expect(find.text('Solusi Suku Cadang Terpercaya'), findsOneWidget);

    // Fast forward splash screen
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    // Verify that dashboard content is shown.
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
    expect(find.text('Selamat datang kembali di Ibrahim Part'), findsOneWidget);
  });
}
