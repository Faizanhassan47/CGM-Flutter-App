/// Equipment form: semi-throwable (transmitter can be reused + Sensor disposable）/ Fully disposable (all-in-one disposable）。
enum DeviceForm { half, full }

/// scanQrCode of instanceForm Three states: all thrown into one / half throw launcher / half throw sensor。
enum InstanceForm { allInOne, transmitter, sensor }

InstanceForm? instanceFormFrom(String? raw) {
  switch (raw) {
    case 'all_in_one':
      return InstanceForm.allInOne;
    case 'transmitter':
      return InstanceForm.transmitter;
    case 'sensor':
      return InstanceForm.sensor;
    default:
      return null;
  }
}

/// Device number(12 Bit hex,like E278D33B5AAB) → Bluetooth MAC(E2:78:D3:3B:5A:AB)。
/// Lianxin unified rules: device number / MAC / Bluetooth name(CGM-Device number)Same origin. Illegal format return null。
String? macFromDeviceId(String? deviceId) {
  final id = deviceId?.trim().toUpperCase();
  if (id == null || !RegExp(r'^[0-9A-F]{12}$').hasMatch(id)) return null;
  return [for (var i = 0; i < 12; i += 2) id.substring(i, i + 2)].join(':');
}

/// Device number → Bluetooth broadcast name `CGM-{Device number}`（Lianxin device naming rules）。
String bleNameFromDeviceId(String deviceId) =>
    'CGM-${deviceId.trim().toUpperCase()}';

/// scanQrCode Returned device instance usage status (background caliber）。
/// The usage status on the device side is determined by BLE 0xE5 Reset detection bit judgment (see activation_check）。
enum DeviceScanStatus {
  /// 0=Not bound, available
  unbound,

  /// 1=Bound / Already used
  bound,

  /// 2=Unbound
  unbinded,

  /// Not in library / The identification code is incorrect
  notFound,
}

DeviceScanStatus deviceScanStatusFrom(String? raw) {
  switch (raw) {
    case '0':
      return DeviceScanStatus.unbound;
    case '1':
      return DeviceScanStatus.bound;
    case '2':
      return DeviceScanStatus.unbinded;
    default:
      return DeviceScanStatus.notFound;
  }
}

/// scanQrCode The device instance information found (one instance at a time, the field is DeviceScanResultVO subset of）。
/// Half toss and scan twice (transmitter + sensor), throw all once (two id same）。
class DeviceScanResult {
  const DeviceScanResult({
    required this.instanceId,
    required this.status,
    required this.form,
    this.instanceFormType,
    this.instanceForm,
    this.instanceQrCode,
    this.expireDate,
    this.bluetoothAddr,
    this.transmitterNo,
    this.sensorNo,
    this.firmwareId,
    this.productNo,
    this.sensorAttr,
  });

  /// Instance primary key ID（DeviceScanResultVO.id）→ binding time transmitter_id/sensor_id
  final int instanceId;

  /// Background usage status（0/1/2）
  final DeviceScanStatus status;

  final DeviceForm form;

  /// three-state form（all_in_one/transmitter/sensor），Half throw and divert to the corresponding slot for use
  final InstanceForm? instanceFormType;

  /// Instance form original value（instanceForm，leave traces）
  final String? instanceForm;

  /// Identification code = The original value of the QR code can be used for query by scanning the code; it is not the serial number and is only used to provide information when the number is missing.。
  final String? instanceQrCode;

  /// Factory expiry date（expireDate，Used for verification overdue）
  final String? expireDate;

  /// Bluetooth address（transmitterAttr.bluetoothAddr，transmitter / Full throw belt）
  final String? bluetoothAddr;

  /// Transmitter number（transmitterAttr.transmitterNo）= Transmitter serial number true value。
  final String? transmitterNo;

  /// Probe number（sensorAttr.sensorNo）= Sensor serial number true value。
  final String? sensorNo;

  /// Bind the transmitter serial number sent to the backend DeviceBindDTO Request to take transmitterAttr.transmitterNo。
  /// Required. If the number is not recorded in the background, the identification code will be returned.。
  String get bindTransmitterSn => _sn(transmitterNo);

  /// Bind the sensor serial number sent and get sensorAttr.sensorNo。
  String get bindSensorSn => _sn(sensorNo);

  String _sn(String? no) {
    final v = no?.trim();
    return v != null && v.isNotEmpty ? v : (instanceQrCode ?? '');
  }

  /// firmware ID（transmitterAttr.firmwareId）
  final int? firmwareId;

  final String? productNo;

  /// Sensor factory calibration（sensorAttr）：k=Sensitivity/b=intercept/l3~g5 Segmentation parameters, feed algorithm
  /// setGluCalcParameter。Sensor slot only comes with transmitter/No calibration is null。
  final SensorAttr? sensorAttr;

  /// from backend DeviceScanResultVO parse；scanQrCode and monitoring-devices return same VO。
  factory DeviceScanResult.fromJson(Map<String, dynamic> data) {
    final form = instanceFormFrom(data['instanceForm'] as String?);
    final tx = data['transmitterAttr'];
    final txAttr = tx is Map ? tx : null;
    final se = data['sensorAttr'];
    final seAttr = se is Map ? se : null;
    return DeviceScanResult(
      instanceId: _dsrInt(data['id']) ?? 0,
      status: deviceScanStatusFrom(data['status']?.toString()),
      form: form == InstanceForm.allInOne ? DeviceForm.full : DeviceForm.half,
      instanceFormType: form,
      instanceForm: data['instanceForm'] as String?,
      instanceQrCode: data['instanceQrCode'] as String?,
      expireDate: data['expireDate'] as String?,
      productNo: data['productNo'] as String?,
      bluetoothAddr: normalizeBluetoothAddr(txAttr?['bluetoothAddr']),
      transmitterNo: txAttr?['transmitterNo'] as String?,
      sensorNo: seAttr?['sensorNo'] as String?,
      firmwareId: _dsrInt(txAttr?['firmwareId']),
      sensorAttr: seAttr == null
          ? null
          : SensorAttr(
              k: _dsrDouble(seAttr['k']),
              b: _dsrDouble(seAttr['b']),
              l3: _dsrDouble(seAttr['l3']),
              g3: _dsrDouble(seAttr['g3']),
              l4: _dsrDouble(seAttr['l4']),
              g4: _dsrDouble(seAttr['g4']),
              l5: _dsrDouble(seAttr['l5']),
              g5: _dsrDouble(seAttr['g5']),
            ),
    );
  }
}

/// snowflake ID The backend of other fields may be serialized into strings (to prevent JS loss of precision), compatible with String / num。
int? _dsrInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _dsrDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

/// Backend Bluetooth address may be without colon, normalized to with colon MAC；No 12 Bit hex Return as is。
String? normalizeBluetoothAddr(dynamic raw) {
  final s = raw is String ? raw.trim() : null;
  if (s == null || s.isEmpty) return null;
  return macFromDeviceId(s.replaceAll(':', '')) ?? s;
}

/// The sensor is factory calibrated, and the backend returns according to the identification code.：k=Sensitivity、b=intercept、l3~g5=Segmentation parameters。
class SensorAttr {
  const SensorAttr({
    this.k,
    this.b,
    this.l3,
    this.g3,
    this.l4,
    this.g4,
    this.l5,
    this.g5,
  });

  final double? k;
  final double? b;
  final double? l3;
  final double? g3;
  final double? l4;
  final double? g4;
  final double? l5;
  final double? g5;

  /// at least there k/b Only then can we get a valid calibration。
  bool get hasCalibration => k != null && b != null;
}

/// monitoring-devices a line of:Record under test = device instance(device) + Wearing record(wearRecord),Nested structure。
/// device may be null(Sensor single strip),Unable to connect automatically at this time。
class MonitoringDevice {
  const MonitoringDevice({required this.wearRecord, this.device});

  /// device instance,Contains Bluetooth address/Calibration。
  final DeviceScanResult? device;

  /// Wearing record(wearId / activateTime / Remaining term / monitoring status)。
  final WearRecord wearRecord;

  factory MonitoringDevice.fromJson(Map<String, dynamic> j) {
    final dev = j['device'];
    return MonitoringDevice(
      device: dev is Map
          ? DeviceScanResult.fromJson(dev.cast<String, dynamic>())
          : null,
      wearRecord: WearRecord.fromJson(
        (j['wearRecord'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

/// monitoring-devices Wearing records in(DeviceWearRecordVO subset)。
class WearRecord {
  const WearRecord({
    required this.wearId,
    required this.userId,
    this.accountId,
    this.transmitterId,
    this.sensorSn,
    this.activateTime,
    this.expectedExpireTime,
    this.status,
  });

  /// Wearing record ID(wearRecord.id)= blood sugar query wearId。
  final int wearId;
  final int userId;
  final int? accountId;

  /// Emitter instance ID(Throw all=device.id)。
  final int? transmitterId;
  final String? sensorSn;

  /// activation time(Beijing time,No time zone)→ algorithm startTs / days remaining anchor。
  final DateTime? activateTime;

  /// Estimated time of failure = activateTime + Wearing cycle(15 sky)。
  final DateTime? expectedExpireTime;

  /// 1=activation(Warming up) / 2=Monitoring(End of warm-up) / 3=unbundle。
  final String? status;

  /// If it is not unbound, it will be regarded as"Under test"(Including preheating 1 with monitoring 2)。
  bool get isActiveWear => status != null && status != '3';

  /// exist [now] Is the time point still within the validity period?(lack expectedExpireTime Time never stops)。
  bool notExpiredAt(DateTime now) =>
      expectedExpireTime == null || now.isBefore(expectedExpireTime!);

  factory WearRecord.fromJson(Map<String, dynamic> j) => WearRecord(
    wearId: _dsrInt(j['id']) ?? 0,
    userId: _dsrInt(j['userId']) ?? 0,
    accountId: _dsrInt(j['accountId']),
    transmitterId: _dsrInt(j['transmitterId']),
    sensorSn: j['sensorSn']?.toString(),
    activateTime: _parseBackendTime(j['activateTime']),
    expectedExpireTime: _parseBackendTime(j['expectedExpireTime']),
    status: j['status']?.toString(),
  );
}

/// The backend time looks like "2026-06-27 10:30:05"(Beijing time,No time zone)→ local DateTime,Illegal return null。
DateTime? _parseBackendTime(dynamic v) {
  if (v is! String) return null;
  final s = v.trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}
