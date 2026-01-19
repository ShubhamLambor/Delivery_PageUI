// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deliveryui/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // ✅ Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': false,
    });

    await tester.pumpWidget(
      const DeliveryBoyApp(),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App launches with logged in user', (WidgetTester tester) async {
    // ✅ Mock SharedPreferences with logged in state
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
    });

    await tester.pumpWidget(
      const DeliveryBoyApp(),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('SplashScreen appears on app launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': false,
    });

    await tester.pumpWidget(
      const DeliveryBoyApp(),
    );

    await tester.pump();

    // ✅ Verify splash screen shows
    expect(find.text('Tiffinity'), findsOneWidget);
    expect(find.text('Delivery Partner Portal'), findsOneWidget);
  });

  testWidgets('Settings provider initializes correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': false,
      'isDarkMode': false,
    });

    await tester.pumpWidget(
      const DeliveryBoyApp(),
    );

    await tester.pumpAndSettle();

    // ✅ App should build without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
