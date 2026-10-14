import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, AppLifecycleState;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import '../log/dev_log.dart';
import 'database_key_store.dart';

/// load SQLCipher Dynamic library. Each platform has different sources (top-level functions，open API It is required to statically reference and cross isolate）。
DynamicLibrary _openSqlCipher() {
  if (Platform.isAndroid) {
    return openCipherOnAndroid();
  }
  if (Platform.isIOS || Platform.isMacOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('sqlcipher.dll');
  }
  // Linux and desktop testing environment
  return DynamicLibrary.open('libsqlcipher.so');
}

bool _cipherResolverInstalled = false;

/// Bundle sqlite3 The dynamic library parsing redirects to SQLCipher build, must be called before opening any library。
void _installCipherResolver() {
  if (_cipherResolverInstalled) return;
  open.overrideForAll(_openSqlCipher);
  _cipherResolverInstalled = true;
}

/// Verify that the loaded SQLCipher：ordinary sqlite3 superior `PRAGMA cipher_version` Return empty。
bool _hasCipher(Database db) {
  final result = db.select('PRAGMA cipher_version;');
  return result.isNotEmpty && result.first.values.first.toString().isNotEmpty;
}

/// Lianxin CGM Local encrypted database。
///
/// The Lianxin business table is mapped as it is, and our extended information will always create a new independent table association without changing the Lianxin table structure./index。
/// For changes in each version, see [migration] of onUpgrade branch。

/// Open the encryption library in the document directory [fileName]，The key comes from [keyStore]。
///
/// [sisterFileName] is another library file that shares the same key（App Library ↔ SDK Library）：
/// - Key retrieval protection ”the library is still there but the key cannot be read and the library is not moved” is triggered by the existence of either of the two files.；
/// - 3 If the wheel cannot be opened and you need to change the key, first use the current key to try to open the sister library - if it can be opened, it means that the key is not broken, but this file is.，
///   Only rename and rebuild this file without changing the key, otherwise the sister library will not be able to be opened and will be implicated in the name change.。
LazyDatabase openEncryptedLazy({
  required String fileName,
  required DatabaseKeyStore keyStore,
  String? sisterFileName,
}) {
  return LazyDatabase(() async {
    final sw = Stopwatch()..start();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    final sister = sisterFileName == null
        ? null
        : File(p.join(dir.path, sisterFileName));
    // If any library file exists, the key has been sent: the library cannot be moved if the key cannot be read.
    final guard = file.existsSync() ? file : sister;

    // Check the key before handing it over every time drift，Don’t take the fast path of “pass the inspection and drive straight away”: take the key in the record and drive straight away
    // on failure drift The failure is irreversible, and the entire process’s local reading and writing are disabled; opening the library is not a startup bottleneck.。

    for (var round = 1; ; round++) {
      try {
        // A round of known keys(v2/Old entry/backup)try them all
        final exec = await openEncryptedWithRetry(
          file: file,
          readKeys: () => keyStore.candidateKeys(encryptedDbFile: guard),
          onKeyVerified: (key, _) async => keyStore.rememberWorkingKey(key),
          maxAttempts: 1,
        );
        DevLog.instance.add(
          'db',
          'The local library is open $fileName ${sw.elapsedMilliseconds}ms',
        );
        return exec;
      } catch (e) {
        final lc = WidgetsBinding.instance.lifecycleState;
        // Early start lifecycleState Maybe still null（iOS），At this time, the user is waiting on the startup page，
        // Processed as foreground; only when clearly in non-foreground (lock screen)/Backstage) before leaving 15 The slow path every second。
        final resumed = lc == null || lc == AppLifecycleState.resumed;
        // There is someone waiting at the front desk: I have tried the key and it still can’t be opened, so there is no point in waiting (this is only needed if the keychain occasionally returns the old value)
        // reread，3 enough rounds), approx. 2 Rebuild in seconds。
        if (resumed && round >= 3) {
          final goodKey = await _keyThatOpensSister(keyStore, sister);
          if (goodKey != null) {
            DevLog.instance.add(
              'db',
              'Front desk continuous test $round Wheel cannot be opened $fileName，But it can be opened with the same key $sisterFileName → Only rename and rebuild the library without changing the key',
            );
            await keyStore.quarantineFile(file);
            return openEncryptedNative(file, goodKey, background: true);
          }
          DevLog.instance.add(
            'db',
            'Front desk continuous test $round Can’t open the library even at any time → Rename the old database and keep it, and rebuild it with the new key.',
          );
          final fresh = await keyStore.resetToFreshKey(
            encryptedDbFile: file,
            alsoQuarantine: [if (sister != null) sister],
          );
          return openEncryptedNative(file, fresh, background: true);
        }
        if (round == 1 || round % 5 == 0) {
          DevLog.instance.add(
            'db',
            'Library opening failed(No. $round Wheel, does not move the library file): $e',
          );
        }
        // Backstage(lock screen)No one is waiting when waking up, try slowly, and do not rebuild user data
        await Future<void>.delayed(
          resumed ? const Duration(seconds: 1) : const Duration(seconds: 15),
        );
      }
    }
  });
}

/// Which of the existing candidate keys can open the sister library; the sister library does not exist or cannot be opened and returns null。
Future<String?> _keyThatOpensSister(
  DatabaseKeyStore keyStore,
  File? sister,
) async {
  if (sister == null || !sister.existsSync()) return null;
  for (final k in await keyStore.candidateKeys(encryptedDbFile: sister)) {
    try {
      _verifyKeyOpens(sister, k);
      return k;
    } catch (_) {}
  }
  return null;
}

/// The key obtained when the lock screen period is started may not be able to open the library.（iOS：`PRAGMA key` The first statement after
/// `SqliteException(26) file is not a database`）。At this time, the database cannot be deleted, nor can it fail directly.：
/// [LazyDatabase] The failure result will be cached, and all subsequent local reads and writes in this process will be discarded. Wait here to unlock and try again。
Future<QueryExecutor> openEncryptedWithRetry({
  required File file,
  required Future<List<String>> Function() readKeys,
  Future<void> Function(String workingKey, bool fromMainEntry)? onKeyVerified,
  Duration retryDelay = const Duration(seconds: 3),
  int maxAttempts = 12,
  bool background = true,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      // The main entry may not be empty, but it is incorrect. Try the candidate keys one by one, and you cannot just accept the first one.
      final keys = await readKeys();
      for (var i = 0; i < keys.length; i++) {
        try {
          _verifyKeyOpens(file, keys[i]);
          await onKeyVerified?.call(keys[i], i == 0);
          DevLog.instance.add(
            'db',
            attempt == 1
                ? 'The local library is open ${file.path}'
                : 'The local library is open(No. $attempt attempts) ${file.path}',
          );
          return openEncryptedNative(file, keys[i], background: background);
        } catch (e) {
          lastError = e;
        }
      }
      throw StateError(
        '${keys.length} Cannot open the library even with candidate keys: $lastError',
      );
    } catch (e) {
      lastError = e;
      // The lock screen may last for a while, and the log buffer will be exhausted each time, both for the first time and every time. 5 Record one item at a time
      if (attempt == 1 || attempt % 5 == 0) {
        DevLog.instance.add(
          'db',
          'Library opening failed(No. $attempt times, do not move the library file, try again later): $e',
        );
      }
      if (attempt >= maxAttempts) rethrow;
      await Future<void>.delayed(retryDelay);
    }
  }
  throw StateError('The local library never opens: $lastError');
}

/// Take this key and open it directly to verify the authenticity.：SQLCipher Only reported on the first statement that actually touches the data page 26，
/// and drift Lazy opening and caching failure. Close immediately after verification, a few milliseconds。
void _verifyKeyOpens(File file, String key) {
  _installCipherResolver();
  final db = sqlite3.open(file.path);
  try {
    db.execute("PRAGMA key = '${_escapeKey(key)}';");
    db.select('SELECT count(*) FROM sqlite_master;');
  } finally {
    db.dispose();
  }
}

/// Encryption opens (or creates a new）[file]，Tests also reuse this path to pass explicit [key]。
///
/// [background]=true Bundle SQL Move execution to background isolate，otherwise SQLCipher IO all in UI isolate
/// Zoom on ANR；cipher Two parsers are needed isolate Install each one once. Test to keep versions in sync，
/// testWidgets of FakeAsync Can’t run across the area isolate aisle。
QueryExecutor openEncryptedNative(
  File file,
  String key, {
  bool background = false,
}) {
  _installCipherResolver();
  void applyCipher(Database rawDb) {
    assert(
      _hasCipher(rawDb),
      'What is loaded is not SQLCipher Build, encryption cannot take effect',
    );
    // PRAGMA key must precede others pragma（SQLCipher Require）
    rawDb.execute("PRAGMA key = '${_escapeKey(key)}';");
    // Backfilling is to write two tables for each transaction. By default, DELETE+FULL per transaction fsync Twice, very slow when there are tens of thousands of items。
    // Change WAL+NORMAL：When a power outage occurs, at most the most recent transactions and devices will be lost. FLASH It’s still there, and it can be restored by reconnecting.。
    rawDb.execute('PRAGMA journal_mode = WAL;');
    rawDb.execute('PRAGMA synchronous = NORMAL;');
  }

  return background
      ? NativeDatabase.createInBackground(
          file,
          isolateSetup: _installCipherResolver,
          setup: applyCipher,
        )
      : NativeDatabase(file, setup: applyCipher);
}

/// key in SQL Escape single quotes before literals to prevent injection/syntax error。
String _escapeKey(String key) => key.replaceAll("'", "''");
