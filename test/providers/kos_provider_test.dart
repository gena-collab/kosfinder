import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

void main() {
  group('KosProvider', () {
    test('publishes loading and then the loaded kos list', () async {
      final completer = Completer<List<Kos>>();
      final provider = KosProvider(_FakeKosRepository(() => completer.future));

      final load = provider.loadKos();
      expect(provider.isLoading, isTrue);
      expect(provider.kosList, isEmpty);

      completer.complete([_kos()]);
      await load;

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList.single.nama, 'Kos Asri');
      provider.dispose();
    });

    test('keeps an empty result as an empty state without an error', () async {
      final provider = KosProvider(_FakeKosRepository(() async => []));

      await provider.loadKos();

      expect(provider.isLoading, isFalse);
      expect(provider.kosList, isEmpty);
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test(
      'clears previous data and exposes an error after a failed reload',
      () async {
        var shouldFail = false;
        final provider = KosProvider(
          _FakeKosRepository(() async {
            if (shouldFail) {
              throw Exception('network unavailable');
            }
            return [_kos()];
          }),
        );

        await provider.loadKos();
        shouldFail = true;
        await provider.loadKos();

        expect(provider.isLoading, isFalse);
        expect(provider.kosList, isEmpty);
        expect(
          provider.errorMessage,
          'Gagal memuat data kos. Periksa koneksi, lalu coba lagi.',
        );
        provider.dispose();
      },
    );

    test('searches using the trimmed query and publishes matches', () async {
      String? searchedQuery;
      final provider = KosProvider(
        _FakeKosRepository(() async => [], null, (query, {maxPrice}) async {
          searchedQuery = query;
          return [_kos()];
        }),
      );

      await provider.searchKos('  Asri  ');

      expect(searchedQuery, 'Asri');
      expect(provider.kosList.single.nama, 'Kos Asri');
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('keeps a no-match search as a clear empty result', () async {
      final provider = KosProvider(
        _FakeKosRepository(() async => [], null, (_, {maxPrice}) async => []),
      );

      await provider.searchKos('Tidak ada');

      expect(provider.kosList, isEmpty);
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('clears old results and reports a search connection error', () async {
      var shouldFail = false;
      final provider = KosProvider(
        _FakeKosRepository(() async => [_kos()], null, (_, {maxPrice}) async {
          if (shouldFail) {
            throw Exception('network unavailable');
          }
          return [_kos()];
        }),
      );

      await provider.loadKos();
      shouldFail = true;
      await provider.searchKos('Asri');

      expect(provider.kosList, isEmpty);
      expect(
        provider.errorMessage,
        'Gagal mencari kos. Periksa koneksi, lalu coba lagi.',
      );
      provider.dispose();
    });

    test('applies an inclusive maximum price filter', () async {
      final affordable = _kos(name: 'kos-low', price: 800000);
      final atLimit = _kos(name: 'kos-limit', price: 1000000);
      final overLimit = _kos(name: 'kos-high', price: 1500000);
      double? requestedMaximum;
      final provider = KosProvider(
        _FakeKosRepository(() async => [affordable, atLimit, overLimit], null, (
          query, {
          maxPrice,
        }) async {
          requestedMaximum = maxPrice;
          return [affordable, atLimit, overLimit]
              .where((kos) => maxPrice == null || kos.hargaBulanan <= maxPrice)
              .toList();
        }),
      );

      await provider.filterKosByMaxPrice(1000000);

      expect(requestedMaximum, 1000000);
      expect(provider.kosList.map((kos) => kos.hargaBulanan), [
        800000,
        1000000,
      ]);
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('shows an empty result when no kos fit the maximum price', () async {
      final provider = KosProvider(
        _FakeKosRepository(
          () async => [_kos(name: 'kos-low', price: 800000)],
          null,
          (_, {maxPrice}) async => [],
        ),
      );

      await provider.filterKosByMaxPrice(500000);

      expect(provider.kosList, isEmpty);
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('clears previous results when filtering fails', () async {
      var shouldFail = false;
      final provider = KosProvider(
        _FakeKosRepository(() async => [_kos()], null, (_, {maxPrice}) async {
          if (shouldFail) {
            throw Exception('network unavailable');
          }
          return [_kos()];
        }),
      );

      await provider.loadKos();
      shouldFail = true;
      await provider.filterKosByMaxPrice(1000000);

      expect(provider.kosList, isEmpty);
      expect(
        provider.errorMessage,
        'Gagal memfilter kos. Periksa koneksi, lalu coba lagi.',
      );
      provider.dispose();
    });
  });

  group('KosDetailProvider', () {
    test('loads the requested kos and publishes its loading state', () async {
      final completer = Completer<Kos?>();
      final provider = KosDetailProvider(
        _FakeKosRepository(() async => [], (id) {
          expect(id, 'kos-1');
          return completer.future;
        }),
      );

      final load = provider.loadKosDetail('kos-1');
      expect(provider.isLoading, isTrue);
      expect(provider.kos, isNull);

      completer.complete(_kos());
      await load;

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kos?.nama, 'Kos Asri');
      provider.dispose();
    });

    test('reports a clear message when the kos does not exist', () async {
      final provider = KosDetailProvider(_FakeKosRepository(() async => []));

      await provider.loadKosDetail('missing');

      expect(provider.kos, isNull);
      expect(provider.errorMessage, 'Data kos tidak ditemukan.');
      provider.dispose();
    });

    test('clears old detail and reports a load error', () async {
      var shouldFail = false;
      final provider = KosDetailProvider(
        _FakeKosRepository(() async => [], (_) async {
          if (shouldFail) {
            throw Exception('network unavailable');
          }
          return _kos();
        }),
      );

      await provider.loadKosDetail('kos-1');
      shouldFail = true;
      await provider.loadKosDetail('another-kos');

      expect(provider.kos, isNull);
      expect(
        provider.errorMessage,
        'Gagal memuat detail kos. Periksa koneksi, lalu coba lagi.',
      );
      provider.dispose();
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

Kos _kos({String name = 'Kos Asri', double price = 800000}) => Kos(
  id: name,
  ownerId: 'owner-1',
  nama: name,
  alamat: 'Jl. Melati',
  hargaBulanan: price,
  deskripsi: 'Dekat kampus',
  createdAt: DateTime.utc(2026, 1, 2),
);
