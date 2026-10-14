/// current / Signal abnormality determination (Party A《CGM Equipment exception list》E01 / E02 / E03），and App Home page same caliber。
/// One piece of data per minute，seq = Wear the first N minute. Pure function, the facade is adjusted once every frame。
library;

/// E01 Low current threshold during warm-up period（nA）。
const double kE01LowCurrentNa = 0.5;

/// E02 High current threshold during warm-up period（nA）。
const double kE02HighCurrentNa = 30.0;

/// E03 ”Invalid blood glucose” threshold during wearing period（mmol/L）。
const double kE03LowGlucose = 0.2;

/// E01 Number of minutes required for consecutive hits。
const int kE01ConsecutiveMin = 15;

/// E03 Window size and lower hit limit（15 Tiaozhong 12 strip）。
const int kE03Window = 15;
const int kE03LowCountThreshold = 12;

class SignalSample {
  const SignalSample({required this.seq, this.current, this.glucose});
  final int seq;
  final double? current;
  final double? glucose;
}

/// E01：The end of the preheating period (the end of the preheating time) 1/4，product specifications 90–120min）internally continuous 15 minute current < 0.5nA。
bool detectE01(List<SignalSample> warmup, int warmupMinutes) {
  final lo = warmupMinutes - warmupMinutes ~/ 4;
  final xs =
      warmup
          .where(
            (s) => s.seq >= lo && s.seq <= warmupMinutes && s.current != null,
          )
          .toList()
        ..sort((a, b) => a.seq.compareTo(b.seq));
  var run = 0;
  int? prev;
  for (final s in xs) {
    if (s.current! < kE01LowCurrentNa) {
      run = (prev != null && s.seq == prev + 1) ? run + 1 : 1;
    } else {
      run = 0;
    }
    if (run >= kE01ConsecutiveMin) return true;
    prev = s.seq;
  }
  return false;
}

/// E02：Second half of preheating (product specifications 60–120min）internal current > 30nA The proportion of more than 50%。
bool detectE02(List<SignalSample> warmup, int warmupMinutes) {
  final lo = warmupMinutes ~/ 2;
  final xs = warmup
      .where((s) => s.seq >= lo && s.seq <= warmupMinutes && s.current != null)
      .toList();
  if (xs.isEmpty) return false;
  final high = xs.where((s) => s.current! > kE02HighCurrentNa).length;
  return high / xs.length > 0.5;
}

/// E03：The most recent wearing period 15 Tiaoli ≥ 12 blood sugar strip < 0.2。
bool detectE03(List<SignalSample> recent) {
  final xs = recent.where((s) => s.glucose != null).toList();
  if (xs.length < kE03Window) return false;
  final tail = xs.sublist(xs.length - kE03Window);
  final low = tail.where((s) => s.glucose! < kE03LowGlucose).length;
  return low >= kE03LowCountThreshold;
}
