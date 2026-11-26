import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';

void main() {
  group('KosFormScreen', () {
    testWidgets('requires name, address, and description', (tester) async {
      await _openForm(tester, _FakeKosRepository(_successfulCreate));

      await tester.tap(find.byKey(const Key('kos-form-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Kolom ini wajib diisi.'), findsNWidgets(3));
    });

    testWidgets('rejects a price that is zero or invalid', (tester) async {
      await _openForm(tester, _FakeKosRepository(_successfulCreate));
      await _enterRequiredFields(tester, price: '0');

      await tester.ensureVisible(
        find.byKey(const Key('kos-form-submit-button')),
      );
      await tester.tap(find.byKey(const Key('kos-form-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Harga harus lebih dari 0.'), findsOneWidget);
    });

    testWidgets('saves valid fields with optional values omitted', (
      tester,
    ) async {
      Map<String, Object?>? submittedValues;
      final repository = _FakeKosRepository(({
        required String nama,
        required String alamat,
        required double hargaBulanan,
        required String deskripsi,
        String? fasilitas,
        String? fotoUrl,
      }) async {
        submittedValues = {
          'nama': nama,
          'alamat': alamat,
          'hargaBulanan': hargaBulanan,
          'deskripsi': deskripsi,
          'fasilitas': fasilitas,
          'fotoUrl': fotoUrl,
        };
        return _kos();
      });
      await _openForm(tester, repository);
      await _enterRequiredFields(tester);

      await tester.ensureVisible(
        find.byKey(const Key('kos-form-submit-button')),
      );
      await tester.tap(find.byKey(const Key('kos-form-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Open form'), findsOneWidget);
      expect(submittedValues, {
        'nama': 'Kos Asri',
        'alamat': 'Jl. Melati',
        'hargaBulanan': 800000,
        'deskripsi': 'Dekat kampus',
        'fasilitas': null,
        'fotoUrl': null,
      });
    });

    testWidgets('keeps the form open and shows a save error', (tester) async {
      await _openForm(
        tester,
        _FakeKosRepository(
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
      await _enterRequiredFields(tester);

      await tester.ensureVisible(
        find.byKey(const Key('kos-form-submit-button')),
      );
      await tester.tap(find.byKey(const Key('kos-form-submit-button')));
      await tester.pumpAndSettle();

      expect(find.byType(KosFormScreen), findsOneWidget);
      expect(
        find.text('Gagal menyimpan kos. Periksa koneksi, lalu coba lagi.'),
        findsOneWidget,
      );
    });

    testWidgets('prefills an existing kos and saves valid changes', (
      tester,
    ) async {
      Map<String, Object?>? submittedValues;
      final repository = _FakeKosRepository(
        _successfulCreate,
        updateCallback:
            ({
              required String id,
              required String nama,
              required String alamat,
              required double hargaBulanan,
              required String deskripsi,
              String? fasilitas,
              String? fotoUrl,
            }) async {
              submittedValues = {
                'id': id,
                'nama': nama,
                'alamat': alamat,
                'hargaBulanan': hargaBulanan,
                'deskripsi': deskripsi,
                'fasilitas': fasilitas,
                'fotoUrl': fotoUrl,
              };
              return Kos(
                id: id,
                ownerId: 'owner-1',
                nama: nama,
                alamat: alamat,
                hargaBulanan: hargaBulanan,
                deskripsi: deskripsi,
                fasilitas: fasilitas,
                fotoUrl: fotoUrl,
                createdAt: DateTime.utc(2026, 1, 2),
              );
            },
      );
      await _openForm(tester, repository, kos: _existingKos());

      expect(find.text('Edit Kos'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('kos-form-name-field')))
            .controller
            ?.text,
        'Kos Asri',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('kos-form-facilities-field')),
            )
            .controller
            ?.text,
        'Wi-Fi',
      );
      await tester.enterText(
        find.byKey(const Key('kos-form-name-field')),
        'Kos Asri Baru',
      );
      await tester.enterText(
        find.byKey(const Key('kos-form-price-field')),
        '950000',
      );
      await tester.ensureVisible(
        find.byKey(const Key('kos-form-submit-button')),
      );
      await tester.tap(find.byKey(const Key('kos-form-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Open form'), findsOneWidget);
      expect(submittedValues, {
        'id': 'kos-1',
        'nama': 'Kos Asri Baru',
        'alamat': 'Jl. Melati',
        'hargaBulanan': 950000,
        'deskripsi': 'Dekat kampus',
        'fasilitas': 'Wi-Fi',
        'fotoUrl': 'https://example.invalid/kos.jpg',
      });
    });

    testWidgets('rejects invalid changes before calling the repository', (
      tester,
    ) async {
      var updateCalled = false;
      final repository = _FakeKosRepository(
        _successfulCreate,
        updateCallback:
            ({
              required String id,
              required String nama,
              required String alamat,
              required double hargaBulanan,
              required String deskripsi,
              String? fasilitas,
              String? fotoUrl,
            }) async {
              updateCalled = true;
              return _kos();
            },
      );
      await _openForm(tester, repository, kos: _existingKos());
      await tester.enterText(
        find.byKey(const Key('kos-form-address-field')),
        ' ',
      );
      await tester.enterText(
        find.byKey(const Key('kos-form-price-field')),
        '0',
      );
      await tester.ensureVisible(
        find.byKey(const Key('kos-form-submit-button')),
      );
      await tester.tap(find.byKey(const Key('kos-form-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Kolom ini wajib diisi.'), findsOneWidget);
      expect(find.text('Harga harus lebih dari 0.'), findsOneWidget);
      expect(updateCalled, isFalse);
    });
  });
}

Future<void> _openForm(
  WidgetTester tester,
  KosRepository repository, {
  Kos? kos,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        KosFormScreen(repository: repository, kos: kos),
                  ),
                );
              },
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
}

Future<void> _enterRequiredFields(
  WidgetTester tester, {
  String price = '800000',
}) async {
  await tester.enterText(
    find.byKey(const Key('kos-form-name-field')),
    'Kos Asri',
  );
  await tester.enterText(
    find.byKey(const Key('kos-form-address-field')),
    'Jl. Melati',
  );
  await tester.enterText(find.byKey(const Key('kos-form-price-field')), price);
  await tester.enterText(
    find.byKey(const Key('kos-form-description-field')),
    'Dekat kampus',
  );
}

class _FakeKosRepository implements KosRepository {
  _FakeKosRepository(this._createKos, {this.updateCallback});

  final Future<Kos> Function({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  })
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
  updateCallback;

  @override
  Future<Kos> createKos({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) => _createKos(
    nama: nama,
    alamat: alamat,
    hargaBulanan: hargaBulanan,
    deskripsi: deskripsi,
    fasilitas: fasilitas,
    fotoUrl: fotoUrl,
  );

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
    final updateKos = updateCallback;
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
  Future<void> deleteKos(String id) async => throw UnimplementedError();

  @override
  Future<List<Kos>> getAllKos() async => [];

  @override
  Future<List<Kos>> getOwnedKos() async => [];

  @override
  Future<Kos?> getKosById(String id) async => null;

  @override
  Future<List<Kos>> searchKos(String query, {double? maxPrice}) async => [];
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

Kos _existingKos() => Kos(
  id: 'kos-1',
  ownerId: 'owner-1',
  nama: 'Kos Asri',
  alamat: 'Jl. Melati',
  hargaBulanan: 800000,
  deskripsi: 'Dekat kampus',
  fasilitas: 'Wi-Fi',
  fotoUrl: 'https://example.invalid/kos.jpg',
  createdAt: DateTime.utc(2026, 1, 2),
);

Future<Kos> _successfulCreate({
  required String nama,
  required String alamat,
  required double hargaBulanan,
  required String deskripsi,
  String? fasilitas,
  String? fotoUrl,
}) async => _kos();
