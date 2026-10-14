import 'package:cgm_sdk/src/domain/wear_lifecycle_resolver.dart'
    show kWearWarmupMinutes;

/// SDK Runtime tunable parameters。App Do not touch it when using the core class directly (keep the compile-time default value and the behavior is the same as before unpacking)）；
/// facade `CgmSdk.init(config)` Override by host configuration。
class SdkTuning {
  SdkTuning._();

  /// Preheating time (minutes): preheating end time of the bound service, collection runner stage determination、pipeline of
  /// warmup_flag Shared by three places. default = [kWearWarmupMinutes]。
  static int warmupMinutes = kWearWarmupMinutes;

  /// Minimum voltage gate when bonded（mV），The voltage source is BLE 0xE1。App Currently a development file 500，formal standard 2800。
  ///
  /// This is the only place in the entire project where people are stopped on a voltage basis; the operation period is less than 2.3V Only ”low battery” is reported, and collection does not stop due to voltage.。
  static int bindMinBatteryMv = 500;

  static Duration get warmupDuration => Duration(minutes: warmupMinutes);
}
