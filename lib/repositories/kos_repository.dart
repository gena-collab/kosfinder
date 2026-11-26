import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos.dart';

class KosRepository {
  const KosRepository(this._client);

  final SupabaseClient _client;

  Future<List<Kos>> getAllKos() async {
    final rows = await _client.from('kos').select();
    return rows.map(Kos.fromJson).toList(growable: false);
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
}
