import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';
import 'package:cgm_sdk/src/collection/cgm_replay_dataset.dart';

import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';

/// Local blood glucose timeline fix (only Excel timeline path, anchor=Wear activation time）。
///
/// The algorithm eats real timestamps and has state, requiring `measure_time = activeTime + (record_seq-1)×cycle`。
/// Run once before starting collection [run]（Idempotent): misaligned rows by true measure_time Recalculate record_seq，
/// Missing slot from Excel Complete. The serial number of the equipment during production/The time is based on the device and cannot be rescheduled with this restorer.。
class GlucoseTimelineRepair {
  GlucoseTimelineRepair({
    required this.db,
    required this.pipeline,
    required this.dataset,
    this.recordPeriod = const Duration(minutes: 1),
    this.tolerance = const Duration(minutes: 2),
    this.maxFill = 21600,
  });

  final CgmDatabase db;
  final GlucosePipelineRepository pipeline;
  final CgmReplayDataset dataset;

  /// Recording period (slot width), consistent with the collector。
  final Duration recordPeriod;

  /// Only when the deviation between time and slot exceeds this value will the row be judged to be misaligned. The tolerance is used to absorb timer drift.。
  final Duration tolerance;

  /// The upper limit of single gap filling：21600 = 15 One piece per minute for full coverage during the daily wear period。
  final int maxFill;

  /// repair + fill the gap，[activeTime]=slot 1 time. return (Number of rearranged rows, Fill up the number of slots)。
  Future<({int moved, int filled})> run({
    required int wearId,
    required DateTime activeTime,
    required GluCalcParameter params,
  }) async {
    final anchor = activeTime.toUtc();
    final moved = await _repairSeqs(wearId, anchor);
    final filled = await _fillGaps(wearId, anchor, params);
    if (kDebugMode && (moved > 0 || filled > 0)) {
      debugPrint(
        '[Timeline fix] wear=$wearId rearrange misplaced rows $moved strip、Excel fill the gap $filled strip',
      );
    }
    return (moved: moved, filled: filled);
  }

  int get _periodSec => recordPeriod.inSeconds;

  /// ts（UTC）The corresponding slot number（1-based，smallest 1）。
  int _slotOf(DateTime ts, DateTime anchor) {
    final s = ts.toUtc().difference(anchor).inSeconds ~/ _periodSec + 1;
    return s < 1 ? 1 : s;
  }

  /// seq slot standard time（UTC）。
  DateTime _tsOfSlot(int seq, DateTime anchor) =>
      anchor.add(recordPeriod * (seq - 1));

  /// rearrange misplaced rows：|measure_time − slot time| > Tolerance record_seq Change to the corresponding slot。
  /// Process in descending order of the original serial number to avoid chain occupation. If the target slot is already occupied, it will be skipped. Medical data will not be deleted.。
  Future<int> _repairSeqs(int wearId, DateTime anchor) async {
    final rows = await (db.select(
      db.userlocalGlucoseData,
    )..where((t) => t.wearId.equals(wearId))).get();
    if (rows.isEmpty) return 0;

    final occupied = <int>{
      for (final r in rows)
        if (r.recordSeq != null) r.recordSeq!,
    };
    final moves = <({int id, int? oldSeq, DateTime ts, int newSeq})>[];
    for (final r in rows) {
      final seq = r.recordSeq;
      final newSeq = _slotOf(r.measureTime, anchor);
      final misplaced =
          seq == null ||
          r.measureTime
                  .difference(_tsOfSlot(seq, anchor))
                  .abs()
                  .compareTo(tolerance) >
              0;
      if (misplaced && newSeq != seq) {
        moves.add((id: r.id, oldSeq: seq, ts: r.measureTime, newSeq: newSeq));
      }
    }
    if (moves.isEmpty) return 0;
    moves.sort((a, b) => (b.oldSeq ?? 0).compareTo(a.oldSeq ?? 0));

    var movedCount = 0;
    var skipped = 0;
    await db.transaction(() async {
      for (final m in moves) {
        if (occupied.contains(m.newSeq)) {
          skipped++;
          continue; // The target slot is already occupied, so skip it conservatively.
        }
        // Main table: change serial numbers and clear invalid ones five_min Grouping, resetting upload tags
        await (db.update(
          db.userlocalGlucoseData,
        )..where((t) => t.id.equals(m.id))).write(
          UserlocalGlucoseDataCompanion(
            recordSeq: Value(m.newSeq),
            fiveMinFlag: const Value('0'),
            fiveMinGlucose: const Value(null),
            uploadFlag: const Value('0'),
            uploadResult: const Value(null),
            uploadFailReson: const Value(null),
          ),
        );
        // The original table has no independent primary key association, press wear+Original serial number+Minute triple positioning synchronization change
        await (db.update(db.userlocalGlucoseRawData)..where(
              (t) =>
                  t.wearId.equals(wearId) &
                  (m.oldSeq == null
                      ? t.recordSeq.isNull()
                      : t.recordSeq.equals(m.oldSeq!)) &
                  t.measureTime.equalsValue(m.ts),
            ))
            .write(
              UserlocalGlucoseRawDataCompanion(
                recordSeq: Value(m.newSeq),
                uploadResult: const Value(null),
                uploadFailReson: const Value(null),
              ),
            );
        // Not consumed(No DONE)Change the same-origin frames together to prevent subsequent drain Falling into the wrong position again
        await (db.update(db.bleFrameBuffer)..where(
              (t) =>
                  t.wearId.equals(wearId) &
                  (m.oldSeq == null
                      ? t.recordSeq.isNull()
                      : t.recordSeq.equals(m.oldSeq!)) &
                  t.measureTime.equalsValue(m.ts) &
                  t.status.equals(FrameBufferStatus.done).not(),
            ))
            .write(BleFrameBufferCompanion(recordSeq: Value(m.newSeq)));
        if (m.oldSeq != null) occupied.remove(m.oldSeq);
        occupied.add(m.newSeq);
        movedCount++;
      }
    });
    if (kDebugMode && skipped > 0) {
      debugPrint(
        '[Timeline fix] wear=$wearId have $skipped The target slot of the misaligned row is occupied and will be skipped conservatively.',
      );
    }
    return movedCount;
  }

  /// fill the gap：`[1..Maximum local slot]` Missing slot button Excel The corresponding row group frame is fed to the normal pipeline.，
  /// The tail (from the largest slot to the current moment) is given by [ReplayGlucoseCollector] take over。
  Future<int> _fillGaps(
    int wearId,
    DateTime anchor,
    GluCalcParameter params,
  ) async {
    final rows =
        await (db.selectOnly(db.userlocalGlucoseData)
              ..addColumns([db.userlocalGlucoseData.recordSeq])
              ..where(db.userlocalGlucoseData.wearId.equals(wearId)))
            .get();
    final existing = <int>{
      for (final r in rows)
        if (r.read(db.userlocalGlucoseData.recordSeq) != null)
          r.read(db.userlocalGlucoseData.recordSeq)!,
    };
    if (existing.isEmpty) return 0;
    final maxSeq = existing.reduce((a, b) => a > b ? a : b);

    var holes = [
      for (var seq = 1; seq <= maxSeq; seq++)
        if (!existing.contains(seq)) seq,
    ];
    if (holes.isEmpty) return 0;
    if (holes.length > maxFill) {
      if (kDebugMode) {
        debugPrint(
          '[Timeline fix] wear=$wearId gap ${holes.length} Exceed the upper limit $maxFill，'
          'Only the latest $maxFill slots',
        );
      }
      holes = holes.sublist(holes.length - maxFill);
    }

    final anchorSec = anchor.millisecondsSinceEpoch ~/ 1000;
    for (final seq in holes) {
      final s = dataset.sampleForSeq(seq);
      final record = GlucoseRecord(
        timestampSec: anchorSec + (seq - 1) * _periodSec,
        recordSeq: seq,
        voltage: s.voltage,
        temperature: s.temperature,
        rawCurrent: s.current,
        lactate: 0.0,
      );
      await pipeline.ingestFrame(
        BleFrameCodec.encode([record]),
        wearId: wearId,
      );
    }
    await pipeline.drain(params);
    return holes.length;
  }
}
