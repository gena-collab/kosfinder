import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Kos.fromJson', () {
    test('maps required fields, numeric price, and optional values', () {
      final kos = Kos.fromJson(_kosJson());

      expect(kos.id, 'kos-1');
      expect(kos.ownerId, 'owner-1');
      expect(kos.nama, 'Kos Asri');
      expect(kos.alamat, 'Jl. Melati');
      expect(kos.hargaBulanan, 800000);
      expect(kos.deskripsi, 'Dekat kampus');
      expect(kos.fasilitas, 'Wi-Fi');
      expect(kos.fotoUrl, 'https://example.invalid/kos.jpg');
      expect(kos.createdAt, DateTime.parse('2026-01-02T03:04:05Z'));
    });

    test('accepts null optional fields', () {
      final kos = Kos.fromJson(
        _kosJson()
          ..['fasilitas'] = null
          ..['foto_url'] = null,
      );

      expect(kos.fasilitas, isNull);
      expect(kos.fotoUrl, isNull);
    });

    test('rejects missing or incorrectly typed required data', () {
      final invalidKos = _kosJson()..['harga_bulanan'] = '800000';

      expect(() => Kos.fromJson(invalidKos), throwsFormatException);
    });
  });

  group('KosRepository', () {
    late HttpServer server;
    late SupabaseClient client;
    late KosRepository repository;
    late int responseStatus;
    late String responseBody;
    Uri? lastRequestUri;

    setUp(() async {
      responseStatus = HttpStatus.ok;
      responseBody = '[]';
      lastRequestUri = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        lastRequestUri = request.uri;
        request.response
          ..statusCode = responseStatus
          ..headers.contentType = ContentType.json
          ..persistentConnection = false
          ..write(responseBody);
        await request.response.close();
      });

      client = SupabaseClient(
        'http://${server.address.address}:${server.port}',
        'test-anon-key',
      );
      repository = KosRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });

    test('reads and maps the kos list from Supabase', () async {
      responseBody = jsonEncode([_kosJson()]);

      final kosList = await repository.getAllKos();

      expect(kosList, hasLength(1));
      expect(kosList.single.nama, 'Kos Asri');
      expect(lastRequestUri?.path, '/rest/v1/kos');
    });

    test('returns an empty list when no rows are found', () async {
      final kosList = await repository.getAllKos();

      expect(kosList, isEmpty);
    });

    test('reads one kos by id and returns null when it is not found', () async {
      responseBody = jsonEncode([_kosJson()]);

      final kos = await repository.getKosById('kos-1');

      expect(kos?.id, 'kos-1');
      expect(lastRequestUri?.queryParameters['id'], 'eq.kos-1');

      responseBody = '[]';
      final missingKos = await repository.getKosById('missing');

      expect(missingKos, isNull);
    });

    test(
      'propagates Supabase errors instead of returning stale data',
      () async {
        responseBody = jsonEncode([_kosJson()]);
        final previousResult = await repository.getAllKos();
        expect(previousResult, hasLength(1));

        responseStatus = HttpStatus.serviceUnavailable;
        responseBody = jsonEncode({
          'code': 'PGRST000',
          'message': 'Service unavailable',
          'details': '',
          'hint': '',
        });

        await expectLater(
          repository.getAllKos(),
          throwsA(isA<PostgrestException>()),
        );
      },
    );
  });
}

Map<String, dynamic> _kosJson() => {
  'id': 'kos-1',
  'owner_id': 'owner-1',
  'nama': 'Kos Asri',
  'alamat': 'Jl. Melati',
  'harga_bulanan': 800000,
  'deskripsi': 'Dekat kampus',
  'fasilitas': 'Wi-Fi',
  'foto_url': 'https://example.invalid/kos.jpg',
  'created_at': '2026-01-02T03:04:05Z',
};
