import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';

import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';

/// Analog collector without real machine stage: every [interval] Make a current walking machine with the same style ingestFrame→drain。
class SimulatedGlucoseCollector {
  final GlucosePipelineRepository pipeline;
  final GluCalcParameter params;
  final int wearId;
  final Duration interval;
  final DateTime Function() _now;
  final Random _rand;

  int _seq;
  Timer? _timer;
  bool _busy = false;

  SimulatedGlucoseCollector({
    required this.pipeline,
    required this.params,
    required this.wearId,
    this.interval = const Duration(minutes: 1),
    DateTime Function()? now,
    Random? random,
    int startSeq = 1,
  }) : _now = now ?? DateTime.now,
       _rand = random ?? Random(),
       _seq = startSeq;

  bool get isRunning => _timer != null;

  /// wheel press record_seq Not according to time, the upload time is not aligned with the whole minute。
  void start() {
    _timer ??= Timer.periodic(interval, (_) => collectOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async => stop();

  /// Run a round: making numbers, forming frames, storing, and converting；[_busy] Anti-reentrancy。
  Future<void> collectOnce() async {
    if (_busy) return;
    _busy = true;
    try {
      final now = _now();
      final ts = now.toUtc().millisecondsSinceEpoch ~/ 1000;
      final a = params.slope != 0 ? params.slope : 0.79;
      // First set the target blood sugar according to the daily curve, then reverse the current, and convert it back to this blood sugar downstream.
      final current = (_profileGlucose(now) - params.intercept) / a;
      final record = GlucoseRecord(
        timestampSec: ts,
        recordSeq: _seq++,
        voltage: 2.84 + (_rand.nextDouble() - 0.5) * 0.02,
        temperature: 28.0 + (_rand.nextDouble() - 0.5) * 2.0,
        rawCurrent: double.parse(current.toStringAsFixed(2)),
        lactate: 0.0,
      );
      final Uint8List frame = BleFrameCodec.encode([record]);
      await pipeline.ingestFrame(frame, wearId: wearId);
      await pipeline.drain(params);
    } finally {
      _busy = false;
    }
  }

  /// Simulating a day’s blood glucose profile: baseline 5.2 + dawn rises + Three meals peak + Noise, meal peak can be broken 10。
  double _profileGlucose(DateTime now) {
    final h = now.hour + now.minute / 60.0;
    double bump(double c, double amp, double w) =>
        amp * exp(-((h - c) * (h - c)) / (2 * w * w));
    final dawn = bump(6, 0.8, 2.0);
    final meals =
        bump(8, 4.8, 1.0) + bump(12.5, 5.2, 1.1) + bump(18.5, 5.0, 1.2);
    final noise = (_rand.nextDouble() - 0.5) * 0.3;
    return (5.2 + dawn + meals + noise).clamp(3.2, 15.5);
  }
}
