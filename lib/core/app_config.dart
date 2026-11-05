class AppConfig {
  const AppConfig._();

  /// Live Circle API. Fixed so a phone build cannot call localhost.
  static const String apiBaseUrl = 'https://aima.gms-world.com/';

  /// Realtime gateway on the same host.
  static const String wsUrl = 'https://aima.gms-world.com/';

  static const String defaultLanguage = String.fromEnvironment(
    'APP_DEFAULT_LANGUAGE',
    defaultValue: 'English',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}
