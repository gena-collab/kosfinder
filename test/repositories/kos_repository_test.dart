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
    late String authResponseBody;
    late String? lastRequestMethod;
    late Map<String, dynamic>? lastRequestBody;
    late Map<String, dynamic>? storedKosJson;
    late Map<String, dynamic>? otherKosJson;
    late String supabaseUrl;
    Uri? lastRequestUri;

    setUp(() async {
      responseStatus = HttpStatus.ok;
      responseBody = '[]';
      authResponseBody = '{}';
      lastRequestMethod = null;
      lastRequestBody = null;
      storedKosJson = null;
      otherKosJson = null;
      lastRequestUri = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      supabaseUrl = 'http://${server.address.address}:${server.port}';
      server.listen((request) async {
        lastRequestUri = request.uri;
        lastRequestMethod = request.method;
        var statusCode = responseStatus;
        var body = responseBody;
        if (request.uri.path == '/auth/v1/token') {
          statusCode = HttpStatus.ok;
          body = authResponseBody;
        } else if (request.uri.path == '/rest/v1/kos' &&
            request.method == 'POST') {
          lastRequestBody = jsonDecode(
            await utf8.decoder.bind(request).join(),
          ) as Map<String, dynamic>;
          if (responseStatus < HttpStatus.badRequest) {
            storedKosJson = {
              ...lastRequestBody!,
              'id': 'created-kos',
              'created_at': '2026-01-02T03:04:05Z',
            };
            body = jsonEncode(storedKosJson);
          }
        } else if (request.uri.path == '/rest/v1/kos' &&
            request.method == 'PATCH') {
          lastRequestBody = jsonDecode(
            await utf8.decoder.bind(request).join(),
          ) as Map<String, dynamic>;
          if (responseStatus < HttpStatus.badRequest) {
            final requestedId = request.uri.queryParameters['id']!.replaceFirst(
              'eq.',
              '',
            );
            final ownerFilter = request.uri.queryParameters['owner_id']!;
            final requestedOwnerId = ownerFilter.replaceFirst('eq.', '');
            if (storedKosJson?['id'] == requestedId &&
                storedKosJson?['owner_id'] == requestedOwnerId) {
              storedKosJson = {...storedKosJson!, ...lastRequestBody!};
              body = jsonEncode([storedKosJson]);
            } else {
              body = '[]';
            }
          }
        } else if (request.uri.path == '/rest/v1/kos' &&
            request.method == 'DELETE') {
          if (responseStatus < HttpStatus.badRequest) {
            final requestedId = request.uri.queryParameters['id']!.replaceFirst(
              'eq.',
              '',
            );
            final ownerFilter = request.uri.queryParameters['owner_id']!;
            final requestedOwnerId = ownerFilter.replaceFirst('eq.', '');
            Map<String, dynamic>? deletedRow;
            if (storedKosJson?['id'] == requestedId &&
                storedKosJson?['owner_id'] == requestedOwnerId) {
              deletedRow = storedKosJson;
              storedKosJson = null;
            } else if (otherKosJson?['id'] == requestedId &&
                otherKosJson?['owner_id'] == requestedOwnerId) {
              deletedRow = otherKosJson;
              otherKosJson = null;
            }
            body = deletedRow == null
                ? '[]'
                : jsonEncode([
                    {'id': deletedRow['id']},
                  ]);
          }
        } else if (request.uri.path == '/rest/v1/kos' &&
            request.uri.queryParameters.containsKey('id')) {
          final requestedId = request.uri.queryParameters['id']!.replaceFirst(
            'eq.',
            '',
          );
          final storedRows = [?storedKosJson, ?otherKosJson];
          if (storedRows.isNotEmpty) {
            body = jsonEncode(
              storedRows.where((row) => row['id'] == requestedId).toList(),
            );
          }
        } else if (request.uri.path == '/rest/v1/kos' &&
            request.uri.queryParameters.containsKey('owner_id')) {
          final ownerFilter = request.uri.queryParameters['owner_id']!;
          final requestedOwnerId = ownerFilter.replaceFirst('eq.', '');
          body = jsonEncode(
            [
              ?storedKosJson,
              ?otherKosJson,
            ].where((row) => row['owner_id'] == requestedOwnerId).toList(),
          );
        }
        request.response
          ..statusCode = statusCode
          ..headers.contentType = ContentType.json
          ..persistentConnection = false
          ..write(body);
        await request.response.close();
      });

      client = SupabaseClient(supabaseUrl, 'test-anon-key');
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

    test('requires an authenticated owner before loading owned kos', () async {
      await expectLater(
        repository.getOwnedKos(),
        throwsA(isA<AuthSessionMissingException>()),
      );
      expect(lastRequestUri, isNull);
    });

    test('requires an authenticated owner before inserting a kos', () async {
      await expectLater(
        repository.createKos(
          nama: 'Kos Asri',
          alamat: 'Jl. Melati',
          hargaBulanan: 800000,
          deskripsi: 'Dekat kampus',
        ),
        throwsA(isA<AuthSessionMissingException>()),
      );
      expect(lastRequestUri, isNull);
    });

    test(
      'inserts as the current owner and reads the created kos back',
      () async {
        authResponseBody = jsonEncode(_authResponseJson('owner-1'));
        await client.auth.signInWithPassword(
          email: 'owner-1@example.com',
          password: 'secure1',
        );

        final createdKos = await repository.createKos(
          nama: '  Kos Asri  ',
          alamat: '  Jl. Melati  ',
          hargaBulanan: 800000,
          deskripsi: '  Dekat kampus  ',
          fasilitas: '  ',
          fotoUrl: null,
        );

        expect(createdKos.id, 'created-kos');
        expect(createdKos.ownerId, 'owner-1');
        expect(createdKos.nama, 'Kos Asri');
        expect(createdKos.fasilitas, isNull);
        expect(createdKos.fotoUrl, isNull);
        expect(lastRequestMethod, 'POST');
        expect(lastRequestBody, {
          'owner_id': 'owner-1',
          'nama': 'Kos Asri',
          'alamat': 'Jl. Melati',
          'harga_bulanan': 800000,
          'deskripsi': 'Dekat kampus',
          'fasilitas': null,
          'foto_url': null,
        });

        final reopenedClient = SupabaseClient(supabaseUrl, 'test-anon-key');
        try {
          final loadedKos = await KosRepository(reopenedClient)
              .getKosById('created-kos');
          expect(loadedKos?.ownerId, 'owner-1');
          expect(loadedKos?.nama, 'Kos Asri');
        } finally {
          await reopenedClient.dispose();
        }
      },
    );

    test('propagates Supabase errors when inserting a kos fails', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-1'));
      await client.auth.signInWithPassword(
        email: 'owner-1@example.com',
        password: 'secure1',
      );
      responseStatus = HttpStatus.serviceUnavailable;
      responseBody = jsonEncode({
        'code': 'PGRST000',
        'message': 'Service unavailable',
        'details': '',
        'hint': '',
      });

      await expectLater(
        repository.createKos(
          nama: 'Kos Asri',
          alamat: 'Jl. Melati',
          hargaBulanan: 800000,
          deskripsi: 'Dekat kampus',
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(lastRequestMethod, 'POST');
    });

    test('requires an authenticated owner before updating a kos', () async {
      await expectLater(
        repository.updateKos(
          id: 'kos-1',
          nama: 'Kos Baru',
          alamat: 'Jl. Baru',
          hargaBulanan: 900000,
          deskripsi: 'Dekat kampus',
        ),
        throwsA(isA<AuthSessionMissingException>()),
      );
      expect(lastRequestUri, isNull);
    });

    test('updates only the current owners kos', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-1'));
      await client.auth.signInWithPassword(
        email: 'owner-1@example.com',
        password: 'secure1',
      );
      storedKosJson = _kosJson(ownerId: 'owner-1');

      final updatedKos = await repository.updateKos(
        id: 'kos-1',
        nama: '  Kos Baru  ',
        alamat: '  Jl. Baru  ',
        hargaBulanan: 900000,
        deskripsi: '  Lebih dekat kampus  ',
        fasilitas: '  Wi-Fi  ',
        fotoUrl: null,
      );

      expect(updatedKos.nama, 'Kos Baru');
      expect(updatedKos.alamat, 'Jl. Baru');
      expect(updatedKos.hargaBulanan, 900000);
      expect(updatedKos.ownerId, 'owner-1');
      expect(lastRequestMethod, 'PATCH');
      expect(lastRequestUri?.queryParameters['id'], 'eq.kos-1');
      expect(lastRequestUri?.queryParameters['owner_id'], 'eq.owner-1');
      expect(lastRequestBody, {
        'owner_id': 'owner-1',
        'nama': 'Kos Baru',
        'alamat': 'Jl. Baru',
        'harga_bulanan': 900000,
        'deskripsi': 'Lebih dekat kampus',
        'fasilitas': 'Wi-Fi',
        'foto_url': null,
      });
    });

    test('leaves another owners kos unchanged', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-2'));
      await client.auth.signInWithPassword(
        email: 'owner-2@example.com',
        password: 'secure1',
      );
      storedKosJson = _kosJson(ownerId: 'owner-1');

      await expectLater(
        repository.updateKos(
          id: 'kos-1',
          nama: 'Kos Diubah',
          alamat: 'Jl. Diubah',
          hargaBulanan: 1000000,
          deskripsi: 'Tidak boleh berubah',
        ),
        throwsA(isA<KosOwnershipException>()),
      );

      expect(storedKosJson?['nama'], 'Kos Asri');
      expect(lastRequestUri?.queryParameters['owner_id'], 'eq.owner-2');
    });

    test('propagates a server row-level security rejection', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-2'));
      await client.auth.signInWithPassword(
        email: 'owner-2@example.com',
        password: 'secure1',
      );
      storedKosJson = _kosJson(ownerId: 'owner-1');
      responseStatus = HttpStatus.forbidden;
      responseBody = jsonEncode({
        'code': '42501',
        'message': 'new row violates row-level security policy',
        'details': '',
        'hint': '',
      });

      await expectLater(
        repository.updateKos(
          id: 'kos-1',
          nama: 'Kos Diubah',
          alamat: 'Jl. Diubah',
          hargaBulanan: 1000000,
          deskripsi: 'Tidak boleh berubah',
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(storedKosJson?['nama'], 'Kos Asri');
    });

    test('requires an authenticated owner before deleting a kos', () async {
      await expectLater(
        repository.deleteKos('kos-1'),
        throwsA(isA<AuthSessionMissingException>()),
      );
      expect(lastRequestUri, isNull);
    });

    test('deletes only the current owners kos', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-1'));
      await client.auth.signInWithPassword(
        email: 'owner-1@example.com',
        password: 'secure1',
      );
      storedKosJson = _kosJson(ownerId: 'owner-1');
      otherKosJson = _kosJson(ownerId: 'owner-2')..['id'] = 'kos-2';

      await repository.deleteKos('kos-1');

      expect(lastRequestMethod, 'DELETE');
      expect(lastRequestUri?.queryParameters['id'], 'eq.kos-1');
      expect(lastRequestUri?.queryParameters['owner_id'], 'eq.owner-1');
      expect(storedKosJson, isNull);
      expect(otherKosJson?['owner_id'], 'owner-2');

      authResponseBody = jsonEncode(_authResponseJson('owner-2'));
      await client.auth.signInWithPassword(
        email: 'owner-2@example.com',
        password: 'secure1',
      );
      final remainingKos = await repository.getOwnedKos();
      expect(remainingKos, hasLength(1));
      expect(remainingKos.single.id, 'kos-2');
      expect(remainingKos.single.ownerId, 'owner-2');
    });

    test('does not delete another owners kos', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-2'));
      await client.auth.signInWithPassword(
        email: 'owner-2@example.com',
        password: 'secure1',
      );
      storedKosJson = _kosJson(ownerId: 'owner-1');

      await expectLater(
        repository.deleteKos('kos-1'),
        throwsA(isA<KosOwnershipException>()),
      );

      expect(storedKosJson?['owner_id'], 'owner-1');
      expect(storedKosJson?['nama'], 'Kos Asri');
      expect(lastRequestUri?.queryParameters['owner_id'], 'eq.owner-2');
    });

    test(
      'propagates server row-level security rejection during deletion',
      () async {
        authResponseBody = jsonEncode(_authResponseJson('owner-2'));
        await client.auth.signInWithPassword(
          email: 'owner-2@example.com',
          password: 'secure1',
        );
        storedKosJson = _kosJson(ownerId: 'owner-1');
        responseStatus = HttpStatus.forbidden;
        responseBody = jsonEncode({
          'code': '42501',
          'message': 'row-level security policy violation',
          'details': '',
          'hint': '',
        });

        await expectLater(
          repository.deleteKos('kos-1'),
          throwsA(isA<PostgrestException>()),
        );
        expect(storedKosJson?['owner_id'], 'owner-1');
      },
    );

    test('filters owned kos to the current session for each owner', () async {
      authResponseBody = jsonEncode(_authResponseJson('owner-1'));
      await client.auth.signInWithPassword(
        email: 'owner-1@example.com',
        password: 'secure1',
      );
      storedKosJson = _kosJson(ownerId: 'owner-1');
      otherKosJson = _kosJson(ownerId: 'owner-2')..['id'] = 'kos-2';

      final firstOwnersKos = await repository.getOwnedKos();

      expect(firstOwnersKos, hasLength(1));
      expect(firstOwnersKos.single.ownerId, 'owner-1');
      expect(lastRequestUri?.queryParameters['owner_id'], 'eq.owner-1');

      authResponseBody = jsonEncode(_authResponseJson('owner-2'));
      await client.auth.signInWithPassword(
        email: 'owner-2@example.com',
        password: 'secure1',
      );

      final secondOwnersKos = await repository.getOwnedKos();

      expect(secondOwnersKos, hasLength(1));
      expect(secondOwnersKos.single.ownerId, 'owner-2');
      expect(lastRequestUri?.queryParameters['owner_id'], 'eq.owner-2');
    });

    test(
      'searches both name and address with a case-insensitive substring',
      () async {
        responseBody = jsonEncode([_kosJson()]);

        final kosList = await repository.searchKos('Melati');

        expect(kosList, hasLength(1));
        expect(kosList.single.nama, 'Kos Asri');
        final filter = lastRequestUri?.queryParameters['or'];
        expect(filter, contains('nama.ilike."%Melati%"'));
        expect(filter, contains('alamat.ilike."%Melati%"'));
      },
    );

    test(
      'applies an inclusive maximum price filter without a minimum',
      () async {
        responseBody = jsonEncode([
          _kosJson(price: 800000),
          _kosJson(price: 1000000),
        ]);

        final kosList = await repository.searchKos('', maxPrice: 1000000);

        expect(kosList.map((kos) => kos.hargaBulanan), [800000, 1000000]);
        expect(
          lastRequestUri?.queryParameters['harga_bulanan'],
          'lte.1000000.0',
        );
        expect(
          lastRequestUri?.queryParameters.containsKey('harga_min'),
          isFalse,
        );
      },
    );

    test('combines name and address search with the maximum price', () async {
      responseBody = jsonEncode([_kosJson(price: 800000)]);

      await repository.searchKos('Melati', maxPrice: 1000000);

      expect(lastRequestUri?.queryParameters['harga_bulanan'], 'lte.1000000.0');
      final filter = lastRequestUri?.queryParameters['or'];
      expect(filter, contains('nama.ilike."%Melati%"'));
      expect(filter, contains('alamat.ilike."%Melati%"'));
    });

    test('loads the full list for a blank search query', () async {
      responseBody = jsonEncode([_kosJson()]);

      final kosList = await repository.searchKos('  ');

      expect(kosList, hasLength(1));
      expect(lastRequestUri?.queryParameters.containsKey('or'), isFalse);
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

Map<String, dynamic> _authResponseJson(String userId) => {
  'access_token': 'test-token-$userId',
  'refresh_token': 'test-refresh-token-$userId',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': userId,
    'email': '$userId@example.com',
    'created_at': '2026-01-02T03:04:05Z',
  },
};

Map<String, dynamic> _kosJson({
  String ownerId = 'owner-1',
  num price = 800000,
}) => {
  'id': 'kos-1',
  'owner_id': ownerId,
  'nama': 'Kos Asri',
  'alamat': 'Jl. Melati',
  'harga_bulanan': price,
  'deskripsi': 'Dekat kampus',
  'fasilitas': 'Wi-Fi',
  'foto_url': 'https://example.invalid/kos.jpg',
  'created_at': '2026-01-02T03:04:05Z',
};
