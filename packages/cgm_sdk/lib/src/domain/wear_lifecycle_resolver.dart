/// Wear life cycle stage, decide on real-time monitoring tab Which page does it fall on?：firstUse/expired → FirstUsePage、
/// warmingUp → WarmupPage Countdown、monitoring → HomePage。monitoring internal overrun/data
/// Intermediate segmentation is driven by real-time blood glucose data (see HomeState），Don’t judge here。
enum WearLifecycleStage { firstUse, warmingUp, monitoring, expired }

/// `user_wear_status_log.handle_status` value。
const int kWearStatusBound = 1; // Binding successful
const int kWearStatusWarmupDone = 2; // End of warm-up
const int kWearStatusUnbound = 3; // unbundle

/// Wear validity period 15 sky。
const int kWearLifetimeDays = 15;

/// Preheating time (minutes), the only definition in the entire project, all other references are derived from here。
///
/// Currently a development file 15 Minutes, product specifications must be changed before official packaging 120 minutes; with bound voltage gate (development file 500mV /
/// formal 2800mV）Switches of the same type, please check them together before shipping out the package。
///
/// Just change this number，`BindActivationService.preheatDuration` / `WarmupPage._total` /
/// `LinearAlgorithmGateway.warmupSeconds` Everybody follow。
const int kWearWarmupMinutes = 15;

/// Preheating time [Duration] form, which can be used directly by callers who need duration。
const Duration kWearWarmupDuration = Duration(minutes: kWearWarmupMinutes);

/// Derivation of life cycle stages from wear snapshots. Expiration client end press `activeTime + lifetimeDays` Forget it, don’t rely on it
/// Expired transaction (the device may be offline and unable to write data) log）；first = activeTime/lastWearTime All empty。
WearLifecycleStage resolveWearStage({
  required DateTime? activeTime,
  DateTime? lastWearTime,
  int? handleStatus,
  DateTime? now,
  required int lifetimeDays,
  required int warmupMinutes,
}) {
  now ??= DateTime.now();

  // No current activation Wear: never worn→First time; worn but currently without device→Expired and not renewed。
  if (activeTime == null) {
    return lastWearTime == null
        ? WearLifecycleStage.firstUse
        : WearLifecycleStage.expired;
  }

  // Unbound: Waiting to connect new device。
  if (handleStatus == kWearStatusUnbound) return WearLifecycleStage.expired;

  // It will automatically expire upon expiration (the client will keep in mind, according to the activation time) + Validity period; including expiration date）。
  final expireAt = activeTime.add(Duration(days: lifetimeDays));
  if (!now.isBefore(expireAt)) return WearLifecycleStage.expired;

  // End of warm-up = There is ”preheating end” flow, or the time has passed. Activate + Preheating time (including critical moments)）。
  final warmedUp =
      handleStatus == kWearStatusWarmupDone ||
      !now.isBefore(activeTime.add(Duration(minutes: warmupMinutes)));
  return warmedUp
      ? WearLifecycleStage.monitoring
      : WearLifecycleStage.warmingUp;
}
