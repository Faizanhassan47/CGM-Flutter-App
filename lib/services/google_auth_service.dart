import 'package:google_sign_in/google_sign_in.dart';
import '../core/app_config.dart';

/// Google Sign-In for google_sign_in 6.x (`signIn` + `authentication`).
class GoogleAuthService {
  GoogleAuthService._();

  static GoogleSignIn? _client;

  static GoogleSignIn _clientOrThrow() {
    final serverClientId = AppConfig.googleServerClientId;
    if (serverClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID is not configured. Call AppConfig.load() first.',
      );
    }
    return _client ??= GoogleSignIn(
      serverClientId: serverClientId,
      scopes: const ['email', 'profile'],
    );
  }

  /// Returns null when the user cancels.
  static Future<GoogleSignInAccount?> signIn() async {
    final client = _clientOrThrow();
    return client.signIn();
  }
}
