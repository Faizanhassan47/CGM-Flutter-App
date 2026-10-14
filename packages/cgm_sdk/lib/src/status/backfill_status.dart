import 'package:flutter/foundation.dart';

/// Recover after disconnection（0xD3 Pull in batches/0xD4 item by item + Algorithm replays the global state in progress。
///
/// The device number position at the top of the homepage accordingly displays ”Data is being updated, approx.Xminute」。value=null Not making up for it, not null is the remainder
/// Estimated minutes（≥1，Decrease with progress according to the current measured rate); algorithm replay(drain)Put them back after running them all null，
/// If you clear it in advance, ”the data is still being replenished, but the top column is gone” will appear. cold start/Change wear The multi-day historical replay is also posted here. Whoever reveals it first will be responsible for clearing it.。
class BackfillStatus {
  static final ValueNotifier<int?> etaMinutes = ValueNotifier<int?>(null)
    ..addListener(_markFinished);

  /// The time when the last backfill ended（[etaMinutes] Return from non-empty null that moment）。
  ///
  /// Topping up is to pour the history during the disconnection period into the database at once. A steep slope will appear in the time window after filling. This is not because the blood sugar is really changing rapidly.；
  /// Quick rise/Rapid drop judgment is always present [etaMinutes] Run after clearing, just blocking ”Replenishment in progress” is not enough，
  /// To block until that batch of data slides out of the time window, see [wasFilledWithin]。
  static DateTime? finishedAt;

  static void _markFinished() {
    if (etaMinutes.value == null) {
      finishedAt = DateTime.now();
      progress.value = null;
    }
  }

  /// The progress of the number of calibers（SDK facade progress For events）：kind=backfill Recover after disconnection / replay cold start or
  /// Recalculation after backfill；null=Not running. Follow [etaMinutes] Clear。
  static final ValueNotifier<({String kind, int done, int total})?> progress =
      ValueNotifier(null);

  /// Is it not yet the end of the latest replenishment? [window]（＝The time window is also mixed with replenishment.）。
  /// It is also true that the backfill is in progress。
  static bool wasFilledWithin(Duration window, {DateTime? now}) {
    if (etaMinutes.value != null) return true;
    final t = finishedAt;
    return t != null && (now ?? DateTime.now()).difference(t) < window;
  }

  /// According to the actual measured rate at the current stage (completed [done] time-consuming [sw]）leave the remainder [remaining] strip
  /// Converted into minutes to update the top bar（≥1，Decrease with progress）。done≤0 No rate to measure → Keep last displayed value。
  static void showMeasured({
    required Stopwatch sw,
    required int done,
    required int remaining,
    String kind = 'backfill',
  }) {
    if (done <= 0) return;
    progress.value = (kind: kind, done: done, total: done + remaining);
    final m = (remaining * (sw.elapsedMilliseconds / done) / 60000).ceil();
    etaMinutes.value = m < 1 ? 1 : m;
  }
}
