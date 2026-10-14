/// Front-end service control interface for continuous collection and uploading in the background。
///
/// Android Start a foreground service with resident notifications, pin the process to the foreground priority, and switch to other app successor
/// isolate of BLE Frame collection and batch upload timers are not Doze / Manufacturer power saving freeze。
/// iOS Without this concept, the background collection depends on `UIBackgroundModes: bluetooth-central`，The implementation is no-op。
/// test/desktop injection [NoopForegroundServiceController]。
abstract class ForegroundServiceController {
  /// Idempotent: Make sure the front-end service is running. If it is already running, correct the resident notification copy into the entry.。
  /// During the period of waiting for automatic unbinding, AutoUnbindService Call with your own copywriting, monitoring has stopped at that time。
  Future<void> ensureRunning({
    String title = 'Blood glucose monitoring in progress',
    String text =
        'Continuously receiving and uploading blood glucose data in the background',
  });

  /// Idempotent: Stop the foreground service. Collection stops completely (unbinding/maturity/Called when Bluetooth is turned off)。
  Future<void> stop();
}

/// desktop / The unit test is implemented with nothing: no platform front-end service is enabled.。
class NoopForegroundServiceController implements ForegroundServiceController {
  const NoopForegroundServiceController();

  @override
  Future<void> ensureRunning({String title = '', String text = ''}) async {}

  @override
  Future<void> stop() async {}
}
