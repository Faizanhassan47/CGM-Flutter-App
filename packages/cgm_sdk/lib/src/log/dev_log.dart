import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DevLogEntry {
  DevLogEntry(this.time, this.tag, this.message);

  final DateTime time;
  final String tag;
  final String message;
}

/// Development log bus：[net]/[ble] Wait for the logs to be transferred to the memory ring buffer for app In-floating viewer real-time display，
/// You can also view the packaged real phone directly. Total removal before official release: Delete `core/dev/` Table of contents + app.dart inside
/// DevLogOverlay + reduction LoggingInterceptor / RealCgmBleGate log call。
class DevLog extends ChangeNotifier {
  DevLog._();
  static final DevLog instance = DevLog._();

  /// The upper limit of a single message: super long truncation to prevent a single huge message (large response body, etc.) from overwhelming the memory。
  static const int _maxEntryLen = 4000;

  /// You can keep at most this many entries, any more will be discarded from the oldest.。50 The bar only covers the last ten seconds, and it is not enough to check ”which step starts without counting”；
  /// When the clipboard cannot fit [DevLogOverlay] Walk txt share。
  static const int _maxEntries = 500;

  /// Total in-memory log character budget, approx. 300KB，More than lost from the oldest. It needs to be enlarged together with the number of bars, otherwise the character budget will eat up the number of bars first.。
  static const int _maxTotalChars = 300000;

  final List<DevLogEntry> _entries = [];
  int _totalChars = 0;

  List<DevLogEntry> get entries => _entries;

  /// Remember one thing: into the memory buffer + pass-through `developer.log`（The console can still be pressed tag screen）。
  void add(String tag, String message) {
    final msg = message.length > _maxEntryLen
        ? '${message.substring(0, _maxEntryLen)}…(common ${message.length} character)'
        : message;
    _entries.add(DevLogEntry(DateTime.now(), tag, msg));
    _totalChars += msg.length;
    // Double upper limit: number of items + If the total number of characters exceeds the total number, the oldest batch will be discarded, leaving only the latest batch.。
    while (_entries.length > _maxEntries ||
        (_totalChars > _maxTotalChars && _entries.length > 1)) {
      _totalChars -= _entries.removeAt(0).message.length;
    }
    // developer.log Not entering logcat，adb When grabbing the real machine [ble]/[collect] Can’t see the whole film，
    // debugPrint Enter both modes logcat，So hit both。
    debugPrint('[$tag] $message');
    if (kDebugMode) {
      developer.log(message, name: tag);
    }
    _queueToFile('${_ts(DateTime.now())} [$tag] $msg');
    notifyListeners();
  }

  /// Drop one copy at the same time `Documents/devlog.txt`，Real machine troubleshooting available devicectl Pull directly。
  /// save 500ms Write in batches to avoid writing each item once IO。
  void _queueToFile(String line) {
    if (_fileDead) return;
    _pending.add(line);
    _flushTimer ??= Timer(const Duration(milliseconds: 500), _flush);
  }

  /// If the download fails, give up completely (cannot get the directory)/No write permission), without repeatedly retrying and dragging down the main process.。
  bool _fileDead = Platform.environment.containsKey('FLUTTER_TEST');
  final List<String> _pending = [];
  Timer? _flushTimer;
  File? _file;

  /// File limit: Truncate and restart when exceeded, leaving only the latest section。
  static const int _maxFileBytes = 4 * 1024 * 1024;

  Future<void> _flush() async {
    _flushTimer = null;
    if (_pending.isEmpty) return;
    final batch = _pending.join('\n');
    _pending.clear();
    try {
      final f = _file ??= File(
        '${(await getApplicationDocumentsDirectory()).path}/devlog.txt',
      );
      if (await f.exists() && await f.length() > _maxFileBytes) {
        await f.writeAsString('');
      }
      await f.writeAsString('$batch\n', mode: FileMode.append, flush: false);
    } catch (_) {
      _fileDead = true;
    }
  }

  static String _ts(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
      ':${t.second.toString().padLeft(2, '0')}'
      '.${t.millisecond.toString().padLeft(3, '0')}';

  void clear() {
    _entries.clear();
    _totalChars = 0;
    notifyListeners();
  }
}
