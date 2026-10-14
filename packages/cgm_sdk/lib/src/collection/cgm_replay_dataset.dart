import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A real machine playback sample: current(nA)/temperature(℃)/Voltage(V)，That is, the transmitter passes app the original amount of。
/// excelGlucose It is only used as a comparison benchmark. Blood sugar is calculated from the current by the algorithm and this value is not taken.。
class CgmReplaySample {
  const CgmReplaySample(
    this.current,
    this.temperature,
    this.voltage, [
    this.excelGlucose = 0.0,
  ]);

  final double current;
  final double temperature;
  final double voltage;

  /// Actual measured reference blood glucose (compared to baseline), otherwise 0。
  final double excelGlucose;
}

/// Real machine measured current playback set (included in the package) `assets/data/cgm_replay.csv`，about 21600 strip = 15 One message every minute every day）。
/// In the sensorless stage, the real current is taken according to the serial number in the wearing period, and the same algorithm link is fed to calculate blood sugar.。
class CgmReplayDataset {
  const CgmReplayDataset(this.samples);

  final List<CgmReplaySample> samples;

  /// Assets follow cgm_sdk Bao away, host sutra rootBundle What you need to bring when taking out the assets in the package packages/ prefix。
  static const String assetPath = 'packages/cgm_sdk/assets/data/cgm_replay.csv';

  bool get isEmpty => samples.isEmpty;
  int get length => samples.length;

  /// according to record_seq(1-based) Take the corresponding line and clamp to the beginning if it crosses the boundary/tail。
  CgmReplaySample sampleForSeq(int recordSeq) {
    if (samples.isEmpty) return const CgmReplaySample(0, 0, 0);
    final idx = (recordSeq - 1).clamp(0, samples.length - 1);
    return samples[idx];
  }

  /// right [seq] Neighborhood (before and after each [half] row) of (current→Excel(blood sugar), perform least squares on the pair, and return the
  /// linear coefficient. The sensor sensitivity drifts approx. 5 times, single full-range linearity and large deviation in the middle and late stages。
  /// Returns when there are insufficient effective points or there is no change in current null，The caller returns a fixed coefficient。
  ({double a, double b})? fitAround(int seq, {int half = 45}) {
    if (samples.isEmpty) return null;
    final center = (seq - 1).clamp(0, samples.length - 1);
    final lo = (center - half).clamp(0, samples.length - 1);
    final hi = (center + half).clamp(0, samples.length - 1);
    var n = 0;
    var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
    for (var i = lo; i <= hi; i++) {
      final s = samples[i];
      if (s.excelGlucose <= 0 || s.current <= 0) continue;
      n++;
      sx += s.current;
      sy += s.excelGlucose;
      sxx += s.current * s.current;
      sxy += s.current * s.excelGlucose;
    }
    if (n < 2) return null;
    final denom = n * sxx - sx * sx;
    if (denom.abs() < 1e-9) {
      return null; // The current is constant and the slope is unsolvable
    }
    final a = (n * sxy - sx * sy) / denom;
    final b = (sy - a * sx) / n;
    if (!a.isFinite || !b.isFinite) return null;
    return (a: a, b: b);
  }

  /// parse CSV：per line `current,temp,voltage[,excel_glucose]`，`#` Comment lines and blank lines are skipped。
  static CgmReplayDataset parse(String csv) {
    final out = <CgmReplaySample>[];
    for (final line in const LineSplitter().convert(csv)) {
      final s = line.trim();
      if (s.isEmpty || s.startsWith('#')) continue;
      final parts = s.split(',');
      if (parts.length < 3) continue;
      final c = double.tryParse(parts[0]);
      final t = double.tryParse(parts[1]);
      final v = double.tryParse(parts[2]);
      if (c == null || t == null || v == null) continue;
      final g = parts.length > 3 ? double.tryParse(parts[3]) ?? 0.0 : 0.0;
      out.add(CgmReplaySample(c, t, v, g));
    }
    return CgmReplayDataset(out);
  }

  static Future<CgmReplayDataset> load() async =>
      parse(await rootBundle.loadString(assetPath));
}
