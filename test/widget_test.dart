import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deliveryui/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryBoyApp(isLoggedIn: false));

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App launches with logged in user', (WidgetTester tester) async {
    await tester.pumpWidget(const DeliveryBoyApp(isLoggedIn: true));

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
