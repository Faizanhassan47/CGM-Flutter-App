import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';
import 'package:cgm_sdk/src/collection/device_timeline_audit.dart';

/// Move the inventory that has been dropped according to the equipment axis back to the real time at one time。
///
/// New data is logged into the library according to the real time (see [DeviceClockSkew]）Finally, the inventory in the warehouse still stops on the equipment axis, and the two sections are combined
/// There will be a hole in the middle that is not true, so the stock must be moved there together.。
///
/// The translation amount is taken from the measured anchor point segment by segment.（[DeviceTimelineAudit]）：The deviation increases step by step (every time the equipment is shut down
/// one step at a time), so press SN Segmentation, each segment uses the deviation of the nearest anchor point on its left, instead of applying the same number throughout the process。
/// There is no anchor point in the section of the disconnection window. It is impossible to know when the equipment will stop. Press ”Normal mining first, then stop” to return to the original position.，
/// and write the uncertainty into the log。
///
/// Only run once per wearing cycle（[_flagKey] fall app_meta），and must be run before any new lines are written this round.，
/// Otherwise, the new row that is already the real axis will be translated again.。
class DeviceTimelineMigration {
  DeviceTimelineMigration(this._db);

  final CgmDatabase _db;

  static String _flagKey(int wearId) => 'timeline_shifted_wear_$wearId';

  /// Returns the number of rows actually translated; has been run / Returns when there is no anchor point to base on 0（Don’t miss the mark, come back next time）。
  Future<int> runOnce({required int wearId}) async {
    final done =
        await (_db.select(_db.appMeta)
              ..where((t) => t.key.equals(_flagKey(wearId)))
              ..limit(1))
            .getSingleOrNull();
    if (done != null) return 0;

    final audit = await DeviceTimelineAudit(_db).run(wearId: wearId);
    if (!audit.hasAnchors) {
      DevLog.instance.add(
        'collect',
        'Timeline return: The real-time frame of this machine is insufficient and the deviation of each segment cannot be calculated. → This round of immovable stock，'
            'Wait until the real-time frame is received (there is a lot of data, but it still stops on the device axis)）',
      );
      return 0;
    }

    // anchor click SN Ascending order：(seq, The actual measured deviation here is seconds)
    final points = [
      for (final a in audit.anchors) (seq: a.seq, skew: a.skewSec),
    ]..sort((x, y) => x.seq.compareTo(y.seq));

    // The deviation is already on the real axis (after upgrading and reinstalling, or after the equipment has declined), there is no need to change it.
    final maxSkew = points
        .map((p) => p.skew.abs())
        .reduce((a, b) => a > b ? a : b);
    if (maxSkew < 60) {
      await _mark(wearId);
      DevLog.instance.add(
        'collect',
        'Timeline return: There is no deviation in each section 1 minutes, there is no need to shift the inventory',
      );
      return 0;
    }

    var moved = 0;
    for (final table in [
      'userlocal_glucose_data',
      'userlocal_glucose_raw_data',
      'ble_frame_buffer',
    ]) {
      moved += await _shiftTable(table, wearId, points);
    }

    await _mark(wearId);
    final b = StringBuffer()
      ..writeln(
        'Timeline return: Stock $moved The rows are translated to the real time according to the measured deviation of each segment (there are many data for one，'
        'Only the time is changed; the translation amount is taken from ${points.length} A measured anchor point, not an inference）',
      );
    for (final s in audit.steps.take(5)) {
      b.writeln(
        '  · SN ${s.from.seq}→${s.to.seq} Less equipment is produced between '
        '${(s.lostSec / 60).toStringAsFixed(1)} minutes; when this segment falls within the disconnection window，'
        'There is no way to know when the equipment will be shut down. It has been reset according to ”normal mining first, then shut down”.',
      );
    }
    DevLog.instance.add('collect', b.toString().trimRight());
    return moved;
  }

  /// according to SN Translate a table piece by piece measure_time。SN Deviation from the first anchor point that is less than the first anchor point。
  Future<int> _shiftTable(
    String table,
    int wearId,
    List<({int seq, int skew})> points,
  ) async {
    var moved = 0;
    for (var i = 0; i < points.length; i++) {
      final from = i == 0
          ? null
          : points[i].seq; // The first paragraph does not set a lower bound
      final to = i == points.length - 1 ? null : points[i + 1].seq;
      final skewMs = points[i].skew * 1000;
      if (skewMs == 0) continue;
      final where = StringBuffer('wear_id = ?2 AND record_seq IS NOT NULL');
      final vars = <Variable>[Variable<int>(skewMs), Variable<int>(wearId)];
      if (from != null) {
        where.write(' AND record_seq >= ?${vars.length + 1}');
        vars.add(Variable<int>(from));
      }
      if (to != null) {
        where.write(' AND record_seq < ?${vars.length + 1}');
        vars.add(Variable<int>(to));
      }
      moved += await _db.customUpdate(
        'UPDATE $table SET measure_time = measure_time + ?1 WHERE $where',
        variables: vars,
        updates: {},
      );
    }
    return moved;
  }

  Future<void> _mark(int wearId) => _db
      .into(_db.appMeta)
      .insertOnConflictUpdate(
        AppMetaCompanion.insert(
          key: _flagKey(wearId),
          value: const Value('1'),
          updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );
}
