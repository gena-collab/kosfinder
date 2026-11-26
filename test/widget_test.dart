// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/main.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:kosfinder/screens/owner_kos_screen.dart';

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
      ChangeNotifierProvider(
        create: (_) => AuthProvider(_FakeAuthRepository()),
        child: MaterialApp(
          home: KosFinderHome(repository: _EmptyKosRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Kos'), findsWidgets);
    expect(find.text('Data kos tidak ditemukan.'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('2415051038 - Gena Anggarani'), findsOneWidget);
  });

  testWidgets('anonymous users can browse but management asks them to log in', (
    tester,
  ) async {
    final kos = _testKos();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(_FakeAuthRepository()),
        child: MaterialApp(
          home: KosFinderHome(repository: _SingleKosRepository(kos)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kos Asri'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('kos-search-field')), 'Melati');
    await tester.tap(find.byTooltip('Cari'));
    await tester.pumpAndSettle();
    expect(find.text('Kos Asri'), findsOneWidget);

    await tester.tap(find.text('Kos Asri'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Kos'), findsOneWidget);
    expect(find.text('Jl. Melati'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kelola'));
    await tester.pumpAndSettle();

    expect(find.text('Login Pemilik'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Kos Asri'), findsOneWidget);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('2415051038 - Gena Anggarani'), findsOneWidget);
  });

  testWidgets(
    'successful login opens management while public pages remain open',
    (tester) async {
      final kos = _testKos();
      final authProvider = AuthProvider(_FakeAuthRepository());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: KosFinderHome(repository: _SingleKosRepository(kos)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kelola'));
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

      expect(authProvider.isAuthenticated, isTrue);
      await tester.tap(find.byKey(const Key('login-continue-button')));
      await tester.pumpAndSettle();

      expect(find.byType(OwnerKosScreen), findsOneWidget);
      expect(find.byKey(Key('owner-kos-${kos.id}')), findsOneWidget);
      await tester.tap(find.text('Daftar Kos').last);
      await tester.pumpAndSettle();
      expect(find.text(kos.nama), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('kos-search-field')),
        'Melati',
      );
      await tester.tap(find.byTooltip('Cari'));
      await tester.pumpAndSettle();
      expect(find.text(kos.nama), findsOneWidget);

      await tester.tap(find.text(kos.nama));
      await tester.pumpAndSettle();
      expect(find.text('Detail Kos'), findsOneWidget);
      expect(find.text(kos.alamat), findsOneWidget);
    },
  );

  testWidgets('an authenticated session opens OwnerKosScreen directly', (
    tester,
  ) async {
    final kos = _testKos();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            AuthProvider(_FakeAuthRepository(), initiallyAuthenticated: true),
        child: MaterialApp(
          home: KosFinderHome(repository: _SingleKosRepository(kos)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kelola'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(OwnerKosScreen), findsOneWidget);
    expect(find.byKey(Key('owner-kos-${kos.id}')), findsOneWidget);
  });
}

class _EmptyKosRepository implements KosRepository {
  @override
  Future<List<Kos>> getAllKos() async => [];

  @override
  Future<List<Kos>> getOwnedKos() async => [];

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
  Future<void> deleteKos(String id) async => throw UnimplementedError();

  @override
  Future<Kos?> getKosById(String id) async => null;

  @override
  Future<List<Kos>> searchKos(String query, {double? maxPrice}) async => [];
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) async => const AuthRegistrationResult(hasAuthenticatedSession: false);
}

class _SingleKosRepository implements KosRepository {
  const _SingleKosRepository(this.kos);

  final Kos kos;

  @override
  Future<List<Kos>> getAllKos() async => [kos];

  @override
  Future<List<Kos>> getOwnedKos() async => [kos];

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
  Future<void> deleteKos(String id) async => throw UnimplementedError();

  @override
  Future<Kos?> getKosById(String id) async => id == kos.id ? kos : null;

  @override
  Future<List<Kos>> searchKos(String query, {double? maxPrice}) async {
    final normalizedQuery = query.toLowerCase();
    if (kos.nama.toLowerCase().contains(normalizedQuery) ||
        kos.alamat.toLowerCase().contains(normalizedQuery)) {
      return [kos];
    }
    return [];
  }
}

Kos _testKos() => Kos(
  id: 'kos-1',
  ownerId: 'owner-1',
  nama: 'Kos Asri',
  alamat: 'Jl. Melati',
  hargaBulanan: 800000,
  deskripsi: 'Dekat kampus',
  createdAt: DateTime.utc(2026, 1, 2),
);
