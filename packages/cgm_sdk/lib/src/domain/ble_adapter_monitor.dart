/// Bluetooth adapter（System Bluetooth switch) status seam. The collection stops if Bluetooth is not turned on or is turned off midway through the collection.，
/// No more blood sugar. Real machine realizes walking flutter_blue_plus，test injection fake。
abstract class BleAdapterMonitor {
  /// Bluetooth adapter Is it currently enabled (synchronized snapshot）。
  /// Can’t decide（unknown / The channel is not ready) Keep it as ”open” to release it. If it is really closed, there will be off event added。
  bool get isOnNow;

  /// adapter Switch change flow: only in clear on / off occasional events，
  /// neglect unknown / turningOn / turningOff Intermediate state to avoid false triggering of start and stop due to jitter。
  Stream<bool> get onChanges;
}
