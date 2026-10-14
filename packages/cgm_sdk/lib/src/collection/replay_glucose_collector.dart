import 'dart:async';
import 'dart:typed_data';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';
import 'package:cgm_sdk/src/collection/cgm_replay_dataset.dart';

import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';

/// A pocket collector that prints out blood sugar every minute. When there is a real current, the LiveGlucoseCollector Go frame by frame、
/// This collector has [shouldSkip] give way; otherwise use [CgmReplayDataset] corresponding to the slot Excel current。
///
/// The slot system ensures equal mapping between sequence numbers and time (the algorithm takes real timestamps and is stateful）：
/// `seq slot timestamp = anchorTs + (seq - anchorSeq) × interval`，Each round
/// `[The slot you visited last time+1 .. Current slot]` Complement together, the serial number and time are both consecutive。
class ReplayGlucoseCollector {
  final GlucosePipelineRepository pipeline;
  final CgmReplayDataset dataset;
  final GluCalcParameter params;
  final int wearId;
  final Duration interval;

  /// Anchor point of slot and time：record_seq=[anchorSeq] records corresponding to [anchorTs]。
  /// Excel timeline anchor (1, Wear activation time)，True device timeline anchors the last true record extrapolated along the device timeline。
  final int anchorSeq;
  final DateTime anchorTs;

  /// The local time at the moment when the anchor point is obtained, and the slot advancement is based on it (the default is the same as [anchorTs] Homology）。
  ///
  /// Must be with [anchorTs] Separate: Anchor device when recording [anchorTs] From the device clock, slot advancement uses the phone clock，
  /// What’s the difference between two clocks? Excel The slot is only a few frames ahead. When the real frame comes back, it will hit the duplicate frame of the same timeline and cannot enter the library.。
  final DateTime anchorWallClock;

  /// return true then skip this round; the transmitter gives way when sending frames to avoid conflicts with [LiveGlucoseCollector] repeat。
  final bool Function()? shouldSkip;

  /// The upper limit of filling slots in a single round：21600 = 15 One piece per minute for full coverage during the daily wear period。
  final int maxCatchUp;

  /// Clock injection port (for testing）。
  final DateTime Function() nowProvider;

  int _seq;
  Timer? _timer;
  bool _busy = false;

  ReplayGlucoseCollector({
    required this.pipeline,
    required this.dataset,
    required this.params,
    required this.wearId,
    required DateTime anchorTs,
    DateTime? anchorWallClock,
    this.anchorSeq = 1,
    this.interval = const Duration(minutes: 1),
    int startSeq = 1,
    this.shouldSkip,
    this.maxCatchUp = 21600,
    this.nowProvider = DateTime.now,
  }) : anchorTs = anchorTs.toUtc(),
       anchorWallClock = (anchorWallClock ?? anchorTs).toUtc(),
       _seq = startSeq;

  bool get isRunning => _timer != null;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => collectOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async => stop();

  /// The slot number corresponding to the current moment is advanced according to the elapsed time of the mobile phone clock since the anchor point.；
  /// Can’t take it now Remove device timeline [anchorTs]。
  int _slotForNow() =>
      anchorSeq +
      nowProvider().toUtc().difference(anchorWallClock).inSeconds ~/
          interval.inSeconds;

  /// seq Slot timestamp（UTC Second）。
  int _tsForSlot(int seq) =>
      anchorTs.millisecondsSinceEpoch ~/ 1000 +
      (seq - anchorSeq) * interval.inSeconds;

  /// Run for one round: The transmitter will give way when sending frames, otherwise it will `[Waiting for slot .. Current slot]` Press slot by slot Excel Framing
  /// （Use slot timestamp instead now）Drop framebuffer, again drain feed algorithm。
  Future<void> collectOnce() async {
    if (_busy) return;
    if (shouldSkip?.call() == true) return;
    _busy = true;
    try {
      final nowSeq = _slotForNow();
      if (nowSeq < _seq) {
        return; // This slot has already been released or the clock has been set back. It will not be released again.
      }
      var from = _seq;
      if (nowSeq - from + 1 > maxCatchUp) {
        DevLog.instance.add(
          'ble',
          'Complete the upper limit: slots[$from..$nowSeq]Only the latest$maxCatchUp(discard earlier slots）',
        );
        from = nowSeq - maxCatchUp + 1;
      }
      for (var seq = from; seq <= nowSeq; seq++) {
        final s = dataset.sampleForSeq(seq);
        final record = GlucoseRecord(
          timestampSec: _tsForSlot(seq),
          recordSeq: seq,
          voltage: s.voltage,
          temperature: s.temperature,
          rawCurrent: s.current,
          lactate: 0.0,
        );
        final Uint8List frame = BleFrameCodec.encode([record]);
        await pipeline.ingestFrame(frame, wearId: wearId);
      }
      _seq = nowSeq + 1;
      DevLog.instance.add(
        'ble',
        nowSeq == from
            ? 'transmitter silent→whole frameExcelreveal all the details seq=$nowSeq current=${dataset.sampleForSeq(nowSeq).current}nA'
            : 'transmitter silent→ExcelFill the slot at the bottom of the pocket[$from..$nowSeq]common${nowSeq - from + 1}strip(Missing minutes included)',
      );
      await pipeline.drain(params);
    } finally {
      _busy = false;
    }
  }
}
