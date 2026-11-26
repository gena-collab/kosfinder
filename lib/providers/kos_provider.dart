import 'package:flutter/foundation.dart';

import '../models/kos.dart';
import '../repositories/kos_repository.dart';

class KosProvider extends ChangeNotifier {
  KosProvider(this._repository);

  final KosRepository _repository;

  List<Kos> _kosList = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Kos> get kosList => _kosList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadKos() async {
    _isLoading = true;
    _kosList = const [];
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = List.unmodifiable(await _repository.getAllKos());
    } on Exception {
      _kosList = const [];
      _errorMessage = 'Gagal memuat data kos. Periksa koneksi, lalu coba lagi.';
    } finally {
      _isLoading = false;
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
