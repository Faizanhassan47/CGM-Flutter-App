import 'dart:async';
import 'dart:typed_data';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/domain/cgm_ble_gate.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';
import 'package:cgm_sdk/src/ble/cgm_command.dart';
import 'package:cgm_sdk/src/collection/device_clock_skew.dart';

import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';

/// Real-time collection of real devices: Subscribe to devices 0xB0 Report (one per minute), join the queue frame by frame ingestFrame→drain link。
/// The current source consists of pipeline Determine based on the current frame, serial number/The timestamp always uses the real value of the device. If there is a missing frame, the number will not be counted.。
/// Before subscribing [gate] should have connect and turn on notifications。
class LiveGlucoseCollector {
  LiveGlucoseCollector({
    required this.gate,
    required this.pipeline,
    required this.params,
    required this.wearId,
    this.onFrame,
  });

  final CgmBleGate gate;
  final GlucosePipelineRepository pipeline;
  final GluCalcParameter params;
  final int wearId;

  /// Received successful parsing 0xB0 Frame is callback (device measurement time + Device serial number），
  /// Provides the upper layer with instructions to give way to the pocket timer, record device clock deviation, and check serial number continuity.。
  final void Function(DateTime measureTime, int recordSeq)? onFrame;

  StreamSubscription<List<int>>? _sub;

  /// drain Running. The algorithm is not thread-safe and only allows one round at a time.。
  bool _busy = false;

  /// When I was busy, a new frame dropped. After this round, another round will be added.。
  bool _pendingDrain = false;

  bool get isRunning => _sub != null;

  void start() {
    _sub ??= gate.measurements().listen(_onMeasurement);
    DevLog.instance.add(
      'ble',
      'Option 2 real-time collection has started, waiting for the equipment to be launched 0xB0（Judging reality frame by frame/Zero current）…',
    );
  }

  Future<void> _onMeasurement(List<int> bytes) async {
    // Only frames pushed by the subscription can be used to observe device clock deviation
    if (!await _parseAndIngest(bytes, realtime: true)) return;
    await _runDrain();
  }

  /// Feed the original frame buffer buffered during the connection period into the pipeline: drop the original frame buffer one by one, and finally count one round。
  /// Between connection and real-time collection (read 0xE3、0xD3 cover、drain、Recompute writeback) The device pushes frames per minute as usual。
  Future<void> ingestBuffered(Iterable<List<int>> frames) async {
    var n = 0;
    for (final b in frames) {
      if (await _parseAndIngest(b)) n++;
    }
    if (n == 0) return;
    DevLog.instance.add(
      'ble',
      'buffered during connection $n Frame padded original framebuffer → Count as one round',
    );
    await _runDrain();
  }

  /// Parse a frame and drop the original framebuffer; bad frame/Failed to drop the library and return false。
  ///
  /// The dropout does not wait until the last round of calculation is completed: the dropout is in milliseconds, and it may take tens of seconds to complete the calculation (cold start replay, backfill drain All are there
  /// on the same serial pipe), if the frame is dropped before the last line is finished, the original frames of this minute will be lost together, and you can only wait. 0xD3 cover。
  Future<bool> _parseAndIngest(List<int> bytes, {bool realtime = false}) async {
    try {
      final hex = bytes
          .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0'))
          .join(' ');
      DevLog.instance.add(
        'ble',
        'receive0xB0original frame(${bytes.length}byte): $hex',
      );
      final GlucoseRecord raw;
      try {
        raw = CgmCommand.parseMeasurement(Uint8List.fromList(bytes));
      } on BleFrameException catch (e) {
        DevLog.instance.add(
          'ble',
          '0xB0 Parsing failed and discarded: ${e.reason}',
        );
        return false;
      }
      // 0xB0 Once received, it is just measured, and it is the most accurate observation source of device clock deviation. Only frames subscribed to in real time participate in the observation：
      // [ingestBuffered] The frame observation values ​​of batch refeeding are successively smaller. 60 Seconds, comparing them to the deviation will cause each frame to collapse to the same minute and be deduplicated and discarded.。
      if (realtime) DeviceClockSkew.observe(raw.timestampSec, DateTime.now());
      final rec = DeviceClockSkew.isKnown
          ? GlucoseRecord(
              timestampSec: DeviceClockSkew.toRealSec(raw.timestampSec),
              recordSeq: raw.recordSeq,
              voltage: raw.voltage,
              temperature: raw.temperature,
              rawCurrent: raw.rawCurrent,
              lactate: raw.lactate,
            )
          : raw;
      DevLog.instance.add(
        'ble',
        '0xB0 parsed value seq=${rec.recordSeq} ts=${rec.timestampSec} '
            'current=${rec.rawCurrent}nA temperature=${rec.temperature}℃ Voltage=${rec.voltage}V',
      );
      // Device timestamp is local time zone caliber
      onFrame?.call(
        DateTime.fromMillisecondsSinceEpoch(
          rec.timestampSec * 1000,
          isUtc: true,
        ).toLocal(),
        rec.recordSeq,
      );

      final real = rec.rawCurrent > GlucosePipelineRepository.zeroCurrentEps;
      DevLog.instance.add(
        'ble',
        real
            ? '0xB0 seq=${rec.recordSeq} current=${rec.rawCurrent}nA(Real situation two) → Taking over the engine'
            : '0xB0 seq=${rec.recordSeq} current≈0(${rec.rawCurrent}nA·Situation one) '
                  '→ pipeline according toseqPickExcelFeeding the same main engine to produce blood sugar after current replacement',
      );

      await pipeline.ingestFrame(BleFrameCodec.encode([rec]), wearId: wearId);
      return true;
    } catch (e) {
      // Failure to drop the library (such as the library cannot be opened during the lock screen period) cannot allow exceptions to occur stream Interrupt subscription; this frame was indeed lost。
      DevLog.instance.add(
        'ble',
        '0xB0 Failed to drop original framebuffer(This frame is lost): $e',
      );
      return false;
    }
  }

  /// Count one round. The algorithm is not thread-safe, only one round is allowed at the same time; it is marked during busy hours, and one round of digestion period will be automatically added after calculation.
  /// dropped frame（drain according to measureTime Take it in ascending order, the order is not disordered）。
  Future<void> _runDrain() async {
    if (_busy) {
      _pendingDrain = true;
      DevLog.instance.add(
        'ble',
        '0xB0 The original frame buffer has been dropped, and the previous round is still counting. → Waiting in line for repayment',
      );
      return;
    }
    _busy = true;
    try {
      do {
        _pendingDrain = false;
        await pipeline.drain(params);
      } while (_pendingDrain);
    } catch (e) {
      DevLog.instance.add(
        'ble',
        '0xB0 Calculation failed(The original frame has been dropped into the library,Compensation in the next round): $e',
      );
    } finally {
      _busy = false;
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async => stop();
}
