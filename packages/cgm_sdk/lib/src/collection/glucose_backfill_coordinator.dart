import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/status/backfill_status.dart';
import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/domain/cgm_ble_gate.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';
import 'package:cgm_sdk/src/collection/cgm_replay_dataset.dart';

import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';

/// This generation’s ”serial number” ↔ moment anchor：`ts(sn) = tsSec + (sn - sn0) × period`。
class _GenAnchor {
  const _GenAnchor(this.sn, this.tsSec);

  final int sn;
  final int tsSec;

  int tsOf(int sn0, int periodSec) => tsSec + (sn0 - sn) * periodSec;
  int snOf(int ts, int periodSec) => sn + ((ts - tsSec) / periodSec).round();
}

/// Disconnect/Gap filling arrangement after reconnection。
///
/// The gap is found based on time, and the number is addressed based on the device serial number of this generation. The two must be separated: the frame timestamp is globally monotonic and reliable.；
/// equipment SN Change the generation every time it is cleared. There will be multiple generations of serial numbers mixed in the same sensor library. Cross-generation ones cannot be used.
/// `max(record_seq)+1` Be the starting point, otherwise the segments that are really lacking in this generation will not be requested even once.。
///
/// This generation anchor point is pushed from local data: Press measure_time Scan in ascending order, the last line ”the serial number is not increasing” is
/// The first line of this generation, its `(seq, ts)` i.e. anchor point, reuse device `latestSn` Cross-check; if it doesn’t match, it will degenerate into
/// from SN=1 Pull the entire segment and drop it into the library by frame with its own timestamp。
///
/// Number priority 0xD3 Batch Pull (Protocol 4.2），Retirement due to incomplete flow 0xD4 Item by item; after receiving the batch package, use the real
/// `(sn, ts)` Calibrate anchor points. Can’t get or current≈0 Used when [CgmReplayDataset] Cover; no official version
/// Excel，Plug in a current=0 The gap-filling record keeps the timeline continuous (blank-filling fails in abnormal lines, blood sugar does not come out)）。
///
/// Must be restored in real time 0xB0 Run before consumption: feed the algorithm ts Must be monotonically increasing。
class GlucoseBackfillCoordinator {
  GlucoseBackfillCoordinator({
    required this.db,
    required this.gate,
    required this.pipeline,
    required this.dataset,
    this.zeroCurrentEps = 0.05,
    this.maxBackfill = 32400,
    this.maxMultiAttempts = 2,
    this.maxSingleReads = 60,
    this.recordPeriod = const Duration(minutes: 1),
    this.settleAfterBrokenStream = const Duration(seconds: 2),
  });

  final CgmDatabase db;
  final CgmBleGate gate;
  final GlucosePipelineRepository pipeline;

  /// Excel Full data set, only in the development stage。null=Official version: only pay attention to the data, if you can’t get it, insert one
  /// current=0 Fill in the blank records, do not fill in false blood sugar。
  final CgmReplayDataset? dataset;

  /// current ≤ This value is regarded as no real current: the sensor operating current is positive, and a constant negative value is also no signal.。
  final double zeroCurrentEps;

  /// The upper limit of a single complement. frame period 60 Second/strips (protocol default，0xC4 cycle=60），15 Day wearing period
  /// = 21600 Article, stay 1.5 times margin. If the limit is exceeded, it will not be silently truncated and the log will be dropped.。
  final int maxBackfill;

  /// 0xD3 Maximum number of batch pull attempts: failed/If the stream is incomplete, resend first. 0xD3，If it still doesn’t work, then retreat 0xD4，
  /// Each resend starts from the current first one that is still missing. SN rise。0xD4 about 1.1 Second/strip，8000+ It takes more than two hours。
  final int maxMultiAttempts;

  /// 0xD3 Allowed after resending is exhausted 0xD4 The maximum number of gaps to be filled one by one。
  ///
  /// 0xD4 about 1.1 Second/strip，60 treaty 1 minute. Beyond this number, only consecutive prefixes have been received, leaving gaps
  /// Save it for next time 0xD3 Pull the entire paragraph; you cannot fill in the entire paragraph. Once the gap is filled in, this paragraph will never ask for the true value again.。
  final int maxSingleReads;

  /// Recording period: Current generation ”serial number” ↔ ”Time” conversion step, which is also the timestamp step of blank filling records.。
  final Duration recordPeriod;

  /// The number of batches of dropped frames。500 One transaction per transaction: No matter how large the memory and single lag are, the transaction overhead will not be saved no matter how small it is.。
  static const int _ingestBatch = 500;

  /// 0xD3 After the stream is interrupted, wait silently before sending the next instruction to the device.。
  ///
  /// The protocol requires that no requests be made to the CGM Issue instructions. Judgment of flow depends only on「5 No frame received for seconds」（[RealCgmBleGate]
  /// idle timeout), there is no guarantee that the device has stopped sending, please stop and try again. 0xD3 or withdraw 0xD4。
  final Duration settleAfterBrokenStream;

  /// The number of gaps at the end of the current round when none of them have been requested，0 It means that everything you need in this round has arrived.。
  ///
  /// Only count quilts「0xD4 Devices that have been blocked by ”Maximum one by one” or ”Link outage” and can be requested again next time; equipment FLASH
  /// Those that are not there in the first place and have been filled in are not counted. Reconnecting them indefinitely will only freeze and drag down the real-time data.。
  ///
  /// >0 The caller should disconnect and clean up the status、10 Reconnect and rerun a round of synchronization after seconds, instead of recording this round as
  /// Completed, see `GlucoseCollectionRunner._startLiveDevice`。
  int lastUnresolvedGaps = 0;

  /// Fill the disconnection gap and return the actual number of filled items; there is no gap/Device not measured returns 0。
  /// [activeTime]=Wearing activation time, time earlier than it does not belong to this wear and will not be replenished.。
  /// [knownState]=What the caller just read 0xE3 As a result, after passing it, I no longer read it myself: the protocol requires connecting 6 within seconds
  /// issue 0xD3，The firmware read command has a second-level response delay. Reading it more than once will eat up most of the budget.。
  Future<int> backfill({
    required int wearId,
    required GluCalcParameter params,
    required DateTime activeTime,
    ({bool measuring, int measuredSec, int latestSn})? knownState,
  }) async {
    lastUnresolvedGaps = 0; // Independent settlement for each round
    final state = knownState ?? await gate.readMeasureState();
    if (!state.measuring || state.latestSn <= 0) return 0;
    final latestSn = state.latestSn;
    final periodSec = recordPeriod.inSeconds;
    final activeSec = activeTime.toUtc().millisecondsSinceEpoch ~/ 1000;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    // Local timeline: local collection line (with device serial number）+ Already raw I won’t leave even a few minutes BLE。
    // 「Do you want to go to the device this minute? Click raw Judgment or not: Cloud supplement only has blood sugar but no current，
    // The algorithm baseline cannot be reconstructed, so we still have to ask for it。
    final rows = await _localRows(wearId, sinceSec: activeSec - periodSec);
    // raw The table is retrieved in full at once, and the following two criteria are shared.
    final rawRows = await _rawRows(wearId, sinceSec: activeSec - periodSec);
    final have = <int>{for (final r in rows) r.tsSec ~/ 60}
      ..addAll(rawRows.map((r) => r.tsSec ~/ 60));
    var anchor = _genAnchorOf(rows, latestSn);

    // 「this SN Is there any locally?” Click SN Compare by itself, do not push the time linearly according to the anchor point to compare the minutes：measure_time
    // is the moment of truth (see [DeviceClockSkew]），There is a gap on the real axis where the equipment stopped, and linear calculation will
    // after the shutdown SN All misjudgments lead to shortcomings, and every time you reconnect, you will lose one round. 0xD3。The same number across generations can be avoided by only collecting the lines after the anchor point.。
    // I received it but clicked ”Same” (wear,whole minute) Only take the first frame that is judged to be a duplicate, and leave no rows in both business tables.
    // （[GlucosePipelineRepository._completeDuplicate] Just mark the frame DONE），So we have to count
    // line in the framebuffer, otherwise this SN There will always be a gap。
    final bufRows = await _bufferedRows(
      wearId,
      sinceSec: activeSec - periodSec,
    );
    final haveSns = anchor == null
        ? const <int>{}
        : <int>{
            for (final r in rows)
              if (r.tsSec >= anchor.tsSec) r.seq,
            for (final r in rawRows)
              if (r.tsSec >= anchor.tsSec) r.seq,
            for (final r in bufRows)
              if (r.tsSec >= anchor.tsSec) r.seq,
          };
    var planned = anchor == null
        ? null
        : _missingSns(
            anchor,
            latestSn,
            haveSns,
            activeSec: activeSec,
            periodSec: periodSec,
          );
    if (planned != null) {
      if (planned.isEmpty) {
        return 0; // No gap, one piece BLE No orders were issued
      }
      _logUnreachable(
        anchor!,
        have,
        activeSec: activeSec,
        periodSec: periodSec,
      );
      planned = _capOldest(planned);
    }

    final startSn = planned?.first ?? 1;
    // If the added line is earlier than the ”latest one that has been calculated”, the blood sugar after that period will always maintain the false current value.
    // Calculated from the baseline, you have to recalculate and write back from the starting point of the gap after completion.。
    final maxComputedBeforeSec = await _maxComputedTsSec(wearId);
    int? minFilledSec;
    var filled = 0;
    var gapFilled = 0;
    // The progress of the top bar must be maintained until drain Disappears only after completion: the feeding loop only falls into the original frame buffer, and the real time-consuming process is drain
    // Feed algorithm one by one+Dropped into the library. The number of minutes is converted and decreased according to the actual measured rate at the current stage, and the starting value is roughly estimated.。
    final total = planned?.length ?? (latestSn - startSn + 1);
    BackfillStatus.etaMinutes.value = _etaMinutes(total);
    DevLog.instance.add(
      'collect',
      planned != null
          ? 'cover: Anchor point of this generation SN=${anchor!.sn}@${_iso(anchor.tsSec)}，'
                'shortage according to time $total strip → SN[$startSn..$latestSn]'
          : 'cover: Unable to push trusted local anchor point (device latestSn=$latestSn）→ '
                'According to Party A’s caliber from SN=1 The whole section is pulled, and the time stamp of the frame shall prevail.',
    );
    try {
      // 0xD4 Each line must be crossed 2 indivual BLE For connection events, the connection interval is its ceiling. Replenishing window to increase throughput
      // link，finally Switch back to power saving mode。
      await gate.setFastLink(true);

      // First 0xD3 Batch pull (one request to the device to push the gap through streaming), failed/The stream is incomplete and the first one from the current one is still missing
      // of SN Re-pull, collected merge retained，[maxMultiAttempts] Retreat only after failure 0xD4。
      Map<int, GlucoseRecord>? batch;
      var batchComplete = false;
      final pullSw = Stopwatch()..start();
      for (var attempt = 1; attempt <= maxMultiAttempts; attempt++) {
        final gapFrom =
            _firstStillMissing(batch, planned) ??
            (batch == null ? startSn : null);
        if (gapFrom == null) break; // Already collected
        // From the second time onwards, it means that the last stream was interrupted (the end frame was not received). Let the link quiet down before retransmitting.。
        if (attempt > 1) {
          await Future<void>.delayed(settleAfterBrokenStream);
        }
        try {
          final r = await gate.readMulti(
            gapFrom,
            onProgress: (n) {
              final got = (batch?.length ?? 0) + n;
              _showMeasuredEta(pullSw, got, total - got < 0 ? 0 : total - got);
            },
          );
          final acc = batch ??= {};
          for (final rec in r.records) {
            acc[rec.recordSeq] = rec;
          }
          batchComplete = r.complete;
          if (kDebugMode) {
            debugPrint(
              '[Disjoint complement] 0xD3 attempt $attempt startSN=$gapFrom received '
              '${r.records.length} strip${r.complete ? "(whole)" : "(incomplete)"}，'
              'Grand total ${acc.length}/$total',
            );
          }
          if (r.complete) break;
        } catch (e) {
          batchComplete = false;
          if (kDebugMode) {
            debugPrint(
              '[Disjoint complement] 0xD3 attempt $attempt startSN=$gapFrom failed ($e)',
            );
          }
        }
      }
      final pullMs = pullSw.elapsedMilliseconds;

      // The batch package comes with real (sn, ts)，Use it to calibrate the anchor point. The device timestamp is more accurate than the calculated one.。
      final refined = _anchorFromBatch(batch);
      if (refined != null) {
        if (anchor == null ||
            (refined.tsOf(anchor.sn, periodSec) - anchor.tsSec).abs() >
                periodSec) {
          DevLog.instance.add(
            'collect',
            'cover: The anchor point is calibrated according to the actual package of the device. → SN=${refined.sn}@${_iso(refined.tsSec)}'
                '${anchor == null ? "" : "（original calculation SN=${anchor.sn}@${_iso(anchor.tsSec)}）"}',
          );
          anchor = refined;
          planned = _capOldest(
            _missingSns(
              refined,
              latestSn,
              have,
              activeSec: activeSec,
              periodSec: periodSec,
            ),
          );
        } else {
          anchor = refined;
        }
      }

      // There is still no anchor point (the local generation cannot be pushed、0xD3 (never came back)) Just from SN=1 I want the whole paragraph, and I will leave whatever I get.、
      // The frame’s own timestamp shall prevail.。
      var wanted =
          planned ?? _capOldest([for (var sn = 1; sn <= latestSn; sn++) sn]);

      // 0xD3 The reissue is still incomplete after exhaustion: the gap is small 0xD4 Make up for it, if it is too big, only the consecutive prefixes that have been received will be dropped, and the rest will
      // Leave it to next time 0xD3 Pull the whole section. Can’t press「SN ”Infinite reconnection if not continuous” Processing: Equipment FLASH Liben
      // The missing records cannot be changed and will be stuck in the reconnection loop and drag down the real-time data.。
      if (!batchComplete) {
        final stillMissing = wanted
            .where((sn) => batch == null || !batch.containsKey(sn))
            .length;
        if (stillMissing > maxSingleReads) {
          final firstGap = _firstStillMissing(batch, wanted) ?? latestSn + 1;
          // None of the truncated epicycles has been claimed, so it will be credited [lastUnresolvedGaps] Let the caller disconnect and try again。
          lastUnresolvedGaps += wanted.where((sn) => sn >= firstGap).length;
          wanted = wanted.where((sn) => sn < firstGap).toList();
          DevLog.instance.add(
            'collect',
            'Disjoint complement: 0xD3 Sent $maxMultiAttempts times still missing $stillMissing strip'
                '(Exceeding item-by-item limit $maxSingleReads)→ This round only falls SN<$firstGap of ${wanted.length} strip，'
                'SN=$firstGap from $lastUnresolvedGaps The strips are left until the next round when the connection is disconnected and then pulled again; real-time data is not affected',
          );
        } else if (kDebugMode) {
          debugPrint(
            '[Disjoint complement] 0xD3 $maxMultiAttempts Didn’t win all the times，'
            'lack $stillMissing strip(≤$maxSingleReads) → retreat 0xD4 Point by point',
          );
        }
        // It may be posted below 0xD4，Also let the disconnected flow calm down first.。
        await Future<void>.delayed(settleAfterBrokenStream);
      }

      final feedSw = Stopwatch()..start();
      // Batch stacking: Each transaction must wait for flash memory confirmation. There is no sequential dependency between frames, the whole batch
      // Not written for the next round 0xD3 It can be pulled back again, so you can save。
      final pendingFrames = <Uint8List>[];
      Future<void> flushFrames() async {
        if (pendingFrames.isEmpty) return;
        await pipeline.ingestFrames(pendingFrames, wearId: wearId);
        pendingFrames.clear();
        // The entire batch is synchronized to the main thread, and each batch gives up one frame to the interface.
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }

      for (var i = 0; i < wanted.length; i++) {
        final sn = wanted[i];
        if (i % 10 == 0) {
          _showMeasuredEta(feedSw, i, wanted.length - i);
        }
        GlucoseRecord? real;
        if (batch != null && (batchComplete || batch.containsKey(sn))) {
          real = batch[sn];
        } else {
          try {
            real = await gate.readSingle(sn);
          } catch (_) {
            real = null;
          }
          // 0xD4 There are two types of failure: the link is alive.（0xE3 (can pass)) It means that the device is really not available, fill in the blank；
          // 0xE3 If it is still unavailable, it means the link is broken. Stop this round immediately. Otherwise, the remaining gaps will be filled with blank lines.
          if (real == null) {
            var linkAlive = true;
            try {
              await gate.readMeasureState();
            } catch (_) {
              linkAlive = false;
            }
            if (!linkAlive) {
              // The rest have also not been asked for, so they will be included in the calculation. [lastUnresolvedGaps]。
              lastUnresolvedGaps += wanted.length - i;
              if (kDebugMode) {
                debugPrint(
                  '[Disjoint complement] Link down(0xE3Doesn’t make sense)→stop atSN=$sn,'
                  'Filled $filled records; ${wanted.length - i} records remain unresolved',
                );
              }
              break;
            }
          }
        }
        // The timestamp is based on the one provided by the device frame. If the device cannot provide it, it will be converted based on the anchor point; if there is no anchor point, it will be used.
        // 「latestSn ≈ ”At this moment”, the overall bias is at most one cycle, but each sn Still falling on their respective minutes。
        final tsSec =
            real?.timestampSec ??
            (anchor ?? _GenAnchor(latestSn, nowSec)).tsOf(sn, periodSec);
        // If there are already rows locally at this minute (old records brought back by the batch package), they will not be dropped repeatedly, but traces must be left: Gap Press
        // SN Judgment and delivery judgment are based on minutes. If the equipment is returned and we don’t keep it, we won’t keep accounts. It will be a gap in the next round.，
        // It can never be completed。
        if (real != null && have.contains(tsSec ~/ 60)) {
          await _markSettled(wearId, sn, tsSec, real);
          continue;
        }
        final (record, isGap) = _recordFor(sn, real, tsSec);
        if (isGap) gapFilled++;
        pendingFrames.add(BleFrameCodec.encode([record]));
        if (pendingFrames.length >= _ingestBatch) await flushFrames();
        have.add(tsSec ~/ 60);
        final seenMin = minFilledSec;
        if (!isGap && (seenMin == null || tsSec < seenMin)) {
          minFilledSec =
              tsSec; // Filling in blank rows has no true current, cannot correct the baseline, and does not count.
        }
        filled++;
      }
      // Link down break I walked here when I came out, and the frames I got were still dropped into the warehouse.
      await flushFrames();
      final feedMs = feedSw.elapsedMilliseconds;

      // BLE Reading so far, the following drain pure CPU+Bluetooth is not used when the library is dropped; high-priority links wake up frequently，
      // large batch drain If you have to run for several minutes, you have to downshift here.。finally That time here was the bottom line of the abnormal path.。
      await gate.setFastLink(false);

      if (filled > 0) {
        // Fully replenished drain Measured in minutes, the top bar progress ends here, and the remainder decreases at the measured rate.
        final drainSw = Stopwatch()..start();
        await pipeline.drain(
          params,
          onProgress: (p) {
            final remaining = filled - p;
            _showMeasuredEta(drainSw, p, remaining < 0 ? 0 : remaining);
          },
        );
        // Three-stage rate retention, used to estimate long-term replenishment time。
        String rate(int ms, int n) =>
            n <= 0 ? '-' : '${(ms / n).toStringAsFixed(1)}ms/strip';
        final pulled = batch?.length ?? 0;
        DevLog.instance.add(
          'collect',
          'Actual measurement of backfill segmentation: 0xD3pull $pulled strip/${pullMs}ms(${rate(pullMs, pulled)}) | '
              'Write framebuffer $filled strip/${feedMs}ms(${rate(feedMs, filled)}) | '
              'drainCalculate+Write $filled strip/${drainSw.elapsedMilliseconds}ms'
              '(${rate(drainSw.elapsedMilliseconds, filled)})',
        );
        if (kDebugMode) {
          debugPrint(
            '[Disjoint complement] wear=$wearId starting pointSN=$startSn complete $filled strip '
            '(Real machine0xD4/current0retreatExcel)→Double tables have been placed in the inventory',
          );
        }
        // The true data to be restored is earlier than the calculated row time, and the blood sugar after that period is calculated from the baseline of maintaining the false flat line.，
        // You must replay it from the starting point of the gap to correct it. Only run when you really jump in line: pure tail continuation without pollution, replaying in vain CPU。
        final rc = minFilledSec;
        if (rc != null &&
            maxComputedBeforeSec != null &&
            rc < maxComputedBeforeSec) {
          final n = await pipeline.recomputeFrom(
            params,
            wearId: wearId,
            fromTs: DateTime.fromMillisecondsSinceEpoch(rc * 1000, isUtc: true),
          );
          DevLog.instance.add(
            'collect',
            'Disjoint complement: The real data to be restored is the earliest to arrive. ${_iso(rc)}，earlier than calculated '
                '${_iso(maxComputedBeforeSec)} → Recalculate writeback $n strip'
                '（During the disconnection period, the false current of the maintained value is fed to the algorithm, and the baseline is dragged past）',
          );
        }
      }
    } finally {
      await gate.setFastLink(
        false,
      ); // High priority link consumes power, switch back after completion
      BackfillStatus.etaMinutes.value = null;
    }
    if (kDebugMode && gapFilled > 0) {
      debugPrint(
        '[Disjoint complement] wear=$wearId have $gapFilled A gap is inserted into the current0Fill records'
        '(Party A’s rules,Keep the timeline continuous)',
      );
    }
    return filled;
  }

  /// Anchor point of this generation: Scan local rows in ascending order of time. The last row with ”no serial number increasing” is the first row of this generation.
  /// （Serial number backwards＝The device has been cleared and the generation has been changed); the whole string increment indicates that the generation has not been changed, and the earliest line is the first line of this generation.。
  ///
  /// The latest local serial number is greater than the current one on the device. `latestSn` time, indicating that the device was cleared again and the local
  /// There are no new generation rows, the mapping cannot be deduced, and return null Walk the entire length。
  ///
  /// Deliberately do not use the mobile phone clock for cross-checking: the device time axis is tied to the measurement count. If one measurement is missed, it will be permanently one minute behind.，
  /// take now Being a benchmark can misjudge a good anchor as a bad one. The real calibration is in [_anchorFromBatch]。
  _GenAnchor? _genAnchorOf(List<_LocalRow> rows, int latestSn) {
    if (rows.isEmpty) return null;
    if (rows.last.seq > latestSn) {
      DevLog.instance.add(
        'collect',
        'cover: The latest local serial number ${rows.last.seq} > equipment latestSn=$latestSn'
            ' → After our last one, the device was cleared again, and the current generation mapping could not be pushed locally. Instead, the entire segment was pulled.',
      );
      return null;
    }
    var first = rows.first;
    for (var i = rows.length - 1; i > 0; i--) {
      // Only ”serial number backwards” is recognized as a generation change, and ”sequence numbers are equal” cannot also be regarded as a generation change: go to re-click. (wear,whole minute)，
      // and measure_time = Device time + Clock deviation, the same record may be pushed out by minutes after the deviation is remeasured
      // boundary, common seq Two rows are completed; if the replacement is based on equality, the anchor point will be judged to this row and the previous one. SN It all counts
      // This generation is missing, and every time you reconnect, the SN=1 Repeat the whole section。
      if (rows[i].seq < rows[i - 1].seq) {
        first = rows[i];
        break;
      }
    }
    return _GenAnchor(first.seq, first.tsSec);
  }

  /// If the upper limit is exceeded, the oldest merged logs will be discarded. Silently popping up the starting point will make ”the oldest few days have not been restored” look like the restoration is successful.。
  List<int> _capOldest(List<int> sns) {
    if (sns.length <= maxBackfill) return sns;
    final dropped = sns.length - maxBackfill;
    final kept = sns.sublist(dropped);
    DevLog.instance.add(
      'collect',
      'The number of disconnected complements exceeds the upper limit $maxBackfill Bar: oldest $dropped No replenishment，'
          'starting point to SN=${kept.first}（The baseline of stateful algorithms also starts here）',
    );
    return kept;
  }

  /// Select a true record in the batch package as the anchor point: given by the device `(sn, ts)` More accurate than any calculation。
  static _GenAnchor? _anchorFromBatch(Map<int, GlucoseRecord>? batch) {
    if (batch == null || batch.isEmpty) return null;
    GlucoseRecord? best;
    for (final r in batch.values) {
      if (r.timestampSec <= 0) continue;
      if (best == null || r.recordSeq > best.recordSeq) best = r;
    }
    return best == null ? null : _GenAnchor(best.recordSeq, best.timestampSec);
  }

  /// This generation 1..latestSn Not found locally SN（Ascending order), those earlier than the activation time are not counted。
  List<int> _missingSns(
    _GenAnchor a,
    int latestSn,
    Set<int> haveSns, {
    required int activeSec,
    required int periodSec,
  }) {
    final out = <int>[];
    for (var sn = 1; sn <= latestSn; sn++) {
      // Sensors that are earlier than the activation time do not belong to this sensor. Here it is still pushed linearly according to the anchor point: it is only used to cut off the previous generation
      // Head, that section is before the anchor point and there is no stopping problem。
      if (a.tsOf(sn, periodSec) < activeSec) continue;
      if (!haveSns.contains(sn)) out.add(sn);
    }
    return out;
  }

  /// Missing minutes before the current generation: the device serial number has been replaced, these minutes are used 0xD3/0xD4 Unable to click, permanently missing。
  /// The log must be logged, otherwise ”the oldest few hours are gone” will look like the recovery is successful.。
  void _logUnreachable(
    _GenAnchor a,
    Set<int> have, {
    required int activeSec,
    required int periodSec,
  }) {
    final genStartSec = a.tsOf(1, periodSec);
    if (genStartSec <= activeSec) return;
    var n = 0;
    for (var m = activeSec ~/ 60; m < genStartSec ~/ 60; m++) {
      if (!have.contains(m)) n++;
    }
    if (n > 0) {
      DevLog.instance.add(
        'collect',
        'cover: have $n minutes before this generation (this generation starts from ${_iso(genStartSec)}），'
            'The device serial number has been replaced, these times cannot be clicked, and it is permanently missing.',
      );
    }
  }

  /// Book wear since [sinceSec] Start the rows collected by this machine `(time, Device serial number)`，ascending order by time。
  ///
  /// Exclude cloud backfill rows (is_cloud_data='1')：It only has blood sugar but no current, and the serial number is not from this generation.，
  /// Neither can we push it aside, nor can we count it as ”this minute has already happened.”」。
  Future<List<_LocalRow>> _localRows(
    int wearId, {
    required int sinceSec,
  }) async {
    final t = db.userlocalGlucoseData;
    // measure_time yes int List + DateTimeEpochConverter，More useful epoch millisecond。
    final q = db.selectOnly(t)
      ..addColumns([t.measureTime, t.recordSeq])
      ..where(
        t.wearId.equals(wearId) &
            t.recordSeq.isNotNull() &
            (t.isCloudData.isNull() | t.isCloudData.equals('1').not()) &
            t.measureTime.isBiggerOrEqualValue(sinceSec * 1000),
      );
    final out = <_LocalRow>[];
    for (final r in await q.get()) {
      final ms = r.read(t.measureTime);
      final seq = r.read(t.recordSeq);
      if (ms != null && seq != null) out.add(_LocalRow(ms ~/ 1000, seq));
    }
    out.sort((a, b) => a.tsSec.compareTo(b.tsSec));
    return out;
  }

  /// Book wear The latest moment of blood sugar has been calculated (this machine can do it, if not) null），Used to determine whether this replenishment
  /// Insert into calculated history。
  Future<int?> _maxComputedTsSec(int wearId) async {
    final t = db.userlocalGlucoseData;
    final maxTs = t.measureTime.max();
    final q = db.selectOnly(t)
      ..addColumns([maxTs])
      ..where(
        t.wearId.equals(wearId) &
            t.glucoseValue1.isNotNull() &
            (t.isCloudData.isNull() | t.isCloudData.equals('1').not()),
      );
    final row = await q.getSingleOrNull();
    final ms = row?.read(maxTs);
    return ms == null ? null : ms ~/ 1000;
  }

  /// Make a note of ”this SN The equipment has been given, and we will judge the weight by minutes and display the line.」。
  ///
  /// Write to the framebuffer and mark directly DONE：[_bufferedRows] and replenishing and guarding holes Determine whether to recognize the frame buffer，
  /// I won’t treat it as a gap in the next round.；drain Take only RAW/RETRY，will not be reprocessed。
  Future<void> _markSettled(
    int wearId,
    int sn,
    int tsSec,
    GlucoseRecord real,
  ) async {
    final t = db.bleFrameBuffer;
    final exists =
        await (db.select(t)
              ..where((r) => r.wearId.equals(wearId) & r.recordSeq.equals(sn))
              ..limit(1))
            .getSingleOrNull();
    if (exists != null) return;
    final at = DateTime.fromMillisecondsSinceEpoch(tsSec * 1000, isUtc: true);
    await db
        .into(t)
        .insert(
          BleFrameBufferCompanion.insert(
            wearId: Value(wearId),
            rawFrame: BleFrameCodec.encode([real]),
            measureTime: at,
            recordSeq: Value(sn),
            rawCurrent: Value(real.rawCurrent),
            temperature: Value(real.temperature),
            status: const Value(FrameBufferStatus.done),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Book wear since [sinceSec] Lines that have been processed in the frame buffer `(time, Device serial number)`。
  ///
  /// The frame buffer does not automatically discard, and every frame received is retained.（RAW→DONE）。Frames dropped by same-minute deduplication rules
  /// Only recognized here, display table and raw The table doesn’t have it。
  Future<List<_LocalRow>> _bufferedRows(
    int wearId, {
    required int sinceSec,
  }) async {
    final t = db.bleFrameBuffer;
    final q = db.selectOnly(t)
      ..addColumns([t.measureTime, t.recordSeq])
      ..where(
        t.wearId.equals(wearId) &
            t.recordSeq.isNotNull() &
            t.status.equals(FrameBufferStatus.done) &
            t.measureTime.isBiggerOrEqualValue(sinceSec * 1000),
      );
    final out = <_LocalRow>[];
    for (final r in await q.get()) {
      final ms = r.read(t.measureTime);
      final seq = r.read(t.recordSeq);
      if (ms != null && seq != null) out.add(_LocalRow(ms ~/ 1000, seq));
    }
    return out;
  }

  /// Book wear since [sinceSec] Starting from the line that already has the original current `(time, Device serial number)`。
  /// 「Do you want to ask the device? Click raw Judgment: The cloud supplement only has blood sugar but no current, and the algorithm baseline cannot be reconstructed.，
  /// Still have to ask for it。
  Future<List<_LocalRow>> _rawRows(int wearId, {required int sinceSec}) async {
    final t = db.userlocalGlucoseRawData;
    final q = db.selectOnly(t)
      ..addColumns([t.measureTime, t.recordSeq])
      ..where(
        t.wearId.equals(wearId) &
            t.measureTime.isBiggerOrEqualValue(sinceSec * 1000),
      );
    final out = <_LocalRow>[];
    for (final r in await q.get()) {
      final ms = r.read(t.measureTime);
      if (ms != null) out.add(_LocalRow(ms ~/ 1000, r.read(t.recordSeq) ?? -1));
    }
    return out;
  }

  /// Excel A quick tip: taking the current Excel，Voltage/The temperature is really different 0 Use true value otherwise Excel，
  /// The timestamp uses the real machine value, otherwise it is calculated using the anchor point. [tsSec]。
  GlucoseRecord _excelRecord(int sn, int tsSec, GlucoseRecord? real) {
    final s = dataset!.sampleForSeq(sn); // only dataset != null branch call
    return GlucoseRecord(
      timestampSec: real?.timestampSec ?? tsSec,
      recordSeq: sn,
      voltage: (real != null && real.voltage != 0) ? real.voltage : s.voltage,
      temperature: (real != null && real.temperature != 0)
          ? real.temperature
          : s.temperature,
      rawCurrent: s.current,
      lactate: 0.0,
    );
  }

  /// [wanted] The first one I haven’t gotten yet SN（Complete/No rules null），0xD3 Starting point for reissue。
  static int? _firstStillMissing(
    Map<int, GlucoseRecord>? batch,
    List<int>? wanted,
  ) {
    if (wanted == null) return null;
    for (final sn in wanted) {
      if (batch == null || !batch.containsKey(sn)) return sn;
    }
    return null;
  }

  static String _iso(int tsSec) => DateTime.fromMillisecondsSinceEpoch(
    tsSec * 1000,
    isUtc: true,
  ).toIso8601String();

  /// Remaining [count] Click 1.2 Second/strip（0xD4 about 1.1s）Convert to minutes, minimum 1。
  /// This is only a rough estimate, and we will proceed after we have actual measured speeds. [_showMeasuredEta]。
  static int _etaMinutes(int count) {
    final m = (count * 1.2 / 60).ceil();
    return m < 1 ? 1 : m;
  }

  /// According to the current measured rate, the remaining [remaining] Convert bars into minutes and update the top bar。
  /// done=0 When there is no rate to measure, the last displayed value is retained. Caliber shared with cold start replay。
  static void _showMeasuredEta(Stopwatch sw, int done, int remaining) =>
      BackfillStatus.showMeasured(sw: sw, done: done, remaining: remaining);

  /// A backfill record: if there is a real current, use the true value; otherwise Excel Keep it under wraps; otherwise plug in the current=0 fill record
  /// Keep the timeline continuous (blank filling will be invalidated by the entry control and the abnormal line will be dropped, and the algorithm will not be fed). return (Record, Whether to fill the gap)。
  (GlucoseRecord, bool) _recordFor(int sn, GlucoseRecord? real, int tsSec) {
    if (real != null && real.rawCurrent > zeroCurrentEps) return (real, false);
    if (dataset != null) return (_excelRecord(sn, tsSec, real), false);
    return (
      GlucoseRecord(
        timestampSec: real?.timestampSec ?? tsSec,
        recordSeq: sn,
        voltage: real?.voltage ?? 0,
        temperature: real?.temperature ?? 0,
        rawCurrent: 0.0,
        lactate: 0.0,
      ),
      true,
    );
  }
}

/// Minimum projection of a local row: moment + Device serial number。
class _LocalRow {
  const _LocalRow(this.tsSec, this.seq);

  final int tsSec;
  final int seq;
}
