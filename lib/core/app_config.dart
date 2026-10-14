class AppConfig {
  const AppConfig._();

  static const String _rawBaseUrl = String.fromEnvironment('CGM_API_BASE_URL');
  static const String _rawWsUrl = String.fromEnvironment('CGM_WS_URL');

  /// Backend REST base URL, read from `.env` (CGM_API_BASE_URL).
  static String get apiBaseUrl => _require('CGM_API_BASE_URL', _rawBaseUrl);

  /// Realtime gateway URL, read from `.env` (CGM_WS_URL).
  /// Falls back to the API base URL since both are served by the same backend.
  static String get wsUrl =>
      _rawWsUrl.trim().isNotEmpty ? _rawWsUrl.trim() : apiBaseUrl;

  static String _require(String key, String value) {
    final v = value.trim();
    if (v.isEmpty) {
      throw StateError(
        '$key is not set. Run the app with: '
        'flutter run --dart-define-from-file=.env',
      );
    }
    return v;
  }

  static const String defaultLanguage = String.fromEnvironment(
    'APP_DEFAULT_LANGUAGE',
    defaultValue: 'English',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}
