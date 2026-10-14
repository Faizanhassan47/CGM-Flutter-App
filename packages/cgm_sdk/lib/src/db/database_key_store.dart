import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../log/dev_log.dart';
import '../storage/secure_storage.dart';

/// Secure access to database master keys。
///
/// Take the whole library SQLCipher Transparent encryption, the key only enters Android Keystore / iOS Keychain，first
/// Start random generation 256 Bit and persistence. If the key is lost in the encryption library, it is irreversible. You can only log in again and reinject it from the cloud.。
class DatabaseKeyStore {
  DatabaseKeyStore({
    FlutterSecureStorage? storage,
    Duration? missingKeyRetryDelay,
  }) : _storage = storage ?? kSecureStorage,
       _missingKeyRetryDelay =
           missingKeyRetryDelay ?? const Duration(seconds: 2);

  final FlutterSecureStorage _storage;

  /// 「The reread interval when the key cannot be read, test transmission [Duration.zero]。
  final Duration _missingKeyRetryDelay;

  /// Name of historical entry: There may be more than one with the same name. It is not sure which one to read. It is only read but not written.。
  static const _keyName = 'cgm_db_cipher_key';

  /// Active entry name: No historical duplicate entries, read OK. After successfully opening the library, write the one that can be used here.，
  /// Next time you start reading, you will get it right, no need to try one by one.。
  static const _keyNameV2 = 'cgm_db_cipher_key_v2';

  /// Key copy: Master entry rewrite is ”deletion+”Write a new one” in two steps, if you are killed in the middle, it will be gone.。
  static const _backupKeyName = 'cgm_db_cipher_key_bak';

  /// The number of rereads when the library is still there but the key cannot be read (the keychain may not be available temporarily during the lock screen period)）。
  static const _missingKeyRetries = 5;

  static const _keyBytes = 32;

  /// Take out the existing key; if not, generate one and persist it before returning。
  ///
  /// The key is not there [encryptedDbFile] The library could no longer be opened when it was still there (it was restored after changing the machine and it did not include Keychain
  /// The backup will be like this), changing the new key to open will only read and write all errors, so deal with the old database first.。
  /// only in read Processed only when empty is returned explicitly；Keychain Temporarily inaccessible means an exception is thrown and cannot be reached here.。
  Future<String> getOrCreate({File? encryptedDbFile}) {
    // App Library and SDK The head of the library holds a meeting to obtain keys concurrently: everything in the middle await，If both channels are read empty, each will generate one.、
    // The last writer wins, and another library cannot be opened next time it is started. Only one copy is run at the same time, and latecomers will wait for the result.。
    return _inflight ??= _getOrCreate(
      encryptedDbFile: encryptedDbFile,
    ).whenComplete(() => _inflight = null);
  }

  Future<String>? _inflight;

  Future<String> _getOrCreate({File? encryptedDbFile}) async {
    final v2 = await _readNamed(_keyNameV2);
    if (v2 != null) return v2;
    final legacy = await _readNamed(_keyName);
    if (legacy != null) {
      return legacy; // Old entries can only be read and not written, and will be moved to after the database is successfully opened. v2
    }

    // If the library is still there but the key cannot be read, it may be that the keychain cannot be released during the lock-screen period. In this case, deleting the library will destroy the data.。
    // First read the backup entries, and then re-read them several times. If you can’t get them, you decide that they are really lost.。
    if (encryptedDbFile != null && encryptedDbFile.existsSync()) {
      final backup = await _readNamed(_backupKeyName);
      if (backup != null) {
        DevLog.instance.add(
          'db-key',
          'The main entry cannot be read, use the backup entry instead',
        );
        return backup;
      }
      for (var i = 1; i <= _missingKeyRetries; i++) {
        await Future<void>.delayed(_missingKeyRetryDelay);
        final retry =
            await _readNamed(_keyNameV2) ?? await _readNamed(_keyName);
        if (retry != null) {
          DevLog.instance.add(
            'db-key',
            'No. $i Obtained the key after re-reading',
          );
          return retry;
        }
      }
      // Only when you confirm that the keychain is usable at the moment (can be written in and read back) can you conclude that the key is really lost.；
      // The keychain cannot be read before unlocking for the first time after booting. At this time, the library will destroy the user data.。
      if (!await _keychainUsable()) {
        DevLog.instance.add(
          'db-key',
          'The keychain is unavailable at the moment. The library file will not be moved. Please try again after unlocking it.',
        );
        throw StateError(
          'The keychain is temporarily unavailable and the database key cannot be obtained.',
        );
      }
      DevLog.instance.add(
        'db-key',
        'Keychain is available but there really is no key → The old database cannot be decrypted',
      );
    }

    await _dropUndecryptableDb(encryptedDbFile);
    final fresh = _generateKey();
    await _storage.write(key: _keyNameV2, value: fresh);
    await _storage.write(key: _backupKeyName, value: fresh);
    return fresh;
  }

  /// After successfully opening the database, solidify this key to v2 Entries, you will get it right the next time you start it.。
  Future<void> rememberWorkingKey(String workingKey) async {
    try {
      if (await _storage.read(key: _keyNameV2) != workingKey) {
        await _storage.write(key: _keyNameV2, value: workingKey);
        await _storage.write(key: _backupKeyName, value: workingKey);
        DevLog.instance.add(
          'db-key',
          'The key that can open the library has been solidified to v2 entry',
        );
      }
    } catch (e) {
      DevLog.instance.add(
        'db-key',
        'Failed to harden key(Does not affect this operation): $e',
      );
    }
  }

  /// Keys that can be tried when opening the library：v2 Entries are given priority, followed by older entries, and lastly backup entries.。
  /// The old entries may not be empty but are incorrect (there are multiple entries in the keychain with the same name, and I am not sure which one to read). You cannot recognize just one.。
  Future<List<String>> candidateKeys({File? encryptedDbFile}) async {
    final keys = <String>[await getOrCreate(encryptedDbFile: encryptedDbFile)];
    for (final name in [_keyNameV2, _keyName, _backupKeyName]) {
      final v = await _readNamed(name);
      if (v != null && !keys.contains(v)) keys.add(v);
    }
    return keys;
  }

  /// To read an item, an empty string is treated as if there is none. The log only records the length and the previous 4 Bit, used to determine whether there are multiple entries with the same name。
  Future<String?> _readNamed(String name) async {
    final v = await _storage.read(key: name);
    DevLog.instance.add(
      'db-key',
      v == null || v.isEmpty
          ? 'read key[$name]=null'
          : 'read key[$name] len=${v.length} head=${v.substring(0, 4)}',
    );
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Rename the library that cannot be decrypted and keep it instead of deleting it: deleting the library when the key determination is wrong will result in irreversible data loss.，
  /// After the name change, the new warehouse will still be built, but the old warehouse can be saved manually. together with `-wal`/`-shm` Change the name together. If you keep it, it will be regarded as the new database.
  /// Read your own log. If the file does not exist, it will be installed for the first time and skipped.。
  static Future<void> _dropUndecryptableDb(File? db) async {
    if (db == null || !db.existsSync()) return;
    DevLog.instance.add(
      'db-key',
      'The old database cannot be decrypted → Change name and keep it ${db.path}.unopenable',
    );
    for (final path in [db.path, '${db.path}-wal', '${db.path}-shm']) {
      try {
        final f = File(path);
        if (!f.existsSync()) continue;
        final kept = File('$path.unopenable');
        if (kept.existsSync()) await kept.delete();
        await f.rename(kept.path);
      } catch (e) {
        DevLog.instance.add('db-key', 'Name change failed $path: $e');
      }
    }
  }

  /// Just rename the library and keep it without changing the key: the key can open the sister library, which means that the file is damaged and not the key.。
  Future<void> quarantineFile(File db) => _dropUndecryptableDb(db);

  /// The last resort when all known keys cannot open this library: rename the old library and keep it, send a new key to rebuild it。
  /// After changing the key [alsoQuarantine] The sister library with the same key can no longer be opened and has to be renamed.。
  /// Before rebuilding, delete the entry with the same name before writing to prevent the new key from being covered by the old entry.。
  Future<String> resetToFreshKey({
    File? encryptedDbFile,
    Iterable<File> alsoQuarantine = const [],
  }) async {
    await _dropUndecryptableDb(encryptedDbFile);
    for (final f in alsoQuarantine) {
      await _dropUndecryptableDb(f);
    }
    final fresh = _generateKey();
    await _forceWrite(_keyNameV2, fresh);
    await _forceWrite(_backupKeyName, fresh);
    DevLog.instance.add(
      'db-key',
      'New key issued and library rebuilt(The old library has been renamed and retained.)',
    );
    return fresh;
  }

  /// Before writing, delete the entries with the same name (there may be more than one) and make sure that what you read back is the one you just wrote.。
  /// Only used when changing to a new key, not a key that can open the library。
  Future<void> _forceWrite(String name, String value) async {
    for (var i = 0; i < 5; i++) {
      await _storage.delete(key: name);
      if (await _storage.read(key: name) == null) break;
    }
    await _storage.write(key: name, value: value);
  }

  /// Whether the keychain is available at the moment: write a probe and read it back。
  /// Used to distinguish ”the key is really lost” and ”the lock screen period cannot be read temporarily”, the latter cannot move the library。
  Future<bool> _keychainUsable() async {
    const probeKey = 'cgm_db_cipher_key_probe';
    try {
      await _storage.write(key: probeKey, value: '1');
      final back = await _storage.read(key: probeKey);
      await _storage.delete(key: probeKey);
      return back == '1';
    } catch (_) {
      return false;
    }
  }

  /// Only for scenarios where the key is lost and needs to be reset; after clearing it, the old encryption library can no longer be opened.。
  Future<void> reset() => _storage.delete(key: _keyName);

  String _generateKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(_keyBytes, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }
}
