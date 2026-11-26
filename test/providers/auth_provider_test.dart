import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthProvider', () {
    test(
      'registers a valid email and reports the confirmation next step',
      () async {
        String? registeredEmail;
        final provider = AuthProvider(
          _FakeAuthRepository((email, password) async {
            registeredEmail = email;
            return const AuthRegistrationResult(hasAuthenticatedSession: false);
          }),
        );

        final succeeded = await provider.register(
          email: '  owner@example.com  ',
          password: 'secure1',
        );

        expect(succeeded, isTrue);
        expect(registeredEmail, 'owner@example.com');
        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, contains('lanjutkan ke login'));
        expect(provider.isLoading, isFalse);
        provider.dispose();
      },
    );

    test(
      'rejects invalid email and short password before repository call',
      () async {
        var repositoryCalled = false;
        final provider = AuthProvider(
          _FakeAuthRepository((email, password) async {
            repositoryCalled = true;
            return const AuthRegistrationResult(hasAuthenticatedSession: true);
          }),
        );

        final invalidEmail = await provider.register(
          email: 'not-an-email',
          password: 'secure1',
        );
        expect(invalidEmail, isFalse);
        expect(provider.errorMessage, 'Masukkan alamat email yang valid.');
        expect(repositoryCalled, isFalse);

        final shortPassword = await provider.register(
          email: 'owner@example.com',
          password: '12345',
        );
        expect(shortPassword, isFalse);
        expect(
          provider.errorMessage,
          'Password harus terdiri dari minimal 6 karakter.',
        );
        expect(repositoryCalled, isFalse);
        expect(provider.successMessage, isNull);
        provider.dispose();
      },
    );

    test('reports an already registered email without success state', () async {
      final provider = AuthProvider(
        _FakeAuthRepository(
          (email, password) async => throw const AuthException(
            'User already registered',
            code: 'email_exists',
          ),
        ),
      );

      final succeeded = await provider.register(
        email: 'owner@example.com',
        password: 'secure1',
      );

      expect(succeeded, isFalse);
      expect(provider.errorMessage, contains('Email sudah terdaftar'));
      expect(provider.successMessage, isNull);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('reports a connection failure without success state', () async {
      final provider = AuthProvider(
        _FakeAuthRepository(
          (email, password) async =>
              throw AuthRetryableFetchException(message: 'connection refused'),
        ),
      );

      final succeeded = await provider.register(
        email: 'owner@example.com',
        password: 'secure1',
      );

      expect(succeeded, isFalse);
      expect(provider.errorMessage, contains('Koneksi gagal'));
      expect(provider.successMessage, isNull);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test(
      'reports success when Supabase creates an authenticated session',
      () async {
        final provider = AuthProvider(
          _FakeAuthRepository(
            (email, password) async =>
                const AuthRegistrationResult(hasAuthenticatedSession: true),
          ),
        );

        final succeeded = await provider.register(
          email: 'owner@example.com',
          password: 'secure1',
        );

        expect(succeeded, isTrue);
        expect(provider.isAuthenticated, isTrue);
        expect(provider.successMessage, contains('Anda sudah masuk'));
        expect(provider.errorMessage, isNull);
        provider.dispose();
      },
    );

    test('opens an authenticated session after successful login', () async {
      String? loggedInEmail;
      final provider = AuthProvider(
        _FakeAuthRepository(
          (email, password) async =>
              const AuthRegistrationResult(hasAuthenticatedSession: false),
          loginHandler: (email, password) async {
            loggedInEmail = email;
          },
        ),
      );

      final succeeded = await provider.login(
        email: '  owner@example.com  ',
        password: 'secure1',
      );

      expect(succeeded, isTrue);
      expect(loggedInEmail, 'owner@example.com');
      expect(provider.isAuthenticated, isTrue);
      expect(provider.successMessage, 'Login berhasil.');
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('rejects invalid credentials without opening a session', () async {
      final provider = AuthProvider(
        _FakeAuthRepository(
          (email, password) async =>
              const AuthRegistrationResult(hasAuthenticatedSession: false),
          loginHandler: (email, password) async => throw const AuthException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
      );

      final succeeded = await provider.login(
        email: 'owner@example.com',
        password: 'secure1',
      );

      expect(succeeded, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, 'Email atau password salah.');
      expect(provider.successMessage, isNull);
      provider.dispose();
    });

    test(
      'reports a login connection failure without opening a session',
      () async {
        final provider = AuthProvider(
          _FakeAuthRepository(
            (email, password) async =>
                const AuthRegistrationResult(hasAuthenticatedSession: false),
            loginHandler: (email, password) async =>
                throw AuthRetryableFetchException(
                  message: 'connection refused',
                ),
          ),
        );

        final succeeded = await provider.login(
          email: 'owner@example.com',
          password: 'secure1',
        );

        expect(succeeded, isFalse);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.errorMessage, contains('Koneksi gagal'));
        expect(provider.successMessage, isNull);
        provider.dispose();
      },
    );

    test('initializes and tracks authentication session changes', () async {
      final sessionChanges = StreamController<bool>();
      final provider = AuthProvider(
        _FakeAuthRepository(
          (email, password) async =>
              const AuthRegistrationResult(hasAuthenticatedSession: false),
        ),
        initiallyAuthenticated: true,
        sessionChanges: sessionChanges.stream,
      );

      expect(provider.isAuthenticated, isTrue);

      sessionChanges.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(provider.isAuthenticated, isFalse);

      sessionChanges.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(provider.isAuthenticated, isTrue);

      provider.dispose();
      await sessionChanges.close();
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._register, {this.loginHandler});

  final Future<AuthRegistrationResult> Function(String email, String password)
  _register;
  final Future<void> Function(String email, String password)? loginHandler;

  @override
  Future<void> login({
    required String email,
    required String password,
  }) {
    final handler = loginHandler;
    if (handler == null) {
      throw UnimplementedError(
        'Login handler was not configured for this test.',
      );
    }
    return handler(email, password);
  }

  @override
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) => _register(email, password);
}
