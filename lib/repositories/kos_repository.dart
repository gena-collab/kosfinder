import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos.dart';

class KosRepository {
  const KosRepository(this._client);

  final SupabaseClient _client;

  Future<List<Kos>> getAllKos() async {
    final rows = await _client.from('kos').select();
    return rows.map(Kos.fromJson).toList(growable: false);
  }

  Future<Kos?> getKosById(String id) async {
    final row = await _client.from('kos').select().eq('id', id).maybeSingle();
    return row == null ? null : Kos.fromJson(row);
  }
}
