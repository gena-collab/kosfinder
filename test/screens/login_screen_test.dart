import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('submits credentials and displays success after login', (
      tester,
    ) async {
      String? loggedInEmail;
      String? loggedInPassword;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            _FakeAuthRepository((email, password) async {
              loggedInEmail = email;
              loggedInPassword = password;
            }),
          ),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

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

      expect(loggedInEmail, 'owner@example.com');
      expect(loggedInPassword, 'secure1');
      expect(find.text('Login berhasil.'), findsOneWidget);
      expect(find.byKey(const Key('login-error-message')), findsNothing);
    });

    testWidgets('obscures the password and shows wrong-credential errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            _FakeAuthRepository(
              (email, password) async => throw const AuthException(
                'Invalid login credentials',
                statusCode: '400',
                code: 'invalid_credentials',
              ),
            ),
          ),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      final passwordField = tester.widget<TextField>(
        find.byKey(const Key('login-password-field')),
      );
      expect(passwordField.obscureText, isTrue);

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

      expect(find.text('Email atau password salah.'), findsOneWidget);
      expect(find.byKey(const Key('login-success-message')), findsNothing);
    });

    testWidgets('shows connection failures without claiming login success', (
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
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

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

      expect(find.textContaining('Koneksi gagal'), findsOneWidget);
      expect(find.byKey(const Key('login-success-message')), findsNothing);
    });

    testWidgets('opens registration from the login screen', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_FakeAuthRepository((email, password) async {})),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.byKey(const Key('login-register-link')));
      await tester.pumpAndSettle();

      expect(find.text('Registrasi Pemilik'), findsOneWidget);
      expect(find.byKey(const Key('register-login-link')), findsOneWidget);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._login);

  final Future<void> Function(String email, String password) _login;

  @override
  Future<void> login({required String email, required String password}) =>
      _login(email, password);

  @override
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
}
