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

    testWidgets('searches by name and address', (tester) async {
      final kosByName = _kos('Kos Asri', address: 'Jl. Mawar');
      final kosByAddress = _kos('Kos Taman', address: 'Jl. Melati');
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => [kosByName, kosByAddress],
              null,
              (query, {maxPrice}) async {
                if (query == 'Asri') {
                  return [kosByName];
                }
                if (query == 'Jl. Melati') {
                  return [kosByAddress];
                }
                return [];
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('kos-search-field')), 'Asri');
      await tester.tap(find.byTooltip('Cari'));
      await tester.pumpAndSettle();
      expect(find.text('Kos Asri'), findsOneWidget);
      expect(find.text('Kos Taman'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('kos-search-field')),
        'Jl. Melati',
      );
      await tester.tap(find.byTooltip('Cari'));
      await tester.pumpAndSettle();
      expect(find.text('Kos Taman'), findsOneWidget);
      expect(find.text('Kos Asri'), findsNothing);
    });

    testWidgets('shows an empty state when a search has no matches', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => [_kos('Kos Asri')],
              null,
              (_, {maxPrice}) async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos-search-field')),
        'Tidak ada',
      );
      await tester.tap(find.byTooltip('Cari'));
      await tester.pumpAndSettle();

      expect(find.text('Data kos tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows a clear error and no old results when search fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => [_kos('Kos Asri')],
              null,
              (_, {maxPrice}) async => throw Exception('network unavailable'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('kos-search-field')), 'Asri');
      await tester.tap(find.byTooltip('Cari'));
      await tester.pumpAndSettle();

      expect(
        find.text('Gagal mencari kos. Periksa koneksi, lalu coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Kos Asri'), findsNothing);
    });

    testWidgets('filters by maximum price including the boundary', (
      tester,
    ) async {
      final affordable = _kos('Kos Hemat', price: 800000);
      final atLimit = _kos('Kos Pas', price: 1000000);
      final overLimit = _kos('Kos Mahal', price: 1500000);
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => [affordable, atLimit, overLimit],
              null,
              (_, {maxPrice}) async => [affordable, atLimit, overLimit]
                  .where(
                    (kos) => maxPrice == null || kos.hargaBulanan <= maxPrice,
                  )
                  .toList(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos-max-price-field')),
        '1000000',
      );
      await tester.tap(find.byTooltip('Terapkan filter harga'));
      await tester.pumpAndSettle();

      expect(find.text('Kos Hemat'), findsOneWidget);
      expect(find.text('Kos Pas'), findsOneWidget);
      expect(find.text('Kos Mahal'), findsNothing);
    });

    testWidgets('shows an empty state when no kos fit the maximum price', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => [_kos('Kos Hemat', price: 800000)],
              null,
              (_, {maxPrice}) async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('kos-max-price-field')),
        '500000',
      );
      await tester.tap(find.byTooltip('Terapkan filter harga'));
      await tester.pumpAndSettle();

      expect(find.text('Data kos tidak ditemukan.'), findsOneWidget);
    });

    testWidgets(
      'shows a clear error and removes old results when filtering fails',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: KosListScreen(
              repository: _FakeKosRepository(
                () async => [_kos('Kos Hemat')],
                null,
                (_, {maxPrice}) async => throw Exception('network unavailable'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('kos-max-price-field')),
          '1000000',
        );
        await tester.tap(find.byTooltip('Terapkan filter harga'));
        await tester.pumpAndSettle();

        expect(
          find.text('Gagal memfilter kos. Periksa koneksi, lalu coba lagi.'),
          findsOneWidget,
        );
        expect(find.text('Kos Hemat'), findsNothing);
      },
    );

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

    testWidgets('opens the selected kos detail screen', (tester) async {
      final selectedKos = _kos('Kos Asri');
      await tester.pumpWidget(
        MaterialApp(
          home: KosListScreen(
            repository: _FakeKosRepository(
              () async => [selectedKos],
              (id) async => id == selectedKos.id ? selectedKos : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kos Asri'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Kos'), findsOneWidget);
      expect(find.text('Jl. Melati'), findsOneWidget);
    });
  });
}

class _FakeKosRepository implements KosRepository {
  _FakeKosRepository(this._loadKos, [this._getKosById, this._searchKos]);

  final Future<List<Kos>> Function() _loadKos;
  final Future<Kos?> Function(String id)? _getKosById;
  final Future<List<Kos>> Function(String query, {double? maxPrice})?
  _searchKos;

  @override
  Future<List<Kos>> getAllKos() => _loadKos();

  @override
  Future<Kos?> getKosById(String id) async =>
      _getKosById == null ? null : _getKosById(id);

  @override
  Future<List<Kos>> searchKos(String query, {double? maxPrice}) =>
      _searchKos == null ? _loadKos() : _searchKos(query, maxPrice: maxPrice);
}

Kos _kos(String name, {String address = 'Jl. Melati', double price = 800000}) =>
    Kos(
      id: name,
      ownerId: 'owner-1',
      nama: name,
      alamat: address,
      hargaBulanan: price,
      deskripsi: 'Dekat kampus',
      createdAt: DateTime.utc(2026, 1, 2),
    );
