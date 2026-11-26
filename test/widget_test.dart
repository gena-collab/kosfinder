// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/main.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

void main() {
  testWidgets('shows a configuration error instead of crashing', (
    WidgetTester tester,
  ) async {
    const message = 'SUPABASE_URL belum diatur.';

    await tester.pumpWidget(
      const MyApp(startupResult: AppStartupResult.failure(message)),
    );

    expect(find.text(message), findsOneWidget);
  });

  testWidgets('opens the kos list and About page from app navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: KosFinderHome(repository: _EmptyKosRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Kos'), findsWidgets);
    expect(find.text('Data kos tidak ditemukan.'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('2415051038 - Gena Anggarani'), findsOneWidget);
  });
}

class _EmptyKosRepository implements KosRepository {
  @override
  Future<List<Kos>> getAllKos() async => [];

  @override
  Future<Kos?> getKosById(String id) async => null;
}
