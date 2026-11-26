import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';

void main() {
  group('KosListScreen', () {
    testWidgets('shows kos names and monthly prices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(() async => [_kos('Kos Asri')]),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Kos Asri'), findsOneWidget);
      expect(find.text('Rp 800000'), findsOneWidget);
    });

    testWidgets('shows loading while the repository is waiting', (
      tester,
    ) async {
      final completer = Completer<List<Kos>>();

      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(() => completer.future),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pump();

      expect(find.text('Data kos tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows an empty state when no kos are returned', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(repository: _FakeKosRepository(() async => [])),
        ),
      );
      await tester.pump();

      expect(find.text('Data kos tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows a clear error when loading fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => throw Exception('network unavailable'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Gagal memuat data kos. Periksa koneksi, lalu coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Kos Asri'), findsNothing);
    });

    testWidgets('keeps a 1,000-row list lazy', (tester) async {
      final kos = List.generate(1000, (index) => _kos('Kos $index'));

      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(repository: _FakeKosRepository(() async => kos)),
        ),
      );
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 1000);
      expect(find.text('Kos 0'), findsOneWidget);
      expect(find.text('Kos 999'), findsNothing);
    });
  });
}

class _FakeKosRepository implements KosRepository {
  _FakeKosRepository(this._loadKos);

  final Future<List<Kos>> Function() _loadKos;

  @override
  Future<List<Kos>> getAllKos() => _loadKos();

  @override
  Future<Kos?> getKosById(String id) async => null;
}

Kos _kos(String name) => Kos(
  id: name,
  ownerId: 'owner-1',
  nama: name,
  alamat: 'Jl. Melati',
  hargaBulanan: 800000,
  deskripsi: 'Dekat kampus',
  createdAt: DateTime.utc(2026, 1, 2),
);
