import 'package:google_sign_in/google_sign_in.dart';
import '../core/app_config.dart';

/// Google Sign-In v7+ wrapper (singleton + authenticate).
class GoogleAuthService {
  GoogleAuthService._();

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final serverClientId = AppConfig.googleServerClientId;
    if (serverClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID is not configured. Call AppConfig.load() first.',
      );
    }
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  /// Returns null when the user cancels.
  static Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google sign-in is not supported on this platform.');
    }
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
