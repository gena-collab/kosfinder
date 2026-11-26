import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(
    this._repository, {
    bool initiallyAuthenticated = false,
    Stream<bool>? sessionChanges,
  }) : _isAuthenticated = initiallyAuthenticated {
    _sessionSubscription = sessionChanges?.listen((isAuthenticated) {
      if (_isAuthenticated != isAuthenticated) {
        _isAuthenticated = isAuthenticated;
        notifyListeners();
      }
    });
  }

  final AuthRepository _repository;
  StreamSubscription<bool>? _sessionSubscription;

  bool _isLoading = false;
  bool _isAuthenticated;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    final validationError = _validate(email, password);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.login(email: email.trim(), password: password);
      _isAuthenticated = true;
      _successMessage = 'Login berhasil.';
      return true;
    } on AuthRetryableFetchException {
      _errorMessage =
          'Koneksi gagal saat login. Periksa koneksi, lalu coba lagi.';
      return false;
    } on AuthException catch (error) {
      _errorMessage = _loginErrorMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    final validationError = _validate(email, password);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.register(
        email: email.trim(),
        password: password,
      );
      if (result.hasAuthenticatedSession) {
        _isAuthenticated = true;
      }
      _successMessage = result.hasAuthenticatedSession
          ? 'Registrasi berhasil. Anda sudah masuk.'
          : 'Registrasi berhasil. Periksa email untuk verifikasi, lalu lanjutkan ke login.';
      return true;
    } on AuthRetryableFetchException {
      _errorMessage =
          'Koneksi gagal saat registrasi. Periksa koneksi, lalu coba lagi.';
      return false;
    } on AuthException catch (error) {
      _errorMessage = _authErrorMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _validate(String email, String password) {
    final trimmedEmail = email.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmedEmail)) {
      return 'Masukkan alamat email yang valid.';
    }
    if (password.length < 6) {
      return 'Password harus terdiri dari minimal 6 karakter.';
    }
    return null;
  }

  String _authErrorMessage(AuthException error) {
    if (error.code == 'email_exists' ||
        error.code == 'user_already_exists') {
      return 'Email sudah terdaftar. Gunakan email lain atau lanjutkan ke login.';
    }
    if (error.code == 'weak_password') {
      return 'Password tidak memenuhi persyaratan. Gunakan minimal 6 karakter.';
    }
    if (error is AuthUnknownException) {
      return 'Registrasi gagal karena respons layanan tidak dapat diproses. Coba lagi.';
    }
    return error.message.isEmpty
        ? 'Registrasi gagal. Periksa data dan coba lagi.'
        : error.message;
  }

  String _loginErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (error.code == 'invalid_credentials' ||
        error.code == 'user_not_found' ||
        message.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (error is AuthUnknownException) {
      return 'Login gagal karena respons layanan tidak dapat diproses. Coba lagi.';
    }
    return error.message.isEmpty
        ? 'Login gagal. Periksa email dan password, lalu coba lagi.'
        : error.message;
  }

  @override
  void dispose() {
    final subscription = _sessionSubscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
