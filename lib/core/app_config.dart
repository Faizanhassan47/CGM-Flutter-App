import 'package:flutter/services.dart';

class AppConfig {
  const AppConfig._();

  static String apiBaseUrl = '';
  static String wsUrl = '';
  static String googleServerClientId = '';

  /// New-sensor heating / calibration window (sensor needs ~2 hours).
  static const int sensorWarmupMinutes = 120;

  static const String defaultLanguage = String.fromEnvironment(
    'APP_DEFAULT_LANGUAGE',
    defaultValue: 'English',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static Future<void> load() async {
    final raw = await rootBundle.loadString('.env');
    final values = <String, String>{};
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final split = trimmed.indexOf('=');
      if (split <= 0) continue;
      values[trimmed.substring(0, split).trim()] = trimmed.substring(split + 1).trim();
    }
    final api = values['CGM_API_BASE_URL'] ?? '';
    final ws = values['CGM_WS_URL'] ?? '';
    final googleClient =
        values['GOOGLE_SERVER_CLIENT_ID'] ?? values['GOOGLE_CLIENT_ID'] ?? '';
    if (api.isEmpty) {
      throw StateError('CGM_API_BASE_URL is missing from .env');
    }
    if (googleClient.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID (or GOOGLE_CLIENT_ID) is missing from .env',
      );
    }
    String withSlash(String value) => value.endsWith('/') ? value : '$value/';
    apiBaseUrl = withSlash(api);
    wsUrl = withSlash(ws.isEmpty ? api : ws);
    googleServerClientId = googleClient;
  }
}
