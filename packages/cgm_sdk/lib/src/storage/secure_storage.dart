import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Complete App only [FlutterSecureStorage] Configuration（DB master key / token / equipment UUID / Various local
/// Use it for all small configurations), new uses must be cited here.。
///
/// iOS must be given explicitly `first_unlock`：Plug-in default `unlocked` Reading will throw when the screen is locked
/// PlatformException，and iOS Depend on bluetooth-central Wake up the collection in the background and read it when the screen is locked DB key
/// and token time. Old entries will not be affected, and the plug-in will clear other entries the next time it is written. accessibility entry with the same name。
const kSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
