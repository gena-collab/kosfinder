import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';

void main() {
  group('KosDetailScreen', () {
    testWidgets('shows required and available optional details', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosDetailScreen(
            repository: _FakeKosRepository(
              () async => _kos(
                fasilitas: 'Wi-Fi',
                fotoUrl: 'https://example.com/kos.jpg',
              ),
            ),
            kosId: 'kos-1',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Kos Asri'), findsOneWidget);
      expect(find.text('Jl. Melati'), findsOneWidget);
      expect(find.text('Rp 800000'), findsOneWidget);
      expect(find.text('Dekat kampus'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
      'keeps required details visible when optional values are empty',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: KosDetailScreen(
              repository: _FakeKosRepository(() async => _kos()),
              kosId: 'kos-1',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Kos Asri'), findsOneWidget);
        expect(find.text('Jl. Melati'), findsOneWidget);
        expect(find.text('Rp 800000'), findsOneWidget);
        expect(find.text('Dekat kampus'), findsOneWidget);
        expect(find.text('Belum tersedia.'), findsOneWidget);
        expect(find.text('Foto belum tersedia.'), findsOneWidget);
      },
    );

    testWidgets('shows a clear error without displaying stale detail', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosDetailScreen(
            repository: _FakeKosRepository(
              () async => throw Exception('network unavailable'),
            ),
            kosId: 'kos-1',
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Gagal memuat detail kos. Periksa koneksi, lalu coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Kos Asri'), findsNothing);
    });
  });
}

class _FakeKosRepository implements KosRepository {
  _FakeKosRepository(this._loadKos);

  final Future<Kos?> Function() _loadKos;

  @override
  Future<List<Kos>> getAllKos() async => [];

  @override
  Future<Kos?> getKosById(String id) => _loadKos();
}

Kos _kos({String? fasilitas, String? fotoUrl}) => Kos(
  id: 'kos-1',
  ownerId: 'owner-1',
  nama: 'Kos Asri',
  alamat: 'Jl. Melati',
  hargaBulanan: 800000,
  deskripsi: 'Dekat kampus',
  fasilitas: fasilitas,
  fotoUrl: fotoUrl,
  createdAt: DateTime.utc(2026, 1, 2),
);
