import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:classlytics/main.dart';
import 'package:classlytics/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ClasslyticsApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
