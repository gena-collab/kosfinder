import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/screens/about_screen.dart';

void main() {
  testWidgets('shows the required student identity', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    expect(find.text('2415051038 - Gena Anggarani'), findsOneWidget);
  });
}
