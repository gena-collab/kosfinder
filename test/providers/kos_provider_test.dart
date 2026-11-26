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

  group('OwnerKosProvider', () {
    test('publishes loading and then the owners kos list', () async {
      final completer = Completer<List<Kos>>();
      final provider = OwnerKosProvider(
        _FakeKosRepository(() async => [], null, null, () => completer.future),
      );

      final load = provider.loadOwnerKos();
      expect(provider.isLoading, isTrue);
      expect(provider.kosList, isEmpty);

      completer.complete([_kos()]);
      await load;

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList.single.nama, 'Kos Asri');
      provider.dispose();
    });

    test(
      'clears previous kos and reports an error when loading fails',
      () async {
        var shouldFail = false;
        final provider = OwnerKosProvider(
          _FakeKosRepository(() async => [], null, null, () async {
            if (shouldFail) {
              throw Exception('network unavailable');
            }
            return [_kos()];
          }),
        );

        await provider.loadOwnerKos();
        shouldFail = true;
        await provider.loadOwnerKos();

        expect(provider.kosList, isEmpty);
        expect(
          provider.errorMessage,
          'Gagal memuat kos milik Anda. Periksa koneksi, lalu coba lagi.',
        );
        provider.dispose();
      },
    );

    test('removes a kos only after the repository confirms deletion', () async {
      final ownerKos = _kos(name: 'owner-kos');
      final otherKos = _kos(name: 'other-kos');
      String? deletedId;
      final provider = OwnerKosProvider(
        _FakeKosRepository(
          () async => [],
          null,
          null,
          () async => [ownerKos, otherKos],
          null,
          null,
          (id) async {
            deletedId = id;
          },
        ),
      );
      await provider.loadOwnerKos();

      final deleted = await provider.deleteKos(ownerKos.id);

      expect(deleted, isTrue);
      expect(deletedId, ownerKos.id);
      expect(provider.kosList, [otherKos]);
      expect(provider.deleteErrorMessage, isNull);
      expect(provider.deletingKosId, isNull);
      provider.dispose();
    });

    test('keeps the kos and reports an error when deletion fails', () async {
      final ownerKos = _kos(name: 'owner-kos');
      final provider = OwnerKosProvider(
        _FakeKosRepository(
          () async => [],
          null,
          null,
          () async => [ownerKos],
          null,
          null,
          (_) async => throw Exception('network unavailable'),
        ),
      );
      await provider.loadOwnerKos();

      final deleted = await provider.deleteKos(ownerKos.id);

      expect(deleted, isFalse);
      expect(provider.kosList, [ownerKos]);
      expect(
        provider.deleteErrorMessage,
        'Gagal menghapus kos. Periksa koneksi, lalu coba lagi.',
      );
      expect(provider.deletingKosId, isNull);
      provider.dispose();
    });
  });

  group('KosFormProvider', () {
    test('publishes saving state and submits the entered kos data', () async {
      final completer = Completer<Kos>();
      Map<String, Object?>? submittedValues;
      final provider = KosFormProvider(
        _FakeKosRepository(() async => [], null, null, null, ({
          required String nama,
          required String alamat,
          required double hargaBulanan,
          required String deskripsi,
          String? fasilitas,
          String? fotoUrl,
        }) {
          submittedValues = {
            'nama': nama,
            'alamat': alamat,
            'hargaBulanan': hargaBulanan,
            'deskripsi': deskripsi,
            'fasilitas': fasilitas,
            'fotoUrl': fotoUrl,
          };
          return completer.future;
        }),
      );

      final save = provider.saveKos(
        nama: 'Kos Asri',
        alamat: 'Jl. Melati',
        hargaBulanan: 800000,
        deskripsi: 'Dekat kampus',
        fasilitas: 'Wi-Fi',
        fotoUrl: 'https://example.invalid/kos.jpg',
      );

      expect(provider.isSaving, isTrue);
      completer.complete(_kos());
      expect(await save, isTrue);
      expect(provider.isSaving, isFalse);
      expect(provider.errorMessage, isNull);
      expect(submittedValues, {
        'nama': 'Kos Asri',
        'alamat': 'Jl. Melati',
        'hargaBulanan': 800000,
        'deskripsi': 'Dekat kampus',
        'fasilitas': 'Wi-Fi',
        'fotoUrl': 'https://example.invalid/kos.jpg',
      });
      provider.dispose();
    });

    test('reports a save failure and clears the saving state', () async {
      final provider = KosFormProvider(
        _FakeKosRepository(
          () async => [],
          null,
          null,
          null,
          ({
            required String nama,
            required String alamat,
            required double hargaBulanan,
            required String deskripsi,
            String? fasilitas,
            String? fotoUrl,
          }) async => throw Exception('network unavailable'),
        ),
      );

      final saved = await provider.saveKos(
        nama: 'Kos Asri',
        alamat: 'Jl. Melati',
        hargaBulanan: 800000,
        deskripsi: 'Dekat kampus',
      );

      expect(saved, isFalse);
      expect(provider.isSaving, isFalse);
      expect(
        provider.errorMessage,
        'Gagal menyimpan kos. Periksa koneksi, lalu coba lagi.',
      );
      provider.dispose();
    });

    test('updates the selected kos and reports saving state', () async {
      final completer = Completer<Kos>();
      String? updatedId;
      String? updatedName;
      final provider = KosFormProvider(
        _FakeKosRepository(() async => [], null, null, null, null, ({
          required String id,
          required String nama,
          required String alamat,
          required double hargaBulanan,
          required String deskripsi,
          String? fasilitas,
          String? fotoUrl,
        }) {
          updatedId = id;
          updatedName = nama;
          return completer.future;
        }),
      );

      final update = provider.updateKos(
        id: 'kos-1',
        nama: 'Kos Baru',
        alamat: 'Jl. Baru',
        hargaBulanan: 900000,
        deskripsi: 'Dekat kampus',
      );

      expect(provider.isSaving, isTrue);
      completer.complete(_kos(name: 'Kos Baru'));
      expect(await update, isTrue);
      expect(provider.isSaving, isFalse);
      expect(provider.errorMessage, isNull);
      expect(updatedId, 'kos-1');
      expect(updatedName, 'Kos Baru');
      provider.dispose();
    });

    test(
      'reports when an update targets a kos the owner cannot access',
      () async {
        final provider = KosFormProvider(
          _FakeKosRepository(
            () async => [],
            null,
            null,
            null,
            null,
            ({
              required String id,
              required String nama,
              required String alamat,
              required double hargaBulanan,
              required String deskripsi,
              String? fasilitas,
              String? fotoUrl,
            }) async => throw const KosOwnershipException(),
          ),
        );

        final updated = await provider.updateKos(
          id: 'other-owner-kos',
          nama: 'Kos Diubah',
          alamat: 'Jl. Baru',
          hargaBulanan: 900000,
          deskripsi: 'Tidak boleh berubah',
        );

        expect(updated, isFalse);
        expect(
          provider.errorMessage,
          'Kos tidak ditemukan atau Anda tidak memiliki akses.',
        );
        provider.dispose();
      },
    );
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
  _FakeKosRepository(
    this._loadKos, [
    this._getKosById,
    this._searchKos,
    this._getOwnedKos,
    this._createKos,
    this._updateKos,
    this._deleteKos,
  ]);

  final Future<List<Kos>> Function() _loadKos;
  final Future<Kos?> Function(String id)? _getKosById;
  final Future<List<Kos>> Function(String query, {double? maxPrice})?
  _searchKos;
  final Future<List<Kos>> Function()? _getOwnedKos;
  final Future<Kos> Function({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  })?
  _createKos;
  final Future<Kos> Function({
    required String id,
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  })?
  _updateKos;
  final Future<void> Function(String id)? _deleteKos;

  @override
  Future<List<Kos>> getAllKos() => _loadKos();

  @override
  Future<List<Kos>> getOwnedKos() =>
      _getOwnedKos == null ? _loadKos() : _getOwnedKos();

  @override
  Future<Kos> createKos({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) {
    final createKos = _createKos;
    if (createKos == null) {
      throw UnimplementedError();
    }
    return createKos(
      nama: nama,
      alamat: alamat,
      hargaBulanan: hargaBulanan,
      deskripsi: deskripsi,
      fasilitas: fasilitas,
      fotoUrl: fotoUrl,
    );
  }

  @override
  Future<Kos> updateKos({
    required String id,
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) {
    final updateKos = _updateKos;
    if (updateKos == null) {
      throw UnimplementedError();
    }
    return updateKos(
      id: id,
      nama: nama,
      alamat: alamat,
      hargaBulanan: hargaBulanan,
      deskripsi: deskripsi,
      fasilitas: fasilitas,
      fotoUrl: fotoUrl,
    );
  }

  @override
  Future<void> deleteKos(String id) {
    final deleteKos = _deleteKos;
    if (deleteKos == null) {
      throw UnimplementedError();
    }
    return deleteKos(id);
  }

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
