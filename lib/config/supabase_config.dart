class SupabaseConfig {
  const SupabaseConfig._({required this.url, required this.anonKey});

  static const _environmentUrl = String.fromEnvironment('SUPABASE_URL');
  static const _environmentAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  final String url;
  final String anonKey;

  factory SupabaseConfig.fromEnvironment({
    String? urlOverride,
    String? anonKeyOverride,
  }) {
    final url = (urlOverride ?? _environmentUrl).trim();
    final anonKey = (anonKeyOverride ?? _environmentAnonKey).trim();

    if (url.isEmpty) {
      throw const SupabaseConfigException(
        'SUPABASE_URL belum diatur. Jalankan aplikasi dengan '
        '--dart-define=SUPABASE_URL=...',
      );
    }

    if (anonKey.isEmpty) {
      throw const SupabaseConfigException(
        'SUPABASE_ANON_KEY belum diatur. Jalankan aplikasi dengan '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const SupabaseConfigException(
        'SUPABASE_URL harus berupa URL HTTP atau HTTPS yang valid.',
      );
    }

    return SupabaseConfig._(url: url, anonKey: anonKey);
  }
}

class SupabaseConfigException implements Exception {
  const SupabaseConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}
