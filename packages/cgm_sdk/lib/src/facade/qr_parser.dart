import 'package:cgm_sdk/src/domain/device_scan_result.dart'
    show macFromDeviceId;
import 'package:cgm_sdk/src/facade/errors.dart';
import 'package:cgm_sdk/src/facade/models.dart';

/// Parse device QR code (interface 5）。
///
/// Format from《CGM Project algorithm usage documentation》§5.1：
/// `sendSn,deviceName,receiveSn,slope,intercept,l3,l4,l5,g3,g4,g5`，
/// like `1,CGM-E278CF00FD3B,-5,2.8632,-0.04,4,4,6,6,9,9`；deviceName = `CGM-Device number`，
/// list[3]=slope→tempCoef1、list[4]=intercept→tempCoef2；list[5~10] of L3~G5 Algorithm library
/// V1.2.4 Deprecated and no longer parsed。
/// There is no form in the QR code / Validity field：form according to full Return (when the host background knows the form, the background shall prevail），
/// expireDate is empty. Also accepts raw device numbers / `CGM-Device number`（No calibration at this time）。
QrInfo parseQrCode(String qr) {
  final s = qr.trim();
  if (s.isEmpty) throw CgmSdkException(CgmErrorCode.qrInvalid);
  final parts = s.split(',').map((e) => e.trim()).toList();
  if (parts.length == 1) {
    final id = _deviceIdFrom(parts[0]);
    if (id == null) throw CgmSdkException(CgmErrorCode.qrInvalid);
    return QrInfo(deviceId: id, form: 'full');
  }
  if (parts.length < 5) {
    throw CgmSdkException(
      CgmErrorCode.qrInvalid,
      'Insufficient QR code fields',
    );
  }
  final id = _deviceIdFrom(parts[1]);
  if (id == null) {
    throw CgmSdkException(
      CgmErrorCode.qrInvalid,
      'The device number is invalid: ${parts[1]}',
    );
  }
  final k = double.tryParse(parts[3]);
  final b = double.tryParse(parts[4]);
  if (k == null || b == null) {
    throw CgmSdkException(
      CgmErrorCode.qrInvalid,
      'Calibration slope/intercept not a number',
    );
  }
  return QrInfo(
    deviceId: id,
    form: 'full',
    transmitterSn: parts[0].isEmpty ? null : parts[0],
    sensorSn: parts[2].isEmpty ? null : parts[2],
    calibration: AlgoParams(tempCoef1: k, tempCoef2: b),
  );
}

/// `CGM-XXXX` / bare 12 Bit hex / with colon MAC → 12 Bit device number; illegal return null。
String? _deviceIdFrom(String raw) {
  var v = raw.trim().toUpperCase();
  if (v.startsWith('CGM-')) v = v.substring(4);
  v = v.replaceAll(':', '');
  return macFromDeviceId(v) == null ? null : v;
}
