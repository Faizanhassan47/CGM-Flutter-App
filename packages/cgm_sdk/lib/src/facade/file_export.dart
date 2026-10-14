import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show GeneratedDatabase;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:cgm_sdk/src/facade/models.dart';

/// export directory：Documents（iOS Visible via file sharing；Android In the application private directory）。
Future<Directory> sdkExportDir() async {
  final dir = Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'cgm_sdk_export'),
  );
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

String _stamp(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';
}

/// Blood glucose record export csv / json（interface 21），Return absolute path。
Future<String> exportSamples(
  List<GlucoseSample> rows, {
  required String format,
}) async {
  final dir = await sdkExportDir();
  final now = DateTime.now();
  if (format == 'json') {
    final f = File(p.join(dir.path, 'cgm_glucose_${_stamp(now)}.json'));
    await f.writeAsString(jsonEncode([for (final r in rows) r.toMap()]));
    return f.path;
  }
  final f = File(p.join(dir.path, 'cgm_glucose_${_stamp(now)}.csv'));
  final sb = StringBuffer(
    'wearId,seq,measuredAt,value,warmup,abnormal,source,rawCurrent,temperature,voltage\n',
  );
  for (final r in rows) {
    sb.writeln(
      [
        r.wearId,
        r.seq,
        r.measuredAt.toUtc().toIso8601String(),
        r.value ?? '',
        r.warmup ? 1 : 0,
        r.abnormal ? 1 : 0,
        r.source,
        r.rawCurrent ?? '',
        r.temperature ?? '',
        r.voltage ?? '',
      ].join(','),
    );
  }
  await f.writeAsString(sb.toString());
  return f.path;
}

/// diagnostic package (interface 25）：Clear text library copy + devlog.txt + bread crumbs beaten zip，Does not contain any keys。
/// Clear text copy entered zip Delete immediately, leaving no unencrypted library on disk。
Future<String> exportDiagnostics(
  GeneratedDatabase db, {
  String? extraText,
}) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = await sdkExportDir();
  final now = DateTime.now();
  final archive = Archive();

  // 1) plaintext library：ATTACH Target KEY Empty string is plain text（SQLCipher sqlcipher_export）
  final plain = File(p.join(dir.path, 'cgm_sdk_plain.db'));
  try {
    if (plain.existsSync()) plain.deleteSync();
    final escaped = plain.path.replaceAll("'", "''");
    await db.customStatement("ATTACH DATABASE '$escaped' AS plaintext KEY '';");
    await db.customStatement("SELECT sqlcipher_export('plaintext');");
    await db.customStatement('DETACH DATABASE plaintext;');
    if (plain.existsSync()) {
      final bytes = plain.readAsBytesSync();
      archive.addFile(ArchiveFile('cgm_sdk_plain.db', bytes.length, bytes));
    }
  } catch (e) {
    final msg = utf8.encode('export failed: $e');
    archive.addFile(ArchiveFile('db_export_error.txt', msg.length, msg));
  } finally {
    if (plain.existsSync()) plain.deleteSync();
  }

  // 2) log：devlog.txt（recent appointment 4MB，Cover nearly 7 Normal daily dosage）+ bread crumbs（Android external private directory）
  final candidates = <File>[File(p.join(docs.path, 'devlog.txt'))];
  if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      candidates.addAll([
        File(p.join(ext.path, 'breadcrumb.txt')),
        File(p.join(ext.path, 'breadcrumb_last.txt')),
        File(p.join(ext.path, 'algo_feed.txt')),
      ]);
    }
  }
  for (final f in candidates) {
    if (!f.existsSync()) continue;
    final bytes = f.readAsBytesSync();
    archive.addFile(ArchiveFile(p.basename(f.path), bytes.length, bytes));
  }
  if (extraText != null) {
    final bytes = utf8.encode(extraText);
    archive.addFile(ArchiveFile('sdk_state.txt', bytes.length, bytes));
  }

  final out = File(p.join(dir.path, 'cgm_diagnostics_${_stamp(now)}.zip'));
  final data = ZipEncoder().encode(archive);
  await out.writeAsBytes(data, flush: true);
  return out.path;
}
