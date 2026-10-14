import 'dart:io';

/// Run the footprint ”black box” and add disk writes simultaneously。
///
/// native abort(.so internal collapse)Neither is it the same as being killed by a system freeze. Dart abnormal，[CrashGuard] Can’t get a single one，
/// The log disappears with the process. Synchronize key actions here flush Place the order and use ”Session Open”/”Normal off” mark will be judged last time
/// Whether it terminates abnormally, and distinguishes ”backend killed” or ”frontend crashed” based on the last footprint」。
/// Place the disk in an external private directory（adb waived root (can be pulled), and the whole process will be silently downgraded if it fails.。
class BreadcrumbLog {
  BreadcrumbLog._();

  static const String _fileName = 'breadcrumb.txt';

  /// Archive of the previous session (retained only when terminated abnormally) for pop-up at next startup。
  static const String _lastFileName = 'breadcrumb_last.txt';

  /// A snapshot of the input parameters recently fed into the algorithm (overwrite). collapsed .so Take it when you are here algo_validate Replay offline to reproduce。
  static const String _feedFileName = 'algo_feed.txt';

  /// Host package name—drop path `/sdcard/Android/data/<package name>/files` A paragraph is not used for filtering。
  /// host isolate exist `WidgetsFlutterBinding.ensureInitialized()` The first sentence after；
  /// Front desk service isolate Depend on FlutterForegroundServiceController through saveData/getData Pass it over。
  /// The disk will not be placed when the string is empty (otherwise it will be written `/sdcard/Android/data//files`，Android 11+ Can’t create directory）。
  static String packageName = '';

  /// Session starts/Normal end tag. There is no end of file [_cleanExitMark] That is, the last abnormal termination。
  static const String _sessionMark = '#SESSION_START';
  static const String _cleanExitMark = '#CLEAN_EXIT';

  /// Single session footprint limit：15 Tiandai keeps running for a period of time. If it is not capped, the user storage will be full; if it exceeds the limit, the first half will be deleted.。
  static const int _maxBytes = 256 * 1024;

  static void write(String line) {
    if (!Platform.isAndroid) return;
    try {
      final file = _resolveSync();
      if (file == null) return;
      _capIfNeeded(file);
      final stamp = DateTime.now().toIso8601String().substring(11, 23);
      file.writeAsStringSync(
        '$stamp  $line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }

  /// Overwrite ”Recent N Algorithm input parameters” snapshot. Overwrite rather than append: content remains constant KB，No need to truncate, the disk writing cost is fixed。
  static void writeFeedSnapshot(String content) {
    if (!Platform.isAndroid) return;
    try {
      final file = _feedFile ??= _resolveSync(name: _feedFileName);
      file?.writeAsStringSync(content, flush: true);
    } catch (_) {}
  }

  /// Directory parsing result caching: the feed snapshot is written frame by frame and cannot be accessed every time stat Table of contents。
  static File? _feedFile;

  /// Read the feed snapshot left by the last session (read before the first frame this time, when the file is still the content before the last crash)）。
  static String? _readFeedSnapshot() {
    try {
      final file = _resolveSync(name: _feedFileName);
      if (file == null || !file.existsSync()) return null;
      final s = file.readAsStringSync().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  /// Open a new session: Determine whether the last abnormal termination was, if so, archive the last footprint and return a diagnostic report (no abnormal return) null），
  /// Then clear the session footprint and start writing again.。[appVersion] Record it in the session header to help you identify which package crashed.。
  static String? startSession({String appVersion = ''}) {
    if (!Platform.isAndroid) return null;
    String? report;
    try {
      final file = _resolveSync();
      if (file == null) return null;
      if (file.existsSync()) {
        final prev = file.readAsStringSync();
        if (prev.trim().isNotEmpty && !prev.contains(_cleanExitMark)) {
          report = _buildReport(prev, _readFeedSnapshot());
          try {
            _resolveSync(name: _lastFileName)?.writeAsStringSync(prev);
          } catch (_) {}
        }
      }
      final stamp = DateTime.now().toIso8601String();
      // overwrite=Clear the previous session, leaving only the current session。
      file.writeAsStringSync(
        '$_sessionMark $stamp v=$appVersion\n',
        flush: true,
      );
    } catch (_) {}
    return report;
  }

  /// Exit marking normally (life cycle detached）。If this is enabled, the next startup will not terminate abnormally.。
  static void markCleanExit() => write(_cleanExitMark);

  /// Generate report from last session footprint: Verdict + at last 80 On-site + The input sequence of parameters fed into the algorithm before crashing（[feed] Can be replayed offline）。
  /// Only writes back the black box file and does not play it to the user。
  static String _buildReport(String prev, String? feed) {
    final lines = prev
        .trim()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final last = lines.isEmpty ? '' : lines.last;
    // Stopping in the ”Backstage” is most likely caused by ROM freeze/Cleaning and killing, the action that stops at the foreground is really bad（native/ANR）。
    final backgrounded =
        last.contains('lifecycle=paused') ||
        last.contains('lifecycle=inactive') ||
        last.contains('lifecycle=hidden');
    final verdict = backgrounded
        ? 'Last time it was [after retreating to the background]. → High probability of being frozen by the system/Clean and kill, not crash。\n'
              '  evidence：app No front desk service, domestically produced ROM The background must be killed; when the user clicks on the notification and comes back, they see a cold start.。'
        : 'The last time it was [Running in the foreground] was not there. → Most likely it will collapse(native SIGSEGV / ANR killed)。\n'
              '  Next step: Check which action the last footprint is, and then use it adb logcat -b crash Snap stack alignment。';
    final feedSection = (feed == null || feed.isEmpty)
        ? ''
        : '\n\n--- Feed the input parameters of the algorithm before the crash (several recent ones, which can be replayed offline）---\n$feed';
    return '【The last run terminated abnormally】\n'
        'determination：$verdict\n'
        'the last footprint：$last\n'
        '\n--- Live (final ${lines.length > 80 ? 80 : lines.length} strip）---\n'
        '${lines.length > 80 ? lines.sublist(lines.length - 80).join('\n') : lines.join('\n')}'
        '$feedSection';
  }

  /// If the upper limit is exceeded, the first half will be suppressed - the collapse site is at the tail, so if you lose the head, you will not lose the tail.。
  static void _capIfNeeded(File file) {
    try {
      if (!file.existsSync() || file.lengthSync() <= _maxBytes) return;
      final lines = file.readAsStringSync().split('\n');
      final keep = lines.sublist(lines.length ~/ 2);
      file.writeAsStringSync(
        '(The first half has been truncated according to the upper limit)\n${keep.join('\n')}',
        flush: true,
      );
    } catch (_) {}
  }

  static String? readAndClear() {
    if (!Platform.isAndroid) return null;
    try {
      final file = _resolveSync();
      if (file == null || !file.existsSync()) return null;
      final content = file.readAsStringSync();
      file.deleteSync();
      return content.trim().isEmpty ? null : content;
    } catch (_) {
      return null;
    }
  }

  /// Clear the running traces left by the machine when logging out of the account。
  ///
  /// breadcrumb and algo_feed There is the current of the previous account./Raw health data such as temperature should not remain on the machine after logging out.；
  /// crash_log Only crash stack, no user data, retained。
  static void clearUserTraces() {
    for (final name in const [_fileName, _lastFileName, _feedFileName]) {
      try {
        final f = _resolveSync(name: name);
        if (f != null && f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    _feedFile =
        null; // The cached handle points to the deleted file, leave it blank and let it be re-created next time it is written.
  }

  static File? _resolveSync({String name = _fileName}) {
    if (packageName.isEmpty) return null;
    final candidates = <String>[
      '/sdcard/Android/data/$packageName/files',
      '/storage/emulated/0/Android/data/$packageName/files',
    ];
    for (final dirPath in candidates) {
      try {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) dir.createSync(recursive: true);
        return File('$dirPath/$name');
      } catch (_) {}
    }
    return null;
  }
}
