import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';

void main() {
  group('initializeSupabase', () {
    test(
      'returns a clear error and skips initialization when URL is missing',
      () async {
        var initializerCalled = false;

        final result = await initializeSupabase(
          url: '',
          anonKey: 'test-anon-key',
          initializer: (url, anonKey) async {
            initializerCalled = true;
          },
        );

        expect(result.isReady, isFalse);
        expect(result.errorMessage, contains('SUPABASE_URL'));
        expect(initializerCalled, isFalse);
      },
    );

    test('reports success after the initializer completes', () async {
      String? initializedUrl;
      String? initializedAnonKey;

      final result = await initializeSupabase(
        url: 'https://example.invalid',
        anonKey: 'test-anon-key',
        initializer: (url, anonKey) async {
          initializedUrl = url;
          initializedAnonKey = anonKey;
        },
      );

      expect(result.isReady, isTrue);
      expect(initializedUrl, 'https://example.invalid');
      expect(initializedAnonKey, 'test-anon-key');
    });

    test('returns a sanitized error when initialization fails', () async {
      final result = await initializeSupabase(
        url: 'https://example.invalid',
        anonKey: 'test-anon-key',
        initializer: (url, anonKey) async {
          throw Exception('test failure detail');
        },
      );

      expect(result.isReady, isFalse);
      expect(result.errorMessage, contains('Supabase gagal diinisialisasi'));
      expect(result.errorMessage, isNot(contains('test failure detail')));
    });
  });
}
