/// The binding activation process leaves three stages for the host: preparation before connection (such as positioning), and adjusting the back-end binding after passing the verification.、
/// Rewrite after successful activation. All three stages can be implemented empty; the corresponding timing in the service is ① Before / ④ / ⑤ Afterward, the same as before unpacking。
abstract class BindHooks {
  const BindHooks();

  /// `bindAndActivate` Adjust it as soon as you come in and before connecting to Bluetooth. Don’t waste time preparing to start here. await it。
  void onBindStart(BindStart start) {}

  /// Voltage/The validity period verification has passed and is adjusted before activation is issued. return abort Then disconnect the device and do not drop it into the inventory.。
  Future<BeforeActivateResult> beforeActivate(BindCheck check) async =>
      const BeforeActivateResult.proceed();

  /// Activation is successful, local wear record has been generated and post-deployed (return without blocking, abnormal silence)）。
  Future<void> afterActivate(int wearId) async {}
}

class BindStart {
  const BindStart({required this.bluetoothAddr, required this.at});

  final String bluetoothAddr;
  final DateTime at;
}

/// The on-site information that has been connected and verified is enough for the host to fill in the back-end binding request.。
class BindCheck {
  const BindCheck({
    required this.transmitterId,
    required this.transmitterSn,
    required this.sensorId,
    required this.sensorSn,
    required this.bluetoothAddr,
    required this.batteryMv,
    required this.inUse,
    required this.at,
  });

  final int transmitterId;
  final String transmitterSn;
  final int sensorId;
  final String sensorSn;
  final String bluetoothAddr;
  final int batteryMv;
  final bool inUse;
  final DateTime at;
}

class BeforeActivateResult {
  const BeforeActivateResult.proceed({this.wearId, this.preheatEndAt})
    : ok = true,
      message = null;

  const BeforeActivateResult.abort(String this.message)
    : ok = false,
      wearId = null,
      preheatEndAt = null;

  final bool ok;

  /// The reason for the suspension can be directly reported to the user.。
  final String? message;

  /// Backend assigned wear id / Preheating end time；null Use local generation。
  final int? wearId;
  final DateTime? preheatEndAt;
}
