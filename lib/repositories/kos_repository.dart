import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos.dart';

class KosRepository {
  const KosRepository(this._client);

  final SupabaseClient _client;

  Future<List<Kos>> getAllKos() async {
    final rows = await _client.from('kos').select();
    return rows.map(Kos.fromJson).toList(growable: false);
  }

  Future<List<Kos>> getOwnedKos() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthSessionMissingException();
    }

    final rows = await _client.from('kos').select().eq('owner_id', user.id);
    return rows.map(Kos.fromJson).toList(growable: false);
  }

  Future<Kos> createKos({
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthSessionMissingException();
    }

    final row = await _client
        .from('kos')
        .insert({
          'owner_id': user.id,
          'nama': nama.trim(),
          'alamat': alamat.trim(),
          'harga_bulanan': hargaBulanan,
          'deskripsi': deskripsi.trim(),
          'fasilitas': _optionalText(fasilitas),
          'foto_url': _optionalText(fotoUrl),
        })
        .select()
        .single();
    return Kos.fromJson(row);
  }

  Future<Kos> updateKos({
    required String id,
    required String nama,
    required String alamat,
    required double hargaBulanan,
    required String deskripsi,
    String? fasilitas,
    String? fotoUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthSessionMissingException();
    }

    final rows = await _client
        .from('kos')
        .update({
          'owner_id': user.id,
          'nama': nama.trim(),
          'alamat': alamat.trim(),
          'harga_bulanan': hargaBulanan,
          'deskripsi': deskripsi.trim(),
          'fasilitas': _optionalText(fasilitas),
          'foto_url': _optionalText(fotoUrl),
        })
        .eq('id', id)
        .eq('owner_id', user.id)
        .select();
    if (rows.isEmpty) {
      throw const KosOwnershipException();
    }
    return Kos.fromJson(rows.single);
  }

  Future<void> deleteKos(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthSessionMissingException();
    }

    final rows = await _client
        .from('kos')
        .delete()
        .eq('id', id)
        .eq('owner_id', user.id)
        .select('id');
    if (rows.isEmpty) {
      throw const KosOwnershipException();
    }
  }

  Future<List<Kos>> searchKos(String query, {double? maxPrice}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty && maxPrice == null) {
      return getAllKos();
    }

    var request = _client.from('kos').select();
    if (trimmedQuery.isNotEmpty) {
      final escapedQuery = _escapeSearchQuery(trimmedQuery);
      final pattern = '"%$escapedQuery%"';
      request = request.or('nama.ilike.$pattern,alamat.ilike.$pattern');
    }
    if (maxPrice != null) {
      request = request.lte('harga_bulanan', maxPrice);
    }

    final rows = await request;
    return rows.map(Kos.fromJson).toList(growable: false);
  }

  Future<Kos?> getKosById(String id) async {
    final row = await _client.from('kos').select().eq('id', id).maybeSingle();
    return row == null ? null : Kos.fromJson(row);
  }

  String _escapeSearchQuery(String query) {
    return query
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class KosOwnershipException implements Exception {
  const KosOwnershipException();
}
