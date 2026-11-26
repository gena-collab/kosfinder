import 'package:flutter/foundation.dart';

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
