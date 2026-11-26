import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/screens/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('RegisterScreen', () {
    testWidgets(
      'shows a validation error and does not register invalid input',
      (tester) async {
        var repositoryCalled = false;
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              _FakeAuthRepository((email, password) async {
                repositoryCalled = true;
                return const AuthRegistrationResult(
                  hasAuthenticatedSession: true,
                );
              }),
            ),
            child: const MaterialApp(home: RegisterScreen()),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('register-email-field')),
          'invalid-email',
        );
        await tester.enterText(
          find.byKey(const Key('register-password-field')),
          'secure1',
        );
        await tester.tap(find.byKey(const Key('register-submit-button')));
        await tester.pumpAndSettle();

        expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
        expect(repositoryCalled, isFalse);
      },
    );

    testWidgets('shows success only after repository registration succeeds', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            _FakeAuthRepository(
              (email, password) async =>
                  const AuthRegistrationResult(hasAuthenticatedSession: false),
            ),
          ),
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('register-email-field')),
        'owner@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password-field')),
        'secure1',
      );
      await tester.tap(find.byKey(const Key('register-submit-button')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Registrasi berhasil. Periksa email untuk verifikasi, lalu lanjutkan ke login.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('register-error-message')), findsNothing);
    });

    testWidgets('shows a connection error and never shows success', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            _FakeAuthRepository(
              (email, password) async => throw AuthRetryableFetchException(
                message: 'connection refused',
              ),
            ),
          ),
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('register-email-field')),
        'owner@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password-field')),
        'secure1',
      );
      await tester.tap(find.byKey(const Key('register-submit-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Koneksi gagal'), findsOneWidget);
      expect(find.byKey(const Key('register-success-message')), findsNothing);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._register);

  final Future<AuthRegistrationResult> Function(String email, String password)
  _register;

  @override
  Future<void> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) => _register(email, password);
}
