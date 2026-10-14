/// CGM Reason for rejection of verification activation。
enum ActivationReject {
  /// Insufficient voltage
  lowVoltage,

  /// The device has expired
  expired,

  /// Equipment has been used · Totally thrown away. There is currently no output, and connections will no longer be blocked when in use.。
  inUseFull,

  /// Equipment has been used · Half thrown. Not currently producing。
  inUseHalf,
}

/// Verification conclusion: passed [reject] for null，Can be activated; otherwise, the rejection reason is carried。
class ActivationVerdict {
  const ActivationVerdict.pass() : reject = null;

  const ActivationVerdict.rejected(ActivationReject this.reject);

  final ActivationReject? reject;

  bool get canActivate => reject == null;
}

/// CGM Verification activation gate: sufficient voltage（0xE1）and has not expired（expireDate），Any failure will result in rejection。
/// In use(0xE5)No gate，MAC Allow the connection if it matches, otherwise the device will be locked and unable to connect.。
ActivationVerdict checkActivation({
  required bool voltageSufficient,
  required bool expired,
}) {
  if (!voltageSufficient) {
    return const ActivationVerdict.rejected(ActivationReject.lowVoltage);
  }
  if (expired) {
    return const ActivationVerdict.rejected(ActivationReject.expired);
  }
  return const ActivationVerdict.pass();
}
