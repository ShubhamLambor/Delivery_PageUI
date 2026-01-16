// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deliveryui/main.dart';
import 'package:deliveryui/providers/settings_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    await tester.pumpWidget(
      DeliveryBoyApp(
        isLoggedIn: false,
        settingsProvider: settingsProvider,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App launches with logged in user', (WidgetTester tester) async {
    // ✅ Create a mock SettingsProvider for testing
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    await tester.pumpWidget(
      DeliveryBoyApp(
        isLoggedIn: true,
        settingsProvider: settingsProvider,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
