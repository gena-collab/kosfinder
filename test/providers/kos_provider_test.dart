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

Kos _kos() => Kos(
  id: 'kos-1',
  ownerId: 'owner-1',
  nama: 'Kos Asri',
  alamat: 'Jl. Melati',
  hargaBulanan: 800000,
  deskripsi: 'Dekat kampus',
  createdAt: DateTime.utc(2026, 1, 2),
);
