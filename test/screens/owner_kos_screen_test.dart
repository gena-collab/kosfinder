import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:kosfinder/screens/owner_kos_screen.dart';

void main() {
  group('OwnerKosScreen', () {
    testWidgets('redirects an anonymous user to login', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(_FakeAuthRepository()),
          child: MaterialApp(
            home: OwnerKosScreen(repository: _FakeKosRepository([])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login Pemilik'), findsOneWidget);
    });

    testWidgets('shows only kos returned for the authenticated owner', (
      tester,
    ) async {
      final ownerKos = _kos('owner-1-kos', 'Kos Pemilik');
      final otherOwnersKos = _kos('owner-2-kos', 'Kos Pemilik Lain');
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_FakeAuthRepository(), initiallyAuthenticated: true),
          child: MaterialApp(
            home: OwnerKosScreen(repository: _FakeKosRepository([ownerKos])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kos Pemilik'), findsOneWidget);
      expect(find.text('Rp 800000'), findsOneWidget);
      expect(find.text(otherOwnersKos.nama), findsNothing);
    });

    testWidgets('loads the owner list after login from the required gate', (
      tester,
    ) async {
      final ownerKos = _kos('owner-1-kos', 'Kos Pemilik');
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(_FakeAuthRepository()),
          child: MaterialApp(
            home: OwnerKosScreen(repository: _FakeKosRepository([ownerKos])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login-email-field')),
        'owner@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password-field')),
        'secure1',
      );
      await tester.tap(find.byKey(const Key('login-submit-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login-continue-button')));
      await tester.pumpAndSettle();

      expect(find.text('Kos Pemilik'), findsOneWidget);
    });

    testWidgets('requires confirmation and removes a kos after deletion', (
      tester,
    ) async {
      final ownerKos = _kos('owner-1-kos', 'Kos Pemilik');
      String? deletedId;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_FakeAuthRepository(), initiallyAuthenticated: true),
          child: MaterialApp(
            home: OwnerKosScreen(
              repository: _FakeKosRepository(
                [ownerKos],
                onDelete: (id) async {
                  deletedId = id;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete-kos-owner-1-kos')));
      await tester.pumpAndSettle();
      expect(find.text('Hapus "Kos Pemilik" secara permanen?'), findsOneWidget);
      expect(deletedId, isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(deletedId, 'owner-1-kos');
      expect(find.text('Kos Pemilik'), findsNothing);
      expect(find.text('Anda belum memiliki kos.'), findsOneWidget);
      expect(find.text('Kos berhasil dihapus.'), findsOneWidget);
    });

    testWidgets('keeps the kos and shows an error when deletion fails', (
      tester,
    ) async {
      final ownerKos = _kos('owner-1-kos', 'Kos Pemilik');
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_FakeAuthRepository(), initiallyAuthenticated: true),
          child: MaterialApp(
            home: OwnerKosScreen(
              repository: _FakeKosRepository(
                [ownerKos],
                onDelete: (_) async {
                  throw Exception('network unavailable');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete-kos-owner-1-kos')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Kos Pemilik'), findsOneWidget);
      expect(
        find.text('Gagal menghapus kos. Periksa koneksi, lalu coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Kos berhasil dihapus.'), findsNothing);
    });

    testWidgets('cancelling the confirmation does not delete the kos', (
      tester,
    ) async {
      var deleteCalled = false;
      final ownerKos = _kos('owner-1-kos', 'Kos Pemilik');
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_FakeAuthRepository(), initiallyAuthenticated: true),
          child: MaterialApp(
            home: OwnerKosScreen(
              repository: _FakeKosRepository(
                [ownerKos],
                onDelete: (_) async {
                  deleteCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete-kos-owner-1-kos')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isFalse);
      expect(find.text('Kos Pemilik'), findsOneWidget);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
}

class _FakeKosRepository implements KosRepository {
  _FakeKosRepository(this._kosList, {this.onDelete});

  final List<Kos> _kosList;
  final Future<void> Function(String id)? onDelete;

  @override
  Future<List<Kos>> getAllKos() async => [];

  @override
  Future<List<Kos>> getOwnedKos() async => _kosList;

  @override
  Future<Kos> createKos({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) => throw UnimplementedError();

  @override
  Future<Kos> updateKos({
    required String id,
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteKos(String id) =>
      onDelete == null ? Future<void>.value() : onDelete!(id);

  @override
  Future<Kos?> getKosById(String id) async => null;

  @override
  Future<List<Kos>> searchKos(String query, {double? maxPrice}) async => [];
}

Kos _kos(String id, String name) => Kos(
  id: id,
  ownerId: id == 'owner-1-kos' ? 'owner-1' : 'owner-2',
  nama: name,
  alamat: 'Jl. Melati',
  hargaBulanan: 800000,
  deskripsi: 'Dekat kampus',
  createdAt: DateTime.utc(2026, 1, 2),
);
