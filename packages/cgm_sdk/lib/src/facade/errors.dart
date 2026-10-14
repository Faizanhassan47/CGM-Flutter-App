/// SDK External error code, with《CGM SDK Interface Document》Chapter 6 One-to-one correspondence；[severity] for the level in the document。
enum CgmErrorCode {
  notInitialized('E_NOT_INITIALIZED', 'fatal', 'Please call first init'),
  notImplemented(
    'E_NOT_IMPLEMENTED',
    'fatal',
    'This interface is not provided in the current version',
  ),
  permissionDenied(
    'E_PERMISSION_DENIED',
    'fatal',
    'Bluetooth permission not granted',
  ),
  bleUnavailable(
    'E_BLE_UNAVAILABLE',
    'fatal',
    'This machine does not support Bluetooth',
  ),
  bleOff('E_BLE_OFF', 'fatal', 'Bluetooth is not turned on'),
  qrInvalid('E_QR_INVALID', 'fatal', 'The QR code format is incorrect'),
  deviceNotFound('E_DEVICE_NOT_FOUND', 'fatal', 'Device not found'),
  connectFailed('E_CONNECT_FAILED', 'fatal', 'Device connection failed'),
  lowVoltage(
    'E_LOW_VOLTAGE',
    'fatal',
    'The device voltage is too low and cannot be bound',
  ),
  deviceExpired('E_DEVICE_EXPIRED', 'fatal', 'The device has expired'),
  bindRejected('E_BIND_REJECTED', 'fatal', 'Binding aborted'),
  notBound('E_NOT_BOUND', 'fatal', 'The device has not been bound yet'),
  noCalibration('E_NO_CALIBRATION', 'fatal', 'Missing calibration parameters'),
  algoInitFailed(
    'E_ALGO_INIT_FAILED',
    'fatal',
    'Algorithm library initialization failed',
  ),
  algoCalcFailed(
    'E_ALGO_CALC_FAILED',
    'warn',
    'This blood sugar calculation failed',
  ),
  frameInvalid('E_FRAME_INVALID', 'warn', 'Invalid data frame received'),
  backfillIncomplete(
    'E_BACKFILL_INCOMPLETE',
    'warn',
    'Not all replenishment completed',
  ),
  deviceFault(
    'E_DEVICE_FAULT',
    'fatal',
    'Equipment failure, monitoring has been interrupted',
  ),
  flashFull(
    'E_FLASH_FULL',
    'fatal',
    'The device storage is full and measurement has been stopped.',
  ),
  batteryLow('E_BATTERY_LOW', 'warn', 'Device battery is too low'),
  currentLow(
    'E_CURRENT_LOW',
    'warn',
    'Abnormal monitoring data (current is too low）',
  ),
  signalNoisy(
    'E_SIGNAL_NOISY',
    'warn',
    'Abnormal monitoring data (signal noise is too large)）',
  ),
  dataInterrupted('E_DATA_INTERRUPTED', 'warn', 'Data connection in progress'),
  deviceNearExpiry(
    'E_DEVICE_NEAR_EXPIRY',
    'info',
    'The remaining validity period of the device is insufficient. 3 sky',
  ),
  deviceExpiredAuto(
    'E_DEVICE_EXPIRED_AUTO',
    'fatal',
    'Equipment wear has expired',
  ),
  storageFailed(
    'E_STORAGE_FAILED',
    'fatal',
    'The local database cannot be opened or writing fails',
  ),
  busy('E_BUSY', 'warn', 'The previous operation has not been completed yet'),
  invalidArgument('E_INVALID_ARGUMENT', 'fatal', 'Parameter is illegal');

  const CgmErrorCode(this.code, this.severity, this.defaultMessage);

  /// The error code string in the document, such as `E_BLE_OFF`。
  final String code;

  /// fatal / warn / info。
  final String severity;

  final String defaultMessage;

  static CgmErrorCode? fromCode(String code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Exception thrown when interface call fails：[code] Corresponding error code，[message] Can be displayed directly。
class CgmSdkException implements Exception {
  CgmSdkException(this.code, [String? message])
    : message = message ?? code.defaultMessage;

  final CgmErrorCode code;
  final String message;

  @override
  String toString() => '${code.code}: $message';
}
