import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/cgm_database.dart';

/// Finger blood(BGM)Local cache of correction values, dropped app_meta KV。When blood events are reported to the backend, a copy is saved simultaneously.，
/// For offline retrieval of algorithms `paramBGMbase`；Only logs are recorded for read and write failures, and no rollback is available. 0 That is, no correction。
class BgmCalibrationStore {
  BgmCalibrationStore(this._db);

  final CgmDatabase _db;

  static const _kValue = 'bgm_calib_value';
  static const _kTime = 'bgm_calib_time';

  Future<void> save(double value, DateTime time) async {
    try {
      final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.appMeta, [
          AppMetaCompanion.insert(
            key: _kValue,
            value: Value(value.toString()),
            updatedAt: ts,
          ),
          AppMetaCompanion.insert(
            key: _kTime,
            value: Value(time.toUtc().millisecondsSinceEpoch.toString()),
            updatedAt: ts,
          ),
        ]);
      });
    } catch (e, st) {
      developer.log(
        'The correction value of finger blood failed to be dropped into the library (ignored）',
        name: 'BgmCalibrationStore',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Latest blood value + Time, nothing null。
  Future<({double value, DateTime time})?> readLatest() async {
    try {
      final rows = await (_db.select(
        _db.appMeta,
      )..where((t) => t.key.isIn([_kValue, _kTime]))).get();
      String? v;
      String? t;
      for (final r in rows) {
        if (r.key == _kValue) v = r.value;
        if (r.key == _kTime) t = r.value;
      }
      final value = double.tryParse(v ?? '');
      final ms = int.tryParse(t ?? '');
      if (value == null || ms == null) return null;
      return (
        value: value,
        time: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      );
    } catch (e, st) {
      developer.log(
        'Failed to read finger blood correction value (revert to no correction, ignore）',
        name: 'BgmCalibrationStore',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
