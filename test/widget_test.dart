// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dispenser_obat_pintar/providers/device_provider.dart';
import 'package:dispenser_obat_pintar/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';


void main() {
  testWidgets('DashboardScreen builds correctly and finds manual dispense button', (WidgetTester tester) async {
    // Create the provider instance.
    final deviceProvider = DeviceProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: deviceProvider,
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Wait for all timers and animations to settle.
    await tester.pumpAndSettle();

    // Verify that the manual dispense button is present.
    expect(find.text('Keluarkan Obat Manual'), findsOneWidget);

    // Dispose the provider after the test.
    deviceProvider.dispose();
  });
}
