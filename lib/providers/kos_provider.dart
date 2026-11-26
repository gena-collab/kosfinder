import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos.dart';
import '../repositories/kos_repository.dart';

class KosProvider extends ChangeNotifier {
  KosProvider(this._repository);

  final KosRepository _repository;

  List<Kos> _kosList = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  double? _maxPrice;

  List<Kos> get kosList => _kosList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get maxPrice => _maxPrice;

  Future<void> loadKos() {
    _searchQuery = '';
    _maxPrice = null;
    return _loadResults(_repository.getAllKos, _loadErrorMessage);
  }

  Future<void> searchKos(String query) {
    _searchQuery = query.trim();
    return _applyFilters(_searchErrorMessage);
  }

  Future<void> filterKosByMaxPrice(double? maxPrice) {
    _maxPrice = maxPrice;
    return _applyFilters(_priceFilterErrorMessage);
  }

  Future<void> _applyFilters(String failureMessage) {
    if (_searchQuery.isEmpty && _maxPrice == null) {
      return _loadResults(_repository.getAllKos, _loadErrorMessage);
    }
    return _loadResults(
      () => _repository.searchKos(_searchQuery, maxPrice: _maxPrice),
      failureMessage,
    );
  }

  Future<void> _loadResults(
    Future<List<Kos>> Function() load,
    String failureMessage,
  ) async {
    _isLoading = true;
    _kosList = const [];
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = List.unmodifiable(await load());
    } on Exception {
      _kosList = const [];
      _errorMessage = failureMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static const _loadErrorMessage =
      'Gagal memuat data kos. Periksa koneksi, lalu coba lagi.';
  static const _searchErrorMessage =
      'Gagal mencari kos. Periksa koneksi, lalu coba lagi.';
  static const _priceFilterErrorMessage =
      'Gagal memfilter kos. Periksa koneksi, lalu coba lagi.';
}

class OwnerKosProvider extends ChangeNotifier {
  OwnerKosProvider(this._repository);

  final KosRepository _repository;

  List<Kos> _kosList = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _deletingKosId;
  String? _deleteErrorMessage;

  List<Kos> get kosList => _kosList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get deletingKosId => _deletingKosId;
  String? get deleteErrorMessage => _deleteErrorMessage;

  Future<void> loadOwnerKos() async {
    _isLoading = true;
    _kosList = const [];
    _errorMessage = null;
    _deleteErrorMessage = null;
    notifyListeners();

    try {
      _kosList = List.unmodifiable(await _repository.getOwnedKos());
    } on Exception {
      _kosList = const [];
      _errorMessage =
          'Gagal memuat kos milik Anda. Periksa koneksi, lalu coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteKos(String id) async {
    _deletingKosId = id;
    _deleteErrorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteKos(id);
      _kosList = List.unmodifiable(_kosList.where((kos) => kos.id != id));
      return true;
    } on AuthSessionMissingException {
      _deleteErrorMessage = 'Login diperlukan untuk menghapus kos.';
      return false;
    } on KosOwnershipException {
      _deleteErrorMessage =
          'Kos tidak ditemukan atau Anda tidak memiliki akses.';
      return false;
    } on Exception {
      _deleteErrorMessage =
          'Gagal menghapus kos. Periksa koneksi, lalu coba lagi.';
      return false;
    } finally {
      _deletingKosId = null;
      notifyListeners();
    }
  }
}

class KosFormProvider extends ChangeNotifier {
  KosFormProvider(this._repository);

  final KosRepository _repository;

  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<bool> saveKos({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) {
    return _save(
      () => _repository.createKos(
        nama: nama,
        alamat: alamat,
        hargaBulanan: hargaBulanan,
        deskripsi: deskripsi,
        fasilitas: fasilitas,
        fotoUrl: fotoUrl,
      ),
      failureMessage: 'Gagal menyimpan kos. Periksa koneksi, lalu coba lagi.',
    );
  }

  Future<bool> updateKos({
    required String id,
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) {
    return _save(
      () => _repository.updateKos(
        id: id,
        nama: nama,
        alamat: alamat,
        hargaBulanan: hargaBulanan,
        deskripsi: deskripsi,
        fasilitas: fasilitas,
        fotoUrl: fotoUrl,
      ),
      failureMessage:
          'Gagal menyimpan perubahan kos. Periksa koneksi, lalu coba lagi.',
    );
  }

  Future<bool> _save(
    Future<Kos> Function() save, {
    required String failureMessage,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await save();
      return true;
    } on AuthSessionMissingException {
      _errorMessage = 'Login diperlukan untuk mengelola kos.';
      return false;
    } on KosOwnershipException {
      _errorMessage = 'Kos tidak ditemukan atau Anda tidak memiliki akses.';
      return false;
    } on Exception {
      _errorMessage = failureMessage;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

class KosDetailProvider extends ChangeNotifier {
  KosDetailProvider(this._repository);

  final KosRepository _repository;

  Kos? _kos;
  bool _isLoading = false;
  String? _errorMessage;

  Kos? get kos => _kos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadKosDetail(String id) async {
    _isLoading = true;
    _kos = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final kos = await _repository.getKosById(id);
      if (kos == null) {
        _errorMessage = 'Data kos tidak ditemukan.';
      } else {
        _kos = kos;
      }
    } on Exception {
      _errorMessage =
          'Gagal memuat detail kos. Periksa koneksi, lalu coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
