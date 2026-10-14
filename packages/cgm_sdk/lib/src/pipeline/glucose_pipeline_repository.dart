import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/log/breadcrumb_log.dart';
import 'package:cgm_sdk/src/status/backfill_status.dart';
import 'package:cgm_sdk/src/status/link_activity.dart';
import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/algorithm/glucose_value.dart';
import 'package:cgm_sdk/src/domain/wear_lifecycle_resolver.dart'
    show kWearLifetimeDays;
import 'package:cgm_sdk/src/domain/sdk_tuning.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';
import 'package:cgm_sdk/src/db/converters/converters.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';
import 'package:cgm_sdk/src/pipeline/serial_executor.dart';

/// Framebuffer status. value with ble_frame_buffer.status Column one-to-one correspondence。
abstract class FrameBufferStatus {
  static const String raw = 'RAW';
  static const String done = 'DONE';

  /// The processing failed and needs to be retried (the consumer will stop at this point and not move forward)）。
  static const String retry = 'RETRY';
}

class PipelineDrainResult {
  final int processed;

  /// Whether to stop at a certain frame (not all cleared)）。
  final bool stopped;

  const PipelineDrainResult(this.processed, this.stopped);
}

/// Algorithm serial pipeline orchestration。
///
/// BLE Frame falls first ble_frame_buffer，single consumer press measure_time/record_seq/id Ascending serial feeding of the same set
/// main engine; current ≤ [zeroCurrentEps] time button seq Pick Excel After the current is replaced, the source is fed abnormally without replacement.。
/// The output is logged in the same transaction as the original row, and the frame is marked only after success. DONE，failure to stay RETRY Stop where you are。
/// Change sensor By the caller before feeding the frame [resetAlgorithm]，same wear Not halfway through the cycle init。
class GlucosePipelineRepository {
  /// current ≤ this threshold(nA)Treated as no real measurement: the sensor operating current is positive。
  static const double zeroCurrentEps = 0.05;

  final CgmDatabase _db;
  final AlgorithmGateway _algorithm;
  final SerialExecutor _executor;

  /// Alternative current source for zero current frame: Press record_seq Pick Excel current(nA)。null=No replacement (official version）。
  final double? Function(int seq)? _substituteCurrentForSeq;

  /// The wearing period bound to the current algorithm instance, change wear Algorithm status needs to be reset。
  int? _activeWearId;
  bool _algorithmReady = false;

  /// current init Calibration parameters used: preheating judgment and algoB（Input parameter intercept) is taken from。
  GluCalcParameter? _activeParams;

  /// The most recent measurement moment that was actually fed into the algorithm(Second)/current(nA)，The basis for time axis compensation。
  int? _lastFedTs;
  double? _lastFedCurrent;

  /// The dropped library belongs to the user/Account, default 0 Only for pure link testing。
  final int _ownerUserId;
  final int _ownerAccountId;

  /// After each calculation is completed and one item is dropped into the inventory, there will be a callback. Pure bypass observation. If the error is thrown within the callback, it will be swallowed without bubbling.。
  final void Function(BleFrameBufferRow frame, GlucoseValue out)? _onComputed;

  GlucosePipelineRepository({
    required CgmDatabase db,
    required AlgorithmGateway algorithm,
    double? Function(int seq)? substituteCurrentForSeq,
    SerialExecutor? executor,
    int ownerUserId = 0,
    int ownerAccountId = 0,
    void Function(BleFrameBufferRow frame, GlucoseValue out)? onComputed,
  }) : _db = db,
       _algorithm = algorithm,
       _substituteCurrentForSeq = substituteCurrentForSeq,
       _executor = executor ?? SerialExecutor(),
       _ownerUserId = ownerUserId,
       _ownerAccountId = ownerAccountId,
       _onComputed = onComputed;

  /// Parse a frame of raw bytes, each record falls into ble_frame_buffer（state RAW），Don’t feed the algorithm。
  /// First delivery guarantee App killed/Unprocessed frames will not be lost after disconnection; if parsing fails, the entire frame will be discarded. Return the number of warehousing items。
  Future<int> ingestFrame(Uint8List bytes, {int? wearId}) =>
      ingestFrames(<Uint8List>[bytes], wearId: wearId);

  /// Batch frame dropping: After the whole batch of one transaction is written, the number of entries returned to the warehouse is returned。
  ///
  /// When opening transactions frame by frame, each frame must wait for a flash memory confirmation.（3~15ms），Backfilling thousands of lines means thousands of times；
  /// Filter diameter and [ingestFrame] consistent. There is no sequential dependency between frames, and the entire batch fails in the next round. 0xD3 Can you pull it back again?。
  Future<int> ingestFrames(List<Uint8List> framesBytes, {int? wearId}) async {
    if (framesBytes.isEmpty) return 0;

    final now = DateTime.now().toUtc();
    final lowerBound = DateTime.utc(2020);
    final upperBound = now.add(const Duration(days: 1));
    var inserted = 0;
    await _db.batch((b) {
      for (final bytes in framesBytes) {
        final ParsedFrame frame;
        try {
          frame = BleFrameCodec.parse(bytes);
        } on BleFrameException {
          continue; // The entire bad frame is discarded without affecting other frames in the same batch.
        }
        for (final r in frame.records) {
          // SN=65535 is an invalid sentinel of the firmware, the timeline will be counted as 2106-02-07，throw away
          if (r.recordSeq == 65535) {
            DevLog.instance.add(
              'collect',
              'discard bad data SN=65535（Party A’s firmware sentinel value）',
            );
            continue;
          }
          final t = DateTime.fromMillisecondsSinceEpoch(
            r.timestampSec * 1000,
            isUtc: true,
          );
          // The device occasionally spits out invalid timestamps（0xFFFFFFFF→2106、0→1970），It will break the curve timeline，
          // earlier than 2020 or future >1 Throw away everything from heaven
          if (t.isBefore(lowerBound) || t.isAfter(upperBound)) {
            DevLog.instance.add(
              'collect',
              'Discard invalid timestamp frames seq=${r.recordSeq} ts=$t（Outside the reasonable window）',
            );
            continue;
          }
          b.insert(
            _db.bleFrameBuffer,
            BleFrameBufferCompanion.insert(
              wearId: Value(wearId),
              rawFrame: bytes,
              measureTime: t,
              recordSeq: Value(r.recordSeq),
              rawCurrent: Value(r.rawCurrent),
              temperature: Value(r.temperature),
              voltage: Value(r.voltage),
              createdAt: now,
            ),
          );
          inserted++;
        }
      }
    });
    // When a frame is received, it is considered that the link is alive, even if no new blood glucose rows are generated due to duplication; the homepage distinguishes between ”no data received” and ”data but no new value” accordingly」
    if (inserted > 0) LinkActivity.markFrame(DateTime.now());
    return inserted;
  }

  /// Change sensor / Re-wearing: Let the algorithm uninit→Try again next time init。
  /// same wear Do not adjust during the cycle, as it will clear the algorithm history window.。
  Future<void> resetAlgorithm() async {
    await _executor.run(() async {
      if (_algorithmReady) {
        await _algorithm.uninit();
      }
      _algorithmReady = false;
      _activeWearId = null;
      _activeParams = null;
      _lastFedTs = null;
      _lastFedCurrent = null;
    });
  }

  /// After making up for a period of true history, from [fromTs] Replay the original current in sequence, and recalculate and write back the blood sugar that has been stored in the library。
  ///
  /// Disconnection period [_fillTimelineGap] Use the last current as the holding value to fill in .so，The baseline of stateful algorithms will be
  /// This false flat line is biased, and subsequent true values ​​are calculated from the false baseline; after the true current is compensated, it must be played again。
  ///
  /// and [_primeHistory] Different division of labor: that one only rebuilds .so Internal status and output are discarded; this needs to be written back。
  /// [fromTs] Previous photos cannot be written back (just to rebuild the baseline to the correct starting point). Returns the number of rows written back。
  ///
  /// 《CGM Project algorithm usage documentation》§2「Not halfway through the same wearing cycle init」The thing to guard against is init Directly after clearing the baseline
  /// Feed new data. here init After that, the original current of this wearing period is completely replayed in ascending time order before continuing, and the cold start
  /// path（[_ensureAlgorithmReady] → init → [_primeHistory]）It’s the same set of actions。
  Future<int> recomputeFrom(
    GluCalcParameter params, {
    required int? wearId,
    required DateTime fromTs,
  }) => _executor.run(() => _recomputeFromInternal(params, wearId, fromTs));

  /// app_meta The breakpoint mark for ”Halfway through the recalculation” key。
  static const String _pendingRecomputeKey = 'pending_recompute';

  /// Make up for the recalculation that was not completed last time。
  ///
  /// [recomputeFrom] Write back line by line. If the process is killed in the middle, the first half of the library will be changed and the second half will still have wrong values.，
  /// The next replenishment may not trigger a recalculation. Set the breakpoint before recalculating, clear it after the normal run, and make up the run if there are any residues when starting the collection.。
  /// from the same fromTs Run it again and the result is the same。
  Future<int> resumePendingRecompute(
    GluCalcParameter params, {
    required int? wearId,
  }) => _executor.run(() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_pendingRecomputeKey))).getSingleOrNull();
    final raw = row?.value;
    if (raw == null || raw.isEmpty) return 0;
    final parts = raw.split('|');
    if (parts.length != 2) {
      await _clearPendingRecompute();
      return 0;
    }
    final markWear = int.tryParse(parts[0]);
    final fromMs = int.tryParse(parts[1]);
    if (fromMs == null || markWear != (wearId ?? 0)) {
      // Change wear Okay, the breakpoint of the previous one has nothing to do with this one.
      if (markWear != (wearId ?? 0)) await _clearPendingRecompute();
      return 0;
    }
    DevLog.instance.add(
      'algo',
      'The recalculation did not finish after the last backfill (breakpoint ${DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true).toIso8601String()}）'
          '→ Make up the run, otherwise Curry will leave half of the error value',
    );
    return _recomputeFromInternal(
      params,
      wearId,
      DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true),
    );
  });

  Future<void> _markPendingRecompute(int? wearId, int fromMs) =>
      markPendingRecompute(_db, wearId, fromMs);

  /// Drop the ”pending recalculation” breakpoint: next time the collection is started [resumePendingRecompute] will follow [fromMs] Full recalculation and writeback。
  /// If the calibration is changed when the collection is not running (no equipment), go here and the collection will be automatically recalculated.。
  static Future<void> markPendingRecompute(
    CgmDatabase db,
    int? wearId,
    int fromMs,
  ) => db
      .into(db.appMeta)
      .insertOnConflictUpdate(
        AppMetaCompanion.insert(
          key: _pendingRecomputeKey,
          value: Value('${wearId ?? 0}|$fromMs'),
          updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );

  Future<void> _clearPendingRecompute() => (_db.delete(
    _db.appMeta,
  )..where((t) => t.key.equals(_pendingRecomputeKey))).go();

  Future<int> _recomputeFromInternal(
    GluCalcParameter params,
    int? wearId,
    DateTime fromTs,
  ) async {
    // The stateless engine calculates each item independently, and there is no baseline to correct.
    if (!_algorithm.isStateful) return 0;

    // Set the breakpoint first: if you are killed in the middle, you will leave a library of ”half corrected and half corrected”, which can be used to make up for the next run.
    await _markPendingRecompute(wearId, fromTs.toUtc().millisecondsSinceEpoch);

    // forced rebuild：uninit→init→Clear the feedbase so playback starts from an empty timeline
    if (_algorithmReady) await _algorithm.uninit();
    _algorithmReady = false;
    BreadcrumbLog.write(
      'algo re-init (Recalculation after backfill) wearId=$wearId from=${fromTs.toUtc()}',
    );
    await _algorithm.init(params);
    _activeParams = params;
    _lastFedTs = null;
    _lastFedCurrent = null;

    final rows =
        await (_db.select(_db.userlocalGlucoseRawData)
              ..where(
                (t) => wearId == null
                    ? t.wearId.isNull()
                    : t.wearId.equals(wearId),
              )
              // and [_drainInternal]/[_primeHistory] same sort：record_seq Will be reset due to firmware
              // To reverse the order of time, press seq Platoon feeds a sequence that goes backwards in time
              ..orderBy([
                (t) => OrderingTerm(expression: t.measureTime),
                (t) => OrderingTerm(expression: t.recordSeq),
                (t) => OrderingTerm(expression: t.id),
              ]))
            .get();
    final fromMs = fromTs.toUtc().millisecondsSinceEpoch;

    var fed = 0;
    var rewritten = 0;
    final sw = Stopwatch()..start();
    var ownsBanner = false;
    try {
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final cur = r.rawCurrent1;
        // Fill blank lines (current 0、no blood sugar) skipped, with [_primeHistory] Same caliber
        if (cur == null || !cur.isFinite || cur <= zeroCurrentEps) continue;
        final temp = r.temperature1;
        if (temp != null && !temp.isFinite) continue;
        final ts = r.measureTime.toUtc().millisecondsSinceEpoch ~/ 1000;
        if (!_tsSane(ts, params.startTs)) continue;

        final out = await _feedAlgorithm(
          srcData: cur,
          temperature: temp ?? 0.0,
          ts: ts,
          params: params,
        );
        fed++;
        // fromTs Previously, only the baseline was reconstructed, and the existing values ​​were left unchanged.
        if (out != null &&
            r.measureTime.toUtc().millisecondsSinceEpoch >= fromMs) {
          await _rewriteComputed(r, out, wearId: wearId ?? 0);
          rewritten++;
        }
        // dataProc through JNI Run the main thread of the platform and wear tens of thousands of frames for many days for continuous feeding sessions ANR
        if (fed % _drainBatch == 0) {
          if (!ownsBanner &&
              BackfillStatus.etaMinutes.value == null &&
              sw.elapsedMilliseconds >= _primeBannerAfterMs) {
            ownsBanner = true;
          }
          if (ownsBanner || BackfillStatus.etaMinutes.value != null) {
            BackfillStatus.showMeasured(
              sw: sw,
              done: i,
              remaining: rows.length - i,
              kind: 'replay',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }
    } finally {
      if (ownsBanner) BackfillStatus.etaMinutes.value = null;
    }
    _algorithmReady = true;
    _activeWearId = wearId;
    // The breakpoint cannot be cleared until the entire section is run: an error occurred midway/Keep it if you get killed, next time [resumePendingRecompute] make up run
    await _clearPendingRecompute();
    DevLog.instance.add(
      'algo',
      'Recalculation after backfill: replay $fed Rebuild baseline, write back $rewritten strip'
          '（since ${fromTs.toUtc().toIso8601String()} rise）',
    );
    return rewritten;
  }

  /// Write the recalculated value back to the display row and the original row for the same minute。
  /// upload_flag dial back '0'：If the value is changed, you must re-submit it, otherwise the wrong value will always be retained in the cloud.。
  Future<void> _rewriteComputed(
    UserlocalGlucoseRawDataRow r,
    GlucoseValue out, {
    required int wearId,
  }) async {
    final valueOk = out.value.isFinite;
    final double? safeValue = valueOk ? out.value : null;
    final String? status = valueOk ? _statusFor(out.value) : null;
    final abnormalFlag = valueOk ? '0' : '1';
    final double? safeAlgoK = out.sensitivityUsed.isFinite
        ? out.sensitivityUsed
        : null;
    final mt = r.measureTime.toUtc();
    final minute = DateTime.utc(mt.year, mt.month, mt.day, mt.hour, mt.minute);
    // Replay in ascending order of time. The earlier rows in the window have been modified at this moment. The five-minute caliber set when dropped into the library is directly reused.
    final fiveMin = valueOk
        ? await _fiveMinFor(wearId, minute, out.value)
        : (flag: '0', glucose: null as MedicalDecimal?);
    final (fromMs, toMs) = _minuteWindow(mt);
    await _db.transaction(() async {
      await (_db.update(_db.userlocalGlucoseData)..where(
            (t) =>
                t.wearId.equals(wearId) &
                t.measureTime.isBiggerOrEqualValue(fromMs) &
                t.measureTime.isSmallerThanValue(toMs) &
                // The cloud replenishment line is calculated by other mobile phones and is not under the control of local recalculation.
                (t.isCloudData.isNull() | t.isCloudData.equals('1').not()),
          ))
          .write(
            UserlocalGlucoseDataCompanion(
              glucoseValue1: Value(safeValue),
              status: Value(status),
              abnormalFlag: Value(abnormalFlag),
              fiveMinFlag: Value(fiveMin.flag),
              fiveMinGlucose: Value(fiveMin.glucose),
              uploadFlag: const Value('0'),
            ),
          );
      await (_db.update(
        _db.userlocalGlucoseRawData,
      )..where((t) => t.id.equals(r.id))).write(
        UserlocalGlucoseRawDataCompanion(
          glucoseValue1: Value(safeValue),
          abnormalFlag: Value(abnormalFlag),
          algoK: Value(safeAlgoK),
        ),
      );
    });
  }

  /// Bundle ble_frame_buffer inside RAW Frame drained。
  /// [onProgress] The cumulative number of callbacks after each frame is processed, and the progress of the top bar depends on it, without the caller throttling.。
  Future<PipelineDrainResult> drain(
    GluCalcParameter params, {
    void Function(int processed)? onProgress,
  }) {
    return _executor.run(() => _drainInternal(params, onProgress: onProgress));
  }

  Future<PipelineDrainResult> _drainInternal(
    GluCalcParameter params, {
    void Function(int processed)? onProgress,
  }) async {
    // Consumption inquiry only makes money RAW，Bid RETRY The frame will be lost permanently if it is not dialed back. Before starting work, dial back the amount that has not reached the upper limit. RAW，
    // let DB There are still opportunities for occasional failures such as jitter and algorithm transient anomalies; maintenance to the upper limit RETRY，To prevent bad frames from blocking the queue every round。
    await (_db.update(_db.bleFrameBuffer)..where(
          (t) =>
              t.status.equals(FrameBufferStatus.retry) &
              t.retryCount.isSmallerThanValue(_maxFrameRetry),
        ))
        .write(
          const BleFrameBufferCompanion(status: Value(FrameBufferStatus.raw)),
        );

    var processed = 0;
    // Can’t write onProgress?.call(++processed)：The callback is null hour ?. short circuit，processed constant 0
    void done() {
      processed++;
      onProgress?.call(processed);
    }

    // Thousands of items will be replenished one by one select Too slow, press measureTime Ascending batch prefetch
    var pending = const <BleFrameBufferRow>[];
    var cursor = 0;
    // Accumulated segmentation time (microseconds），drain Log at the end to locate the slow period of replenishment
    var dedupMicros = 0;
    var primeMicros = 0;
    var algoMicros = 0;
    var persistMicros = 0;
    try {
      while (true) {
        if (cursor >= pending.length) {
          // Must be downloaded first and then prefetched: the frames in the buffer are still RAW，If you don’t fall, you will be fished out again by the following query.，
          // The same piece of data is fed to the algorithm twice and falls into two lines.。
          final failed = await _flushWrites();
          if (failed > 0) {
            // Not even a single line has been written in this batch, so it doesn’t mean it has been left in the inventory.，processed Want to take it back
            processed -= failed;
            onProgress?.call(processed);
            return PipelineDrainResult(processed, true);
          }
          pending =
              await (_db.select(_db.bleFrameBuffer)
                    ..where((t) => t.status.equals(FrameBufferStatus.raw))
                    ..orderBy([
                      (t) => OrderingTerm(expression: t.measureTime),
                      (t) => OrderingTerm(expression: t.recordSeq),
                      (t) => OrderingTerm(expression: t.id),
                    ])
                    ..limit(_drainFetch))
                  .get();
          cursor = 0;
          if (pending.isEmpty) {
            return PipelineDrainResult(processed, false);
          }
        }
        final next = pending[cursor++];
        // The entire loop body is wrapped up: any error in any step will converge into ”standard RETRY + Call it a day”, otherwise the frame remains RAW，
        // every round drain Everything starts from it, and the subsequent frames will never come out.。
        try {
          // The device may report multiple reports in one minute. The same (wear, whole minute) Only the first frame is taken for calculation, and subsequent repeated frames are only stored and not counted.
          // （mark DONE、Do not feed the algorithm, do not enter the display table). Deduplication is performed based on whole minutes rather than precise seconds, otherwise duplicate frames in the same minute but different seconds will be missed.。
          final swDedup = Stopwatch()..start();
          // Check the buffer first: the minute database that has been stored in the disk cannot be found; if the hit is repeated, it will only be saved as a duplicate frame.。
          final buffered = _pendingMinuteKeys.contains(
            _minuteKeyOf(next.wearId, next.measureTime),
          );
          final dupRow = buffered
              ? null
              : await _computedRowAt(next.wearId, next.measureTime);
          dedupMicros += swDedup.elapsedMicroseconds;
          if (buffered) {
            await _completeDuplicate(next);
            done();
            continue;
          }
          if (dupRow != null) {
            // The cloud replenishment line (scenario of changing the device) is not available locally. raw：The displayed values ​​​​are retained in the cloud, but the algorithm baseline must be fed sequentially.、
            // raw It must also be completed, otherwise it will be restarted. _primeHistory Replay is incomplete. Duplicate frames in real firmware are still only saved and not counted。
            if (dupRow.isCloudData == '1' &&
                !await _hasRawAt(next.wearId, next.measureTime)) {
              try {
                await _feedAndRecordRaw(next, params);
              } catch (e) {
                await _markRetry(
                  next,
                  'Cloud line baseline reconstruction failed: $e',
                );
                return PipelineDrainResult(processed, true);
              }
            }
            // placeholder row（glucose_value1 null、abnormal_flag='1'）The real data arriving after not blocking: the value during the disconnection period
            // Device exists FLASH , after reconnecting 0xD3 What is pulled back is the true value. Only recognize ”occupying space” → ”True value” this one
            // direction, the true value does not overwrite the true value (maintain ”the same timeline only keeps the first」）。
            final isPlaceholder =
                dupRow.glucoseValue1 == null && dupRow.abnormalFlag == '1';
            final newHasSignal = (next.rawCurrent ?? 0) > zeroCurrentEps;
            if (isPlaceholder && newHasSignal) {
              DevLog.instance.add(
                'collect',
                'At the same time, the placeholder row is overwritten by real data. seq=${next.recordSeq} '
                    'ts=${next.measureTime.toUtc()} current=${next.rawCurrent}nA',
              );
              await _deleteRowsAt(next.wearId, next.measureTime);
              // The normal process that falls below is recalculated and rewritten, and there is no way to go _completeDuplicate
            } else {
              await _completeDuplicate(next);
              done();
              continue;
            }
          }

          // Access control：.so No boundary protection, non-limited current/The temperature will destroy the internal state, and the out-of-bounds timestamp will
          // Negative subscript access segfaults. This type of frame is not fed to the engine, and the exception line flag is dropped directly. DONE，No queue queue。
          if (!_isFiniteInput(next) || !_isTimelineSane(next, params)) {
            final elapsed =
                next.measureTime.toUtc().millisecondsSinceEpoch ~/ 1000 -
                params.startTs;
            final why = !_isFiniteInput(next)
                ? 'current/Temperature is not a finite number(NaN/Inf)，Hello .so Will destroy the internal state'
                : 'Timestamp outside algorithm window：elapsed=${elapsed}s Not here [0, $_maxElapsedSec]'
                      '（startTs=${params.startTs}）——The device clock was not set successfully/firmware reset from0Starting from/'
                      'Even if the benchmark is changed, it will end here.';
            try {
              await _persistInvalidInput(next, reason: why);
            } catch (e) {
              await _markRetry(
                next,
                'Exception frame failed to drop into library: $e',
              );
              return PipelineDrainResult(processed, true);
            }
            done();
            continue;
          }

          // current ≤ threshold = No real measurements (without wearing/composite frame/gap filling), press seq Pick Excel After current replacement
          // Feed the same main engine; no replacement source drops the exception line. Blood sugar is always calculated by the main engine，Excel Only current value is provided。
          final bool zeroCur = (next.rawCurrent ?? 0) <= zeroCurrentEps;
          final double? subCur = zeroCur ? _substituteCurrentOf(next) : null;
          if (zeroCur && subCur == null) {
            // Filling in the blank row does not produce blood sugar
            try {
              await _persistInvalidInput(
                next,
                reason:
                    'current≈0（${next.rawCurrent}≤$zeroCurrentEps）and no replacement source'
                    '——Either the equipment cannot provide this during replenishment. seq Being plugged into ”current=0 Fill records」，'
                    'Either the device really returns near-zero current; check the original table. raw_current1 distinguishable'
                    '（Fill in the blank is always 0，The true low current is the original value of the device）',
              );
            } catch (e) {
              await _markRetry(
                next,
                'Exception frame failed to drop into library: $e',
              );
              return PipelineDrainResult(processed, true);
            }
            done();
            continue;
          }
          final double fedCurrent = zeroCur
              ? subCur!
              : (next.rawCurrent ?? 0.0);

          final GlucoseValue? out;
          try {
            final swPrime = Stopwatch()..start();
            await _ensureAlgorithmReady(next.wearId, params);
            primeMicros += swPrime.elapsedMicroseconds;
            final swAlgo = Stopwatch()..start();
            out = await _feedAlgorithm(
              srcData: fedCurrent,
              temperature: next.temperature ?? 0.0,
              ts: next.measureTime.toUtc().millisecondsSinceEpoch ~/ 1000,
              params: params,
            );
            algoMicros += swAlgo.elapsedMicroseconds;
          } catch (e) {
            await _markRetry(next, 'Algorithm exception: $e');
            return PipelineDrainResult(processed, true);
          }

          if (out == null) {
            await _markRetry(next, 'Algorithm returns null');
            return PipelineDrainResult(processed, true);
          }

          try {
            // prefetch full = Large batch replenishment, algorithm logs one by one [_bulkLogEvery] sampling；
            // Real-time collection pending Hengwei 1，There are many lines in the log。
            final bulk = pending.length >= _drainFetch;
            final swWrite = Stopwatch()..start();
            await _persistAndComplete(
              next,
              out,
              fedCurrent: fedCurrent,
              // The current is Excel From the top (the device is connected but there is no real signal), only local and not uploaded
              substituted: zeroCur,
              quietAlgoLog: bulk && processed % _bulkLogEvery != 0,
            );
            persistMicros += swWrite.elapsedMicroseconds;
          } catch (e) {
            await _markRetry(next, 'Failed to drop into warehouse: $e');
            return PipelineDrainResult(processed, true);
          }
          done();
          // Algorithm Sutra JNI Running on the main thread of the platform, feeding thousands of messages ANR，Every [_drainYieldEvery] yield one frame
          if (processed % _drainYieldEvery == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
        } catch (e) {
          await _markRetry(next, 'Abnormal water flow: $e');
          return PipelineDrainResult(processed, true);
        }
      }
    } finally {
      // Unified export placement: midway return（Broken link abort/Algorithm exception), write down the calculations that have been completed as usual
      await _flushWrites();
      // Segmented time-consuming log, midway return The path will also lead to
      if (processed > 0) {
        String per(int us) => (us / 1000 / processed).toStringAsFixed(2);
        final total = dedupMicros + primeMicros + algoMicros + persistMicros;
        DevLog.instance.add(
          'collect',
          'drain Segmented actual measurement $processed strip(millisecond/strip): '
              'Judgment inquiry ${per(dedupMicros)} | Baseline replay ${per(primeMicros)} | '
              'algorithm ${per(algoMicros)} | Dropped into the library ${per(persistMicros)} '
              '→ Timing coverage ${per(total)}，The actual total time taken is based on the caller’s segmented logs.',
        );
      }
    }
  }

  /// After calculating the records to be put into storage, write down the entire batch after processing one page.。
  final List<_PendingWrite> _writeBuffer = <_PendingWrite>[];

  /// Already occupied in the buffer `wear:whole minute`。You must first check it to make a judgment: the rows that have been saved cannot be found in the database.，
  /// The second item in the same minute will be treated as the first item and will be followed by one line.。
  final Set<String> _pendingMinuteKeys = <String>{};

  /// The maximum number of retries for the same frame. Occasional failures should be over after one or two failures. Trying more for deterministic failures will only lead to more rounds of queue blocking.。
  static const int _maxFrameRetry = 3;

  /// The upper limit of the number of items in a single batch is calculated continuously, and one frame is allowed across batches. Replay progress checkpoints (top bar lights up) and breadcrumb snapshots
  /// It is reused for all rhythms. Change the size so that short replays will not light up.。
  static const int _drainBatch = 50;

  /// drain The main loop’s yield frequency. give way itself 16ms/Second-rate，2 Thousands of press 50 Article 1: Let’s light this up 7 Second。
  static const int _drainYieldEvery = 200;

  /// The number of items prefetched from the original frame buffer at one time is also the batch size of the saved batch: prefetch one page, calculate one page, and drop the entire page at once.。
  ///
  /// The two must be the same number: the placement closes at the page boundary, and the buffer cannot grow by one page; if they are staggered, the next prefetch will
  /// The same batch that has not yet been placed on the market RAW The frame is fished out again, the same segment of data is fed to the algorithm twice, and two lines are dropped.。
  static const int _drainFetch = 500;

  /// Sampling interval of algorithm logs one by one when backfilling in large batches. abnormal/Try again/Logs that fail to be dropped into the database are not sampled。
  static const int _bulkLogEvery = 50;

  /// The cold start replay ran for so long and the top bar ”Data updating in progress” appeared before it was finished.」。
  static const int _primeBannerAfterMs = 1500;

  /// The algorithm is used for the first time or changed wear：uninit old、init New (calibration parameters into init，V1.2.4），
  /// Then the stateful algorithm replays the historical current in order to reconstruct the baseline.。
  Future<void> _ensureAlgorithmReady(
    int? wearId,
    GluCalcParameter params,
  ) async {
    final sameWear = _algorithmReady && _activeWearId == wearId;
    if (sameWear) return;
    // _primeHistory Replay the history from the library, and the rows in the buffer that have not been disked are not visible.，
    // Change wear If you are stuck in the middle of a page, the first half of the page will be missed. Please download it first and then play it again.。
    await _flushWrites();
    if (_algorithmReady) {
      BreadcrumbLog.write('algo uninit (Change wear)');
      await _algorithm.uninit();
      _algorithmReady = false;
    }
    // .so No border protection，init/dataProc is the most suspicious native Collapse point, entry and exit leaving traces
    BreadcrumbLog.write('algo init wearId=$wearId startTs=${params.startTs}');
    await _algorithm.init(params);
    _activeParams = params;
    // new init of .so The internal timeline is empty, and the feed reference is reset to zero，
    // Otherwise, replaying the first item will get the previous instance. _lastFedTs Calculate the false gap and fill it up immediately
    _lastFedTs = null;
    _lastFedCurrent = null;
    // During the playback period, feeding is done in batches (see [_recordFeed]），Add a snapshot at the end to stop the disk at the end of the replay
    _replaying = true;
    try {
      await _primeHistory(wearId, params);
    } finally {
      _replaying = false;
      if (_feedRing.isNotEmpty) {
        BreadcrumbLog.writeFeedSnapshot(_feedRing.join('\n'));
      }
    }
    _algorithmReady = true;
    _activeWearId = wearId;
  }

  /// The only outlet for feeding the algorithm: first fill in the missing grids on the timeline, then feed this article, and finally write down the feeding benchmark。
  /// Both real-time frames and cold start replay must go here, otherwise the two paths will feed each other.，.so The internal timeline does not match up。
  Future<GlucoseValue?> _feedAlgorithm({
    required double srcData,
    required double temperature,
    required int ts,
    required GluCalcParameter params,
  }) async {
    await _fillTimelineGap(ts, temperature, params);
    _recordFeed('REAL', srcData, temperature, ts);
    final out = await _algorithm.dataProc(
      srcData: srcData,
      temperature: temperature,
      ts: ts,
    );
    _lastFedTs = ts;
    _lastFedCurrent = srcData;
    return out;
  }

  /// Time axis filling: for every minute missing between the previous feed and this feed, the previous real current is used as the maintained value to fill in.。
  ///
  /// .so Depend on `ts - startTs` Position yourself on which grid you have reached. When there is a hole in the sequence, the grid will be empty but time will go by.
  /// If the preheat window boundary needs to use the full window history to build the baseline, unfilled memory will be read. SIGSEGV。The complement output is discarded directly，
  /// If the blood sugar is not stored or uploaded, the blood sugar cannot be released. All you need to supplement is .so The inner space。
  Future<void> _fillTimelineGap(
    int ts,
    double temperature,
    GluCalcParameter params,
  ) async {
    // The stateless engine has no internal windows and does not require bit filling.
    if (!_algorithm.isStateful) return;
    final last = _lastFedTs;
    final filler = _lastFedCurrent;
    // Book wear The first one has not been fed yet, and there is no previous grid and no retained value.
    if (last == null || filler == null || !filler.isFinite || filler <= 0) {
      return;
    }
    var missing = ((ts - last) / _sampleIntervalSec).round() - 1;
    if (missing <= 0) {
      return; // adjacent/Engraved at the same time/Backsliding: No compensation
    }
    final capped = missing > _maxGapFill;
    if (capped) missing = _maxGapFill;

    var filled = 0;
    for (var i = 1; i <= missing; i++) {
      final fillTs = last + i * _sampleIntervalSec;
      // The padding frame also observes the timeline gate, and cannot be fed with out-of-bounds values ​​due to padding. .so
      if (!_tsSane(fillTs, params.startTs)) continue;
      _recordFeed('FILL', filler, temperature, fillTs);
      await _algorithm.dataProc(
        srcData: filler,
        temperature: temperature,
        ts: fillTs,
      );
      filled++;
      // dataProc through JNI Run the main thread of the platform and make up for hundreds of sessions at a time. ANR
      if (filled % _drainBatch == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }
    if (filled > 0) {
      final note =
          'Algorithm Timeline Complement $filled strip(current=$filler keep value)'
          '${capped ? ' [The single limit has been reached $_maxGapFill，The earlier holes are not repaired]' : ''}';
      DevLog.instance.add('ble', note);
      BreadcrumbLog.write(note);
    }
  }

  /// Black box: record every feed .so Enter the parameters, and keep the latest [_feedRingSize] strip。
  /// native SIGSEGV It’s process level，Dart You can’t get anything after looking around, you can only rely on this sequence on the plate.
  /// take algo_validate Offline replay。
  void _recordFeed(String tag, double srcData, double temperature, int ts) {
    _feedRing.add(
      '$tag ts=$ts cur=${srcData.toStringAsFixed(4)} '
      'temp=${temperature.toStringAsFixed(1)}',
    );
    if (_feedRing.length > _feedRingSize) _feedRing.removeAt(0);
    _feedSinceFlush++;
    // One real-time frame per minute, one by one; replay thousands of frames one by one flush Will slow down the startup, press batch
    if (!_replaying || _feedSinceFlush >= _drainBatch) {
      _feedSinceFlush = 0;
      BreadcrumbLog.writeFeedSnapshot(_feedRing.join('\n'));
    }
  }

  final List<String> _feedRing = [];
  static const int _feedRingSize = 64;
  bool _replaying = false;
  int _feedSinceFlush = 0;

  /// Sampling beat: The transmitter reports one frame every minute (protocol V3.0），.so Click here to advance the internal window。
  static const int _sampleIntervalSec = 60;

  /// The upper limit of the number of single fill-in items（12 Hour). When the interruption is longer, the holding value has no reference meaning, and the value will be replenished until the upper limit is reached.。
  static const int _maxGapFill = 720;

  /// Hello .so Previous Timeline Access Control。
  ///
  /// .so Depend on `ts - startTs` Position internal baseline/Filter window without boundary protection: earlier than startTs yes
  /// Negative subscripts and too late are out of bounds, both SIGSEGV。equipment RTC failed to set up/0xD1 Writing time failed/firmware
  /// reset from 0 This kind of timestamp will be generated from the beginning, and out-of-bounds frames will be abnormal and will not proceed. .so。
  bool _isTimelineSane(BleFrameBufferRow frame, GluCalcParameter params) =>
      _tsSane(
        frame.measureTime.toUtc().millisecondsSinceEpoch ~/ 1000,
        params.startTs,
      );

  /// Naked value version of Timeline Access Control（[_primeHistory] Used to replay history lines, lines are not frames）。
  /// Only engines with internal windows are armed. Linear gateways are purely Dart Calculate, don’t look startTs。
  bool _tsSane(int ts, int startTs) {
    if (!_algorithm.isStateful) return true;
    // startTs Feeding him before he is in position is equivalent to letting him go .so take 1.7e9 When the second is offset, it must cross the boundary.
    if (startTs <= 0) return false;
    final elapsed = ts - startTs;
    return elapsed >= 0 && elapsed <= _maxElapsedSec;
  }

  /// The upper limit of the time span of the single wearing feeding algorithm: wearing period + 2 Day allowance (across time zones/clock trimming）。
  static const int _maxElapsedSec = (kWearLifetimeDays + 2) * 24 * 3600;

  /// Whether the frame value is limited (current exists and is limited, temperature must be limited if present)）。
  /// Is the current size ≤ Zero threshold is determined by frame-by-frame routing, not here。
  bool _isFiniteInput(BleFrameBufferRow frame) {
    final cur = frame.rawCurrent;
    if (cur == null || !cur.isFinite) return false;
    final temp = frame.temperature;
    if (temp != null && !temp.isFinite) return false;
    return true;
  }

  /// Replacement current for zero current frame: Press record_seq Pick Excel Corresponding value。
  /// No replacement source / No serial number / Return if no valid positive value can be obtained null，The caller falls into the abnormal line。
  double? _substituteCurrentOf(BleFrameBufferRow frame) {
    final lookup = _substituteCurrentForSeq;
    final seq = frame.recordSeq;
    if (lookup == null || seq == null) return null;
    final cur = lookup(seq);
    if (cur == null || !cur.isFinite || cur <= 0) return null;
    return cur;
  }

  /// [measureTime] of the whole minute epoch millisecond window [fromMs, fromMs+60s)。
  /// measure_time List epoch millisecond（DateTimeEpochConverter）。
  (int, int) _minuteWindow(DateTime measureTime) {
    final u = measureTime.toUtc();
    final fromMs = DateTime.utc(
      u.year,
      u.month,
      u.day,
      u.hour,
      u.minute,
    ).millisecondsSinceEpoch;
    return (fromMs, fromMs + 60000);
  }

  /// Should (wear, whole minute) The earliest blood glucose line that has been dropped (including abnormal lines), subsequent frames of the same minute will be judged as duplicates based on this。
  /// Match according to the whole minute window instead of exact seconds, otherwise repeated frames in the same minute and different seconds will be missed.。
  Future<UserlocalGlucoseDataRow?> _computedRowAt(
    int? wearId,
    DateTime measureTime,
  ) async {
    final (fromMs, toMs) = _minuteWindow(measureTime);
    return (_db.select(_db.userlocalGlucoseData)
          ..where(
            (t) =>
                t.wearId.equals(wearId ?? 0) &
                t.measureTime.isBiggerOrEqualValue(fromMs) &
                t.measureTime.isSmallerThanValue(toMs),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.measureTime)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Delete this (wear, whole minute) Placeholder rows (deleted from both tables) to make room for real data recalculation and rewriting。
  /// Only in ”occupying a seat” → ”True value” is called in this direction, and the true value will not be deleted by the true value.。
  Future<void> _deleteRowsAt(int? wearId, DateTime measureTime) async {
    final (fromMs, toMs) = _minuteWindow(measureTime);
    await _db.transaction(() async {
      await (_db.delete(_db.userlocalGlucoseData)..where(
            (t) =>
                t.wearId.equals(wearId ?? 0) &
                t.measureTime.isBiggerOrEqualValue(fromMs) &
                t.measureTime.isSmallerThanValue(toMs),
          ))
          .go();
      await (_db.delete(_db.userlocalGlucoseRawData)..where(
            (t) =>
                t.wearId.equals(wearId ?? 0) &
                t.measureTime.isBiggerOrEqualValue(fromMs) &
                t.measureTime.isSmallerThanValue(toMs),
          ))
          .go();
    });
  }

  /// Should (wear, whole minute) Whether the local original table already has rows: None raw = After changing the device, only the cloud blood glucose test is available, and the baseline needs to be rebuilt.。
  /// Also match according to the whole minute window to avoid triggering reconstruction twice in the second frame of the same minute and repeatedly feeding the algorithm to pollute the state.。
  Future<bool> _hasRawAt(int? wearId, DateTime measureTime) async {
    final (fromMs, toMs) = _minuteWindow(measureTime);
    final row =
        await (_db.select(_db.userlocalGlucoseRawData)
              ..where(
                (t) =>
                    t.wearId.equals(wearId ?? 0) &
                    t.measureTime.isBiggerOrEqualValue(fromMs) &
                    t.measureTime.isSmallerThanValue(toMs),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Baseline reconstruction of cloud replenishment rows (machine replacement scenario): feeding algorithm discards output + fill in a line raw for restart and replay，
  /// Do not touch the display table. current routing with drain The main path has the same diameter and no feeding raw Still in the original order。
  Future<void> _feedAndRecordRaw(
    BleFrameBufferRow frame,
    GluCalcParameter params,
  ) async {
    double? fed;
    final cur = frame.rawCurrent;
    // The replay path has the same access control as the main path, and the out-of-bounds timestamp is also not included. .so
    if (_algorithm.isStateful &&
        _isFiniteInput(frame) &&
        _isTimelineSane(frame, params)) {
      // .so/mock All require init→dataProc order
      await _ensureAlgorithmReady(frame.wearId, params);
      final zeroCur = (cur ?? 0) <= zeroCurrentEps;
      final subCur = zeroCur ? _substituteCurrentOf(frame) : null;
      if (!zeroCur) {
        fed = cur;
      } else if (subCur != null) {
        fed = subCur;
      }
      if (fed != null) {
        await _feedAlgorithm(
          srcData: fed,
          temperature: frame.temperature ?? 0.0,
          ts: frame.measureTime.toUtc().millisecondsSinceEpoch ~/ 1000,
          params: params,
        );
      }
    }
    await _db
        .into(_db.userlocalGlucoseRawData)
        .insert(
          UserlocalGlucoseRawDataCompanion.insert(
            measureTime: frame.measureTime,
            userId: Value(_ownerUserId),
            accountId: Value(_ownerAccountId),
            wearId: Value(frame.wearId),
            recordSeq: Value(frame.recordSeq),
            rawCurrent1: Value(fed ?? cur),
            temperature1: Value(frame.temperature),
            glucoseValue1: const Value(null),
            voltageValue: Value(
              frame.voltage == null
                  ? null
                  : MedicalDecimal(frame.voltage!.toString()),
            ),
            warmupFlag: Value(_isWarmup(frame.measureTime) ? '1' : '0'),
            abnormalFlag: Value(fed != null ? '0' : '1'),
            createTime: Value(DateTime.now().toUtc()),
          ),
        );
  }

  /// Duplicate frames in same timeline: original frame remains buffer Milestone DONE，Don’t feed the algorithm, don’t write the display table。
  Future<void> _completeDuplicate(BleFrameBufferRow frame) async {
    await (_db.update(
      _db.bleFrameBuffer,
    )..where((t) => t.id.equals(frame.id))).write(
      const BleFrameBufferCompanion(status: Value(FrameBufferStatus.done)),
    );
    DevLog.instance.add(
      'collect',
      'Duplicate frames in the same timeline are only saved and are not counted. seq=${frame.recordSeq} ts=${frame.measureTime.toUtc()}',
    );
  }

  /// Invalid frame falls abnormal row (two tables have the same transaction): blood sugar/algoK/algoB Complete null、abnormal='1'、status Leave blank
  /// （Statistics only take status='1'），Then mark the frame DONE。
  ///
  /// [reason] The record is blocked by which access control: the three paths of abnormal value, timestamp out of bounds, and zero current filling are left behind.
  /// It’s exactly the same. I can’t tell the difference without remembering the reason.。
  Future<void> _persistInvalidInput(
    BleFrameBufferRow frame, {
    required String reason,
  }) async {
    // Invalid frames during the warm-up period must also be marked, otherwise the reading side can only rely on the activation time to make a final judgment, and the historical wearing period cannot be recognized.，
    // will appear as a blank line in the blood glucose data list.
    final warmupFlag = _isWarmup(frame.measureTime) ? '1' : '0';
    DevLog.instance.add(
      'collect',
      'Invalid frame falling exception line(The chart will be blank,but seq continuous): seq=${frame.recordSeq} '
          'ts=${frame.measureTime.toUtc()} current=${frame.rawCurrent} '
          'temperature=${frame.temperature} → $reason',
    );
    await _db.transaction(() async {
      await _db
          .into(_db.userlocalGlucoseData)
          .insert(
            UserlocalGlucoseDataCompanion.insert(
              userId: _ownerUserId,
              accountId: _ownerAccountId,
              wearId: frame.wearId ?? 0,
              measureTime: frame.measureTime,
              recordSeq: Value(frame.recordSeq),
              glucoseValue1: const Value(null),
              status: const Value(null),
              fiveMinFlag: const Value('0'),
              warmupFlag: Value(warmupFlag),
              abnormalFlag: const Value('1'),
              uploadFlag: const Value('0'),
              createTime: Value(DateTime.now().toUtc()),
            ),
          );
      await _db
          .into(_db.userlocalGlucoseRawData)
          .insert(
            UserlocalGlucoseRawDataCompanion.insert(
              measureTime: frame.measureTime,
              userId: Value(_ownerUserId),
              accountId: Value(_ownerAccountId),
              wearId: Value(frame.wearId),
              recordSeq: Value(frame.recordSeq),
              rawCurrent1: Value(frame.rawCurrent),
              temperature1: Value(frame.temperature),
              glucoseValue1: const Value(null),
              voltageValue: Value(
                frame.voltage == null
                    ? null
                    : MedicalDecimal(frame.voltage!.toString()),
              ),
              warmupFlag: Value(warmupFlag),
              abnormalFlag: const Value('1'),
              createTime: Value(DateTime.now().toUtc()),
            ),
          );
      await (_db.update(
        _db.bleFrameBuffer,
      )..where((t) => t.id.equals(frame.id))).write(
        const BleFrameBufferCompanion(status: Value(FrameBufferStatus.done)),
      );
    });
  }

  /// cold start/Change wear Post-rebuild stateful .so internal baseline: sequence this wear Historical current refeed dataProc，
  /// No drop-in, no callback, discard output。App After restart .so The status is lost. If the cold feed is not replayed, the range value will be exceeded.。
  Future<void> _primeHistory(int? wearId, GluCalcParameter params) async {
    if (!_algorithm.isStateful) return;
    final history =
        await (_db.select(_db.userlocalGlucoseRawData)
              ..where(
                (t) => wearId == null
                    ? t.wearId.isNull()
                    : t.wearId.equals(wearId),
              )
              // In ascending order of measurement time, and [_drainInternal] consistent：record_seq Will be reset due to firmware/wrap around
              // To reverse the order of time, press seq Platoon feeds a sequence that goes backwards in time
              ..orderBy([
                (t) => OrderingTerm(expression: t.measureTime),
                (t) => OrderingTerm(expression: t.recordSeq),
                (t) => OrderingTerm(expression: t.id),
              ]))
            .get();
    // Wearing thousands of them for many days, one by one .so It will take a few minutes. During this time, the blood sugar on the home page will not move, and there should be a prompt on the top bar.。
    // Shares the top bar with disconnection replenishment: when the replenishment is on, only the numbers are updated and clearing is under its control, otherwise this function lights up
    // And in finally Clear it. Run enough [_primeBannerAfterMs] Only bright, small batches do not flash banners。
    final total = history.length;
    final sw = Stopwatch()..start();
    var ownsBanner = false;
    var processed = 0;
    var fed = 0;
    try {
      for (final r in history) {
        processed++;
        // raw_current1 What is stored is the actual input value at that time. Feeding back according to the original sequence can reproduce the algorithm state.；
        // Only skip filling blank lines in the official version (current 0、no blood sugar）
        final cur = r.rawCurrent1;
        if (cur == null || !cur.isFinite || cur <= zeroCurrentEps) continue;
        final temp = r.temperature1;
        if (temp != null && !temp.isFinite) continue;
        final ts = r.measureTime.toUtc().millisecondsSinceEpoch ~/ 1000;
        // Out of bounds timestamp（RTC Not set/firmware reset from 0 Starting from/historical dirty line) will make .so negative subscript segfault。
        // Skip without interrupting playback, the skipped grid is [_fillTimelineGap] Fill back with retained value。
        if (!_tsSane(ts, params.startTs)) {
          DevLog.instance.add(
            'ble',
            'Replay skips out-of-bounds timestamp lines seq=${r.recordSeq} ts=$ts',
          );
          continue;
        }
        await _feedAlgorithm(
          srcData: cur,
          temperature: temp ?? 0.0,
          ts: ts,
          params: params,
        );
        fed++;
        // dataProc through JNI Run the main thread and wear tens of thousands of frames for many days for continuous feeding sessions ANR
        if (fed % _drainBatch == 0) {
          if (!ownsBanner &&
              BackfillStatus.etaMinutes.value == null &&
              sw.elapsedMilliseconds >= _primeBannerAfterMs) {
            ownsBanner = true;
          }
          if (ownsBanner || BackfillStatus.etaMinutes.value != null) {
            BackfillStatus.showMeasured(
              sw: sw,
              done: processed,
              remaining: total - processed,
              kind: 'replay',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }
    } finally {
      if (ownsBanner) BackfillStatus.etaMinutes.value = null;
    }
  }

  /// The algorithm output goes into the write buffer, consisting of [_flushWrites] Write the blood glucose master table in the same transaction + Original data table and label the frame DONE；
  /// Play in the preheat window warmup_flag='1' Not explicit。
  /// [fedCurrent] is the current actually fed to the algorithm, falling raw_current1 For restarting replay to reproduce the same input sequence。
  /// [substituted] means that the current is Excel It comes from the top (the device is connected but the sensor has no real signal). This kind of business
  /// Only keep local and do not upload: it is marked `abnormal_flag=0`，The uploaded data cannot be distinguished from the real measurement, and the backend will see it.
  /// The device has no data but always has original data。
  Future<void> _persistAndComplete(
    BleFrameBufferRow frame,
    GlucoseValue out, {
    required double fedCurrent,
    bool substituted = false,
    bool quietAlgoLog = false,
  }) async {
    final isWarmup = _isWarmup(frame.measureTime);
    final warmupFlag = isWarmup ? '1' : '0';
    // .so Will vomit under malformed input ±Infinity/NaN：blood sugar/algoK/algoB All non-finite fall null mark abnormal、
    // status Leave blank。V1.2.4 caliber algoK=Effective sensitivity(sensitivity_used)、algoB=Input parameter intercept。
    final valueOk = out.value.isFinite;
    final double? safeValue = valueOk ? out.value : null;
    final String? status = valueOk ? _statusFor(out.value) : null;
    final double? safeAlgoK = out.sensitivityUsed.isFinite
        ? out.sensitivityUsed
        : null;
    final double? ib = _activeParams?.intercept;
    final double? safeAlgoB = (ib != null && ib.isFinite) ? ib : null;
    final abnormalFlag = valueOk ? '0' : '1';

    // Check these three things to check your blood sugar level: Feed .so of current/temperature、init calibration、.so Taking sensitivity and filter value。
    // Press when replenishing large quantities [_bulkLogEvery] Sampling, otherwise the log itself becomes a bottleneck。
    final p = _activeParams;
    if (!quietAlgoLog) {
      DevLog.instance.add(
        'algo',
        'blood sugar=${valueOk ? out.value.toStringAsFixed(4) : "invalid(${out.value})"} '
            '← current=${fedCurrent.toStringAsFixed(2)}nA '
            'temperature=${frame.temperature?.toStringAsFixed(1)}℃ '
            'seq=${frame.recordSeq} ts=${frame.measureTime.toUtc()}\n'
            '  engine=${_algorithm.runtimeType}\n'
            '  Calibration input parameters: k/slope=${p?.slope} b/intercept=${p?.intercept} '
            'cgmBase/paramBGMbase=${p?.paramBGMbase} '
            'L3=${p?.paramL3} G3=${p?.paramG3} L4=${p?.paramL4} G4=${p?.paramG4} '
            'L5=${p?.paramL5} G5=${p?.paramG5} startTs=${p?.startTs}\n'
            '  .sooutput: sensitivity_used/algoK=${out.sensitivityUsed} '
            'base=${out.currentBase} iir=${out.currentIirFilter} '
            'median=${out.currentMedianFilter} idx=${out.idx} '
            'kalmandayQ/R=${out.dayKalmanParamQ}/${out.dayKalmanParamR} '
            'nightQ/R=${out.nightKalmanParamQ}/${out.nightKalmanParamR}',
      );
    }

    // Deduplication has been completed before feeding the algorithm. This must be the first item at this time. It can be directly dropped into the database without deleting old items.。measure_time use
    // Device precise measurement time (not rounded to whole minutes), list/curve/The upload time is consistent with the device。
    final mt = frame.measureTime.toUtc();
    final minute = DateTime.utc(mt.year, mt.month, mt.day, mt.hour, mt.minute);
    final wearId = frame.wearId ?? 0;

    // Per whole point boundary 5 Count in minutes five_min_glucose=(This round5Maximum bar+smallest)/2
    final fiveMin = valueOk
        ? await _fiveMinFor(wearId, minute, out.value)
        : (flag: '0', glucose: null as MedicalDecimal?);

    // Do not write directly to the library, advance the buffer, and then write the entire batch to disk after one page is processed.。LinkActivity / _onComputed callback
    // exist [_flushWrites] Triggered after placing the order, these lines must be found in the library when uploading. Real-time collection only
    // One frame, followed by flush，Alerts will not be delayed。
    _writeBuffer.add(
      _PendingWrite(
        frameId: frame.id,
        minuteKey: _minuteKeyOf(frame.wearId, frame.measureTime),
        wearId: wearId,
        minuteMs: minute.millisecondsSinceEpoch,
        glucose: safeValue,
        frame: frame,
        out: out,
        dataRow: UserlocalGlucoseDataCompanion.insert(
          userId: _ownerUserId,
          accountId: _ownerAccountId,
          wearId: wearId,
          measureTime: mt,
          recordSeq: Value(frame.recordSeq),
          glucoseValue1: Value(safeValue),
          status: Value(status),
          fiveMinFlag: Value(fiveMin.flag),
          fiveMinGlucose: Value(fiveMin.glucose),
          warmupFlag: Value(warmupFlag),
          abnormalFlag: Value(abnormalFlag),
          // '2' = Local backup data, never uploaded
          uploadFlag: Value(substituted ? '2' : '0'),
          createTime: Value(DateTime.now().toUtc()),
        ),
        rawRow: UserlocalGlucoseRawDataCompanion.insert(
          measureTime: mt,
          userId: Value(_ownerUserId),
          accountId: Value(_ownerAccountId),
          wearId: Value(frame.wearId),
          recordSeq: Value(frame.recordSeq),
          rawCurrent1: Value(fedCurrent),
          temperature1: Value(frame.temperature),
          glucoseValue1: Value(safeValue),
          voltageValue: Value(
            frame.voltage == null
                ? null
                : MedicalDecimal(frame.voltage!.toString()),
          ),
          warmupFlag: Value(warmupFlag),
          abnormalFlag: Value(abnormalFlag),
          algoK: Value(safeAlgoK),
          algoB: Value(safeAlgoB),
          createTime: Value(DateTime.now().toUtc()),
        ),
      ),
    );
    _pendingMinuteKeys.add(_writeBuffer.last.minuteKey);
    // The order will be closed uniformly at [_drainInternal] Page boundary, the buffer cannot grow by one page, and there will be space to deduct when it fails. processed、work stoppage
  }

  /// `wear:whole minute`，The judgment weight is shared with the buffer index, and the caliber must be the same as [_computedRowAt] The whole minute window is consistent。
  String _minuteKeyOf(int? wearId, DateTime measureTime) {
    final (fromMs, _) = _minuteWindow(measureTime);
    return '${wearId ?? 0}:$fromMs';
  }

  /// Put the saved records into the database at once: insert into two tables + frame mark DONE，All in one transaction。
  ///
  /// The result is the same as DONE The mark must be the same as the transaction: the result is written but not marked DONE There will be duplicate rows in the next round, marked DONE If the result data is not written, it will be lost.。
  ///
  /// Return successfully 0；If the entire batch fails, the number of entries in this batch will be returned (the frames have all been marked). RETRY），The caller deducts accordingly processed and stop work。
  /// Never throw yourself away, and [_markRetry] It’s the same as ending in failure。
  Future<int> _flushWrites() async {
    if (_writeBuffer.isEmpty) return 0;
    final batch = List<_PendingWrite>.of(_writeBuffer);
    _writeBuffer.clear();
    _pendingMinuteKeys.clear();
    try {
      // Explicitly wrap one layer transaction，not dependent on batch The internal implementation of guarantees atomicity
      await _db.transaction(() async {
        await _db.batch((b) {
          for (final w in batch) {
            b.insert(_db.userlocalGlucoseData, w.dataRow);
            b.insert(_db.userlocalGlucoseRawData, w.rawRow);
            b.update(
              _db.bleFrameBuffer,
              const BleFrameBufferCompanion(
                status: Value(FrameBufferStatus.done),
              ),
              where: (t) => t.id.equals(w.frameId),
            );
          }
        });
      });
    } catch (e) {
      // Roll back the entire batch. The algorithm has already eaten this batch, and refeeding it directly is equivalent to feeding the same piece of data twice, forcing it to refeed in the next round. init
      // And replay the history from the library to bring the algorithm state back to be consistent with the library. frame unified standard RETRY，not stay RAW Block the queue。
      _algorithmReady = false;
      DevLog.instance.add(
        'collect',
        'Failed to save the batch and drop it into the inventory ${batch.length} strip → Whole batch rollback, frame marking RETRY；'
            'The algorithm has already fed this batch, forcing the next round to restart init Replay history to reconstruct baseline: $e',
      );
      try {
        await _db.batch((b) {
          for (final w in batch) {
            b.update(
              _db.bleFrameBuffer,
              BleFrameBufferCompanion(
                status: const Value(FrameBufferStatus.retry),
                retryCount: Value(w.frame.retryCount + 1),
                lastError: Value(
                  'Failed to save the batch and drop it into the inventory: $e',
                ),
              ),
              where: (t) => t.id.equals(w.frameId),
            );
          }
        });
      } catch (e2) {
        DevLog.instance.add(
          'collect',
          'mark RETRY fail(frame stay RAW，Come back next time): $e2',
        );
      }
      return batch.length;
    }
    // Callback only after the order is placed: these lines must be found in the library for uploading, and the alarm judgment is the same.。
    for (final w in batch) {
      // Remember the local time instead of measureTime：The firmware timestamp is calculated based on the serial number and will lag behind the real time. Using it to judge will result in false alarms.
      if (w.glucose != null) LinkActivity.markComputed(DateTime.now());
      // Bypass observation, error swallowing does not affect the main link
      final cb = _onComputed;
      if (cb != null) {
        try {
          cb(w.frame, w.out);
        } catch (_) {}
      }
    }
    return 0;
  }

  /// effectiveness char：'1'=efficient(2.2~27.8 Machine effective range) / '0'=too low(<2.2) / '2'=too high(>27.8)。
  String _statusFor(double v) {
    if (v < 2.2) return '0';
    if (v > 27.8) return '2';
    return '1';
  }

  /// One round of five minutes, divided into rounds according to the whole minute boundary (equipment seq May not be continuous and cannot be pressed seq minutes): the minute at the end of the round
  /// set five_min_flag=1，five_min_glucose=(inside the window glucose maximum+smallest)/2，the remaining flag='0'。
  Future<({String flag, MedicalDecimal? glucose})> _fiveMinFor(
    int wearId,
    DateTime minute,
    double value,
  ) async {
    // Integer index %5==4 = No. of this round 5 minutes, window [this minute-4min, this minute]
    final minuteIdx = minute.toUtc().millisecondsSinceEpoch ~/ 60000;
    if (minuteIdx % 5 != 4) {
      return (flag: '0', glucose: null);
    }
    // Before this round 4 Minutes logged + This article（measure_time live epoch millisecond）
    final fromMs = minute
        .subtract(const Duration(minutes: 4))
        .millisecondsSinceEpoch;
    final minuteMs = minute.millisecondsSinceEpoch;
    final prev =
        await (_db.select(_db.userlocalGlucoseData)..where(
              (t) =>
                  t.wearId.equals(wearId) &
                  t.measureTime.isBiggerOrEqualValue(fromMs) &
                  t.measureTime.isSmallerThanValue(minuteMs),
            ))
            .get();
    final vals = <double>[
      ...prev.map((r) => r.glucoseValue1).whereType<double>(),
      // Before this round 4 Minutes may still be stored in the buffer but not placed in the disk. Just checking the database will miss them and the average calculation will be biased.
      for (final w in _writeBuffer)
        if (w.wearId == wearId &&
            w.minuteMs >= fromMs &&
            w.minuteMs < minuteMs &&
            w.glucose != null)
          w.glucose!,
      value,
    ];
    final mid = (vals.reduce(math.max) + vals.reduce(math.min)) / 2;
    return (flag: '1', glucose: MedicalDecimal(mid.toStringAsFixed(2)));
  }

  /// Mark for retry. It will never throw itself: it is the closing point of all failed paths. Throwing it again is equivalent to confiscating the opening.。
  Future<void> _markRetry(BleFrameBufferRow frame, String reason) async {
    try {
      await _markRetryImpl(frame, reason);
    } catch (e) {
      DevLog.instance.add(
        'collect',
        'mark RETRY fail(frame stay RAW，Come back next time): $e',
      );
    }
  }

  Future<void> _markRetryImpl(BleFrameBufferRow frame, String reason) async {
    await (_db.update(
      _db.bleFrameBuffer,
    )..where((t) => t.id.equals(frame.id))).write(
      BleFrameBufferCompanion(
        status: const Value(FrameBufferStatus.retry),
        retryCount: Value(frame.retryCount + 1),
        lastError: Value(reason),
      ),
    );
  }

  /// Warm-up judgment（V1.2.4 The algorithm does not return stage）：The measurement time falls on [activation time, activation+kWearWarmupMinutes)
  /// This is the preheating period; none startTs（not yet init）does not count as warm-up。
  ///
  /// The lower bound cannot be saved: the backend does not provide activateTime hour `saveActivation` retreat into the present，startTs that is
  /// At the time of login, the historical frames restored by the device are all earlier than it; the linear engine does not look at it startTs Follow the plan and it will fall, only the upper realm will be judged
  /// Type the entire segment of real blood sugar into '1'，The reading side shall be subject to the standard（[WarmupFilter]）It will never be displayed。
  bool _isWarmup(DateTime measureTime) {
    final start = _activeParams?.startTs ?? 0;
    if (start == 0) return false;
    final ts = measureTime.toUtc().millisecondsSinceEpoch ~/ 1000;
    return ts >= start && ts < start + SdkTuning.warmupMinutes * 60;
  }

  /// Ending: First uninit The algorithm waits for the serial queue to finish。
  ///
  /// `cgmAlgoV1` It is a process-level singleton and pipeline Create a new one every time the collection is restarted: not here uninit，
  /// new pipeline meeting init The ones that were not uninstalled last time .so status，C Side buffering stacks up with the number of restarts。
  Future<void> dispose() async {
    if (_algorithmReady) {
      try {
        await _executor.run(() async {
          BreadcrumbLog.write('algo uninit (pipeline dispose)');
          await _algorithm.uninit();
          _algorithmReady = false;
          _activeWearId = null;
          _activeParams = null;
          _lastFedTs = null;
          _lastFedCurrent = null;
        });
      } catch (_) {
        // algorithm/If the channel is abnormal, the release will not be blocked and the queue will be closed as usual.
      }
    }
    await _executor.close();
  }
}

/// A record that has been calculated and is waiting for batch approval and storage.。
///
/// with [frame] and [out] It is to be triggered after placing the order. `_onComputed`（upload/Alarm），
/// The row is not in the library during the batch collection period. Calling back in advance will prevent uploading and finding things.。
class _PendingWrite {
  const _PendingWrite({
    required this.frameId,
    required this.minuteKey,
    required this.wearId,
    required this.minuteMs,
    required this.glucose,
    required this.frame,
    required this.out,
    required this.dataRow,
    required this.rawRow,
  });

  /// To bid DONE frame id。
  final int frameId;

  /// `wear:whole minute`，Judgment of heavy index application。
  final String minuteKey;

  final int wearId;

  /// Starting from the whole minute epoch milliseconds, for five-minute windows。
  final int minuteMs;

  /// Effective blood glucose level；null = Abnormal rows (not participating in the five-minute average, not counting ”calculated data”」）。
  final double? glucose;

  final BleFrameBufferRow frame;
  final GlucoseValue out;

  final UserlocalGlucoseDataCompanion dataRow;
  final UserlocalGlucoseRawDataCompanion rawRow;
}
