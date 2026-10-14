import 'package:drift/drift.dart' show Variable;

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';

/// Device timeline self-check: Calculate ”how many minutes the device is behind and where it is lost” from the real frames that have fallen in the local library.」，
/// No extrapolation, no interpolation。
///
/// The basis is `ble_frame_buffer` two moments per frame：
/// - `measure_time`：The timestamp that comes with the device frame is always equal to `t0 + SN×60`（No equipment RTC，The essence is sampling counting）。
/// - `created_at`：The actual moment when the machine writes this frame into the library。
///
/// No distinction is made between real-time frames and back-up frames (distinguishing by frame length is not feasible: real-time frames will be processed once before being dropped into the library) `BleFrameCodec.encode`，
/// It is the same as the backfill frame 18 byte). Use two physical constraints instead：
/// 1. It is impossible for any frame to be received first and detected later.：`created_at − equipmentts ≥ True deviation`，Each row is an upper bound，
///    Measured as soon as the real-time frame is received, the upper bound is the tightest。
/// 2. If the equipment takes one less sample, it will be permanently behind by one minute: the true deviation varies with SN Monotonous。
///
/// So every SN the tightest upper bound of = The smallest observation value in all rows after it (suffix minimum value), the largest observation value of the back-up frame
/// It will be suppressed by subsequent real-time frames. The place where the minimum value of the suffix increases is the interval where the equipment stops.。
class DeviceTimelineAudit {
  DeviceTimelineAudit(this._db, {this.stepToleranceSec = 120});

  final CgmDatabase _db;

  /// The ”low yield” of adjacent anchor points exceeds this many seconds before it is considered a step, which is used to absorb frame receiving jitter (push delay、
  /// drain queue), so that every second of normal jitter is not recorded as a step。
  final int stepToleranceSec;

  Future<DeviceTimelineAuditResult> run({required int wearId}) async {
    final raw = await _db
        .customSelect(
          'SELECT record_seq AS seq, measure_time AS dev_ms, created_at AS real_ms '
          'FROM ble_frame_buffer '
          'WHERE wear_id = ?1 AND record_seq IS NOT NULL',
          variables: [Variable<int>(wearId)],
        )
        .get();
    if (raw.isEmpty) {
      return const DeviceTimelineAuditResult(
        anchors: [],
        steps: [],
        generationResets: 0,
      );
    }

    // ① Generations. After the device is cleared t0 Will be rewritten, within the same generation `t0 = equipmentts − SN×60` Constant (jitter second level，
    // Rounded into minutes). according to t0 Group ratio ”Look at the order of storage SN ”Is there a rollback” is reliable, the latter will
    // backfill (old SN in new SN stored later) misjudged as replacement。
    final gens = <int, List<({int seq, int dev, int obs})>>{};
    for (final r in raw) {
      final seq = r.read<int>('seq');
      final dev = r.read<int>('dev_ms') ~/ 1000;
      final obs = (r.read<int>('real_ms') ~/ 1000) - dev;
      final t0 = dev - seq * 60;
      gens.putIfAbsent((t0 / 60).round(), () => []).add((
        seq: seq,
        dev: dev,
        obs: obs,
      ));
    }
    // See only the latest generation: cross-generational SN If they are not in the same number range, there is no point in mixing them up.
    final newestKey = gens.keys.reduce((a, b) => a > b ? a : b);
    final rowsOfGen = gens[newestKey]!;

    // ② same one SN May have multiple lines (recommend / (Backfill and repeat the frame), leaving only the row with the smallest observed value - the smallest or tightest upper bound
    final best = <int, ({int dev, int obs})>{};
    for (final r in rowsOfGen) {
      final cur = best[r.seq];
      if (cur == null || r.obs < cur.obs) {
        best[r.seq] = (dev: r.dev, obs: r.obs);
      }
    }
    final seqs = best.keys.toList()..sort();

    // ③ Suffix minimum: the true deviation varies with SN Monotone does not decrease, so each SN the tightest upper bound of＝The smallest observation value in all rows after it
    final skew = <int, int>{};
    var running = best[seqs.last]!.obs;
    for (var i = seqs.length - 1; i >= 0; i--) {
      final o = best[seqs[i]]!.obs;
      if (o < running) running = o;
      skew[seqs[i]] = running < 0 ? 0 : running;
    }

    final anchors = <DeviceTimeAnchor>[
      for (final sn in seqs)
        DeviceTimeAnchor(sn, best[sn]!.dev, best[sn]!.dev + skew[sn]!),
    ];

    // ④ steps＝At the deviation lifting point, the lifting amount is how much less the equipment produces during this period.
    final steps = <DeviceTimelineStep>[];
    for (var i = 1; i < anchors.length; i++) {
      final lost = skew[seqs[i]]! - skew[seqs[i - 1]]!;
      if (lost.abs() > stepToleranceSec) {
        steps.add(
          DeviceTimelineStep(
            from: anchors[i - 1],
            to: anchors[i],
            lostSec: lost,
          ),
        );
      }
    }

    return DeviceTimelineAuditResult(
      anchors: anchors,
      steps: steps,
      generationResets: gens.length - 1,
    );
  }

  /// Run it once and write the conclusion in DevLog。
  Future<DeviceTimelineAuditResult> logFor({required int wearId}) async {
    final r = await run(wearId: wearId);
    DevLog.instance.add('collect', r.describe());
    return r;
  }
}

/// A real anchor point: ”The time the device said it” and ”The time the machine actually received it” on a certain record」。
class DeviceTimeAnchor {
  const DeviceTimeAnchor(this.seq, this.deviceSec, this.realSec);

  final int seq;
  final int deviceSec;
  final int realSec;

  /// How many seconds the device is behind this machine. Device time = sample count×60，So the amount of lag ÷60 It’s the number of pieces that are produced in small quantities.。
  int get skewSec => realSec - deviceSec;
}

/// How many seconds does the device lose between two adjacent anchor points?（>0 = Not producing one per minute）。
class DeviceTimelineStep {
  const DeviceTimelineStep({
    required this.from,
    required this.to,
    required this.lostSec,
  });

  final DeviceTimeAnchor from;
  final DeviceTimeAnchor to;
  final int lostSec;
}

class DeviceTimelineAuditResult {
  const DeviceTimelineAuditResult({
    required this.anchors,
    required this.steps,
    required this.generationResets,
  });

  /// Real anchor points, in ascending order according to the real time of the local machine。
  final List<DeviceTimeAnchor> anchors;

  /// Less productive steps, in order of occurrence。
  final List<DeviceTimelineStep> steps;

  /// Devices encountered during scanning SN Clear times。
  final int generationResets;

  bool get hasAnchors => anchors.length >= 2;

  int get firstSkewSec => anchors.isEmpty ? 0 : anchors.first.skewSec;

  int get lastSkewSec => anchors.isEmpty ? 0 : anchors.last.skewSec;

  /// The total number of seconds produced by steps。
  int get totalLostSec =>
      steps.fold<int>(0, (sum, s) => sum + (s.lostSec > 0 ? s.lostSec : 0));

  /// One can fit in DevLog conclusion. Only state the difference between the actual measured values ​​and them, without making inferential descriptions。
  String describe() {
    if (!hasAnchors) {
      return 'Device timeline self-test: Insufficient native real-time frames 2 strip (current ${anchors.length} strip），'
          'The amount of backward equipment cannot be calculated. The backfill frame cannot be used as a basis - its storage time is the moment of backfill and has nothing to do with measurement.。';
    }
    final b = StringBuffer()
      ..writeln(
        'Device timeline self-test (all taken from the real frames that have been dropped into the machine, zero extrapolation）:',
      )
      ..writeln(
        '  Live anchor ${anchors.length} Article, true ${_hm(anchors.first.realSec)}'
        ' → ${_hm(anchors.last.realSec)}，'
        'SN ${anchors.first.seq} → ${anchors.last.seq}',
      )
      ..writeln(
        '  first anchor point behind ${_min(firstSkewSec)} minute，'
        'latest anchor lagging behind ${_min(lastSkewSec)} minute',
      );
    if (generationResets > 0) {
      b.writeln(
        '  Device encountered during scanning SN Clear $generationResets times (steps are not counted across generations)）',
      );
    }
    b.writeln('  → ${_verdict()}');
    if (steps.isNotEmpty) {
      final worst = [...steps]
        ..sort((x, y) => y.lostSec.abs().compareTo(x.lostSec.abs()));
      b.writeln(
        '  Less productive steps ${steps.length} Division, total ${_min(totalLostSec)} minutes, the biggest ones:',
      );
      for (final s in worst.take(5)) {
        b.writeln(
          '   · SN ${s.from.seq}→${s.to.seq} '
          'reality ${_hm(s.from.realSec)}→${_hm(s.to.realSec)} '
          '${s.lostSec > 0 ? "Low yield" : "prolific"} ${_min(s.lostSec.abs())} minute',
        );
      }
    }
    return b.toString().trimRight();
  }

  String _verdict() {
    const tol = 120;
    if (firstSkewSec.abs() <= tol && lastSkewSec.abs() <= tol) {
      return 'The device is consistent with this machine and does not lag behind。';
    }
    if (firstSkewSec.abs() > tol) {
      return 'The first real-time frame is already behind ${_min(firstSkewSec)} minute → '
          'time base (when activated 0xD1 written to device t0）It’s biased in itself, it’s not because I missed it later.；'
          'Then it grew again ${_min(lastSkewSec - firstSkewSec)} minute。';
    }
    return 'Matches when activated and grows later ${_min(lastSkewSec)} minute → '
        'The device actually produced so many fewer records.（t0 That’s right）'
        '${steps.isEmpty ? "，And it grows little by little at a uniform speed, with no concentrated steps." : "，Concentrate on the following paragraphs"}。';
  }

  static String _min(int sec) => (sec / 60).toStringAsFixed(1);

  static String _hm(int sec) {
    final t = DateTime.fromMillisecondsSinceEpoch(
      sec * 1000,
      isUtc: true,
    ).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
