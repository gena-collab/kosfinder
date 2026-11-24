import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/config/supabase_config.dart';

void main() {
  group('SupabaseConfig.fromEnvironment', () {
    test('rejects a missing project URL without exposing values', () {
      expect(
        () => SupabaseConfig.fromEnvironment(
          urlOverride: '',
          anonKeyOverride: 'test-anon-key',
        ),
        throwsA(
          isA<SupabaseConfigException>().having(
            (error) => error.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });

    test('rejects a missing anon key', () {
      expect(
        () => SupabaseConfig.fromEnvironment(
          urlOverride: 'https://example.invalid',
          anonKeyOverride: '',
        ),
        throwsA(
          isA<SupabaseConfigException>().having(
            (error) => error.message,
            'message',
            contains('SUPABASE_ANON_KEY'),
          ),
        ),
      );
    });

    test('rejects a URL without an HTTP or HTTPS scheme', () {
      expect(
        () => SupabaseConfig.fromEnvironment(
          urlOverride: 'example.invalid',
          anonKeyOverride: 'test-anon-key',
        ),
        throwsA(isA<SupabaseConfigException>()),
      );
    });

    test('accepts and trims complete configuration', () {
      final config = SupabaseConfig.fromEnvironment(
        urlOverride: ' https://example.invalid ',
        anonKeyOverride: ' test-anon-key ',
      );

      expect(config.url, 'https://example.invalid');
      expect(config.anonKey, 'test-anon-key');
    });
  });
}
