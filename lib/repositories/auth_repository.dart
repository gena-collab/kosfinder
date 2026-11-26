import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRegistrationResult {
  const AuthRegistrationResult({required this.hasAuthenticatedSession});

  final bool hasAuthenticatedSession;
}

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null || response.session == null) {
      throw const AuthException(
        'Login tidak menghasilkan sesi terautentikasi.',
        code: 'session_missing',
      );
    }

  }

  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Supabase tidak mengembalikan akun setelah registrasi.',
        code: 'signup_failed',
      );
    }

    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthException(
        'Email sudah terdaftar.',
        code: 'user_already_exists',
      );
    }

    return AuthRegistrationResult(
      hasAuthenticatedSession: response.session != null,
    );
  }
}
