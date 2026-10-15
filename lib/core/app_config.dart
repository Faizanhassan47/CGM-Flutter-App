class AppConfig {
  const AppConfig._();

  static const String _defaultUrl = 'https://aima.gms-world.com/';

  static const String _rawBaseUrl = String.fromEnvironment('CGM_API_BASE_URL');
  static const String _rawWsUrl = String.fromEnvironment('CGM_WS_URL');

  /// Backend REST base URL, read from `.env` (CGM_API_BASE_URL),
  /// falling back to the production URL if not provided at build time.
  static String get apiBaseUrl =>
      _rawBaseUrl.trim().isNotEmpty ? _rawBaseUrl.trim() : _defaultUrl;

  /// Realtime gateway URL, read from `.env` (CGM_WS_URL).
  /// Falls back to the API base URL since both are served by the same backend.
  static String get wsUrl =>
      _rawWsUrl.trim().isNotEmpty ? _rawWsUrl.trim() : apiBaseUrl;

  static const String defaultLanguage = String.fromEnvironment(
    'APP_DEFAULT_LANGUAGE',
    defaultValue: 'English',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}
