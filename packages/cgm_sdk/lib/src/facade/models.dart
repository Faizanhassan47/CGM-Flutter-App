/// SDK external data object（《CGM SDK Interface Document” Chapter 5). Each object has `toMap` / `fromMap`，
/// native shell（Kotlin/Swift）through MethodChannel This is what is sent and received Map；Same time UTC millisecond timestamp。
library;

import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart' show AlgoTuning;

int? _ms(DateTime? t) => t?.toUtc().millisecondsSinceEpoch;

DateTime? _dt(Object? v) {
  if (v is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      v.toInt(),
      isUtc: true,
    ).toLocal();
  }
  if (v is String) return DateTime.tryParse(v)?.toLocal();
  return null;
}

double? _d(Object? v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

int? _i(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

/// Initial configuration (interface 1）。
class SdkConfig {
  const SdkConfig({
    this.logLevel = LogLevel.info,
    this.foregroundNotice = 'Blood glucose monitoring',
    this.minBatteryMv = 2800,
    this.warmupMinutes = 120,
  });

  final LogLevel logLevel;

  /// Android Front desk service resident notice copywriting。
  final String foregroundNotice;

  /// Minimum voltage when bonded（mV）。
  final int minBatteryMv;

  /// Preheating time (minutes）。
  final int warmupMinutes;

  factory SdkConfig.fromMap(Map<Object?, Object?>? m) {
    if (m == null) return const SdkConfig();
    return SdkConfig(
      logLevel: LogLevel.parse(m['logLevel'] as String?) ?? LogLevel.info,
      foregroundNotice:
          (m['foregroundNotice'] as String?) ?? 'Blood glucose monitoring',
      minBatteryMv: _i(m['minBatteryMv']) ?? 2800,
      warmupMinutes: _i(m['warmupMinutes']) ?? 120,
    );
  }
}

/// Log level (interface 24 / event 7）。
enum LogLevel {
  none(0),
  error(1),
  warn(2),
  info(3),
  debug(4);

  const LogLevel(this.rank);
  final int rank;

  static LogLevel? parse(String? s) {
    for (final l in values) {
      if (l.name == s) return l;
    }
    return null;
  }
}

/// Algorithm parameters (interface 5 / 8 / 15 / 16），Field alignment algorithm library V1.2.7 interface：
/// tempCoef1 / tempCoef2 / bgmBase Enter init，The rest is optional setXxx Adjustment items。
/// old version l3/g3/l4/g4/l5/g5 Deprecated (still exists in the QR code, not used by the algorithm library)，SDK No more collection）。
class AlgoParams {
  const AlgoParams({
    required this.tempCoef1,
    required this.tempCoef2,
    this.bgmBase,
    this.positiveSlope1,
    this.negativeSlope1,
    this.positiveSlope2,
    this.positiveSlope2Fixed = false,
    this.negativeSlope2,
    this.dayKalmanQ,
    this.dayKalmanR,
    this.nightKalmanQ,
    this.nightKalmanR,
  });

  /// Factory sensitivity k（QR code 4 part slope）→ Algorithm library init of tempcoef1。Required。
  final double tempCoef1;

  /// Factory intercept b（QR code 5 part intercept）→ Algorithm library init of tempcoef2。Required。
  final double tempCoef2;

  /// Finger blood reference → Algorithm library init of paramBGMbase。Not transmitted (or ≤0）SDK use 6.8 reveal all the details。
  final double? bgmBase;

  /// The following are the optional tuning parameters of the algorithm library:（setPositiveslope1/2、setNegativeslope1/2、
  /// setDayKalman、setNightKalman），Not passed on = If not adjusted, the algorithm library uses the built-in default。
  final double? positiveSlope1;
  final double? negativeSlope1;
  final double? positiveSlope2;

  /// setPositiveslope2 of bUseBgSet：true = Mandatory [positiveSlope2]、Not modified by the algorithm library。
  final bool positiveSlope2Fixed;
  final double? negativeSlope2;

  /// Kalman Q/R Must be passed in pairs。
  final double? dayKalmanQ, dayKalmanR, nightKalmanQ, nightKalmanR;

  AlgoTuning get tuning => AlgoTuning(
    positiveSlope1: positiveSlope1,
    negativeSlope1: negativeSlope1,
    positiveSlope2: positiveSlope2,
    positiveSlope2Fixed: positiveSlope2Fixed,
    negativeSlope2: negativeSlope2,
    dayKalmanQ: dayKalmanQ,
    dayKalmanR: dayKalmanR,
    nightKalmanQ: nightKalmanQ,
    nightKalmanR: nightKalmanR,
  );

  /// The reason is returned when the parameter is illegal, and the reason is returned if it is legal. null。
  String? get invalidReason {
    if ((dayKalmanQ == null) != (dayKalmanR == null)) {
      return 'dayKalmanQ / dayKalmanR Must be passed in pairs';
    }
    if ((nightKalmanQ == null) != (nightKalmanR == null)) {
      return 'nightKalmanQ / nightKalmanR Must be passed in pairs';
    }
    return null;
  }

  Map<String, Object?> toMap() => {
    'tempCoef1': tempCoef1,
    'tempCoef2': tempCoef2,
    'bgmBase': bgmBase,
    'positiveSlope1': positiveSlope1,
    'negativeSlope1': negativeSlope1,
    'positiveSlope2': positiveSlope2,
    'positiveSlope2Fixed': positiveSlope2Fixed,
    'negativeSlope2': negativeSlope2,
    'dayKalmanQ': dayKalmanQ,
    'dayKalmanR': dayKalmanR,
    'nightKalmanQ': nightKalmanQ,
    'nightKalmanR': nightKalmanR,
  };

  /// tempCoef1 / tempCoef2 Missing return null（= No valid calibration）。
  static AlgoParams? fromMap(Map<Object?, Object?>? m) {
    if (m == null) return null;
    final k = _d(m['tempCoef1']);
    final b = _d(m['tempCoef2']);
    if (k == null || b == null) return null;
    return AlgoParams(
      tempCoef1: k,
      tempCoef2: b,
      bgmBase: _d(m['bgmBase']),
      positiveSlope1: _d(m['positiveSlope1']),
      negativeSlope1: _d(m['negativeSlope1']),
      positiveSlope2: _d(m['positiveSlope2']),
      positiveSlope2Fixed: m['positiveSlope2Fixed'] == true,
      negativeSlope2: _d(m['negativeSlope2']),
      dayKalmanQ: _d(m['dayKalmanQ']),
      dayKalmanR: _d(m['dayKalmanR']),
      nightKalmanQ: _d(m['nightKalmanQ']),
      nightKalmanR: _d(m['nightKalmanR']),
    );
  }
}

/// parseQrCode the result of (interface 5）。
class QrInfo {
  const QrInfo({
    required this.deviceId,
    required this.form,
    this.calibration,
    this.expireDate,
    this.transmitterSn,
    this.sensorSn,
  });

  /// 12 bit device number。
  final String deviceId;

  /// half / full。
  final String form;
  final AlgoParams? calibration;
  final DateTime? expireDate;
  final String? transmitterSn;
  final String? sensorSn;

  Map<String, Object?> toMap() => {
    'deviceId': deviceId,
    'form': form,
    'calibration': calibration?.toMap(),
    'expireDate': _ms(expireDate),
    'transmitterSn': transmitterSn,
    'sensorSn': sensorSn,
  };
}

/// A device scanned (interface 6）。
class ScanDevice {
  const ScanDevice({
    required this.deviceId,
    required this.name,
    required this.bleId,
    required this.rssi,
  });

  final String deviceId;
  final String name;

  /// Android=MAC，iOS=System assigned UUID。
  final String bleId;
  final int rssi;

  Map<String, Object?> toMap() => {
    'deviceId': deviceId,
    'name': name,
    'bleId': bleId,
    'rssi': rssi,
  };
}

/// Wearing record (interface 8 / 9 / 13）。
class WearInfo {
  const WearInfo({
    required this.wearId,
    required this.deviceId,
    required this.bleId,
    required this.form,
    required this.activatedAt,
    required this.warmupEndAt,
    required this.expiresAt,
    this.calibration,
    this.transmitterSn,
    this.sensorSn,
  });

  final int wearId;
  final String deviceId;
  final String bleId;
  final String form;
  final DateTime activatedAt;
  final DateTime warmupEndAt;
  final DateTime expiresAt;
  final AlgoParams? calibration;
  final String? transmitterSn;
  final String? sensorSn;

  Map<String, Object?> toMap() => {
    'wearId': wearId,
    'deviceId': deviceId,
    'bleId': bleId,
    'form': form,
    'activatedAt': _ms(activatedAt),
    'warmupEndAt': _ms(warmupEndAt),
    'expiresAt': _ms(expiresAt),
    'calibration': calibration?.toMap(),
    'transmitterSn': transmitterSn,
    'sensorSn': sensorSn,
  };

  /// wearId / deviceId / activatedAt Return if one is missing null。
  static WearInfo? fromMap(Map<Object?, Object?>? m) {
    if (m == null) return null;
    final wearId = _i(m['wearId']);
    final deviceId = m['deviceId'] as String?;
    final activatedAt = _dt(m['activatedAt']);
    if (wearId == null || deviceId == null || activatedAt == null) return null;
    return WearInfo(
      wearId: wearId,
      deviceId: deviceId,
      bleId: (m['bleId'] as String?) ?? '',
      form: (m['form'] as String?) ?? 'full',
      activatedAt: activatedAt,
      warmupEndAt: _dt(m['warmupEndAt']) ?? activatedAt,
      expiresAt: _dt(m['expiresAt']) ?? activatedAt,
      calibration: AlgoParams.fromMap(
        m['calibration'] as Map<Object?, Object?>?,
      ),
      transmitterSn: m['transmitterSn'] as String?,
      sensorSn: m['sensorSn'] as String?,
    );
  }
}

/// Device information (interface 14）。
class CgmDeviceInfo {
  const CgmDeviceInfo({
    required this.deviceId,
    required this.firmware,
    required this.batteryMv,
    required this.latestSeq,
    required this.measuring,
    required this.measuredSec,
  });

  final String deviceId;
  final String firmware;
  final int batteryMv;
  final int latestSeq;
  final bool measuring;
  final int measuredSec;

  Map<String, Object?> toMap() => {
    'deviceId': deviceId,
    'firmware': firmware,
    'batteryMv': batteryMv,
    'latestSeq': latestSeq,
    'measuring': measuring,
    'measuredSec': measuredSec,
  };
}

/// A blood glucose record (interface 17 / 18 / 19、event 3）。
class GlucoseSample {
  const GlucoseSample({
    required this.wearId,
    required this.seq,
    required this.measuredAt,
    required this.value,
    required this.warmup,
    required this.abnormal,
    required this.source,
    this.rawCurrent,
    this.temperature,
    this.voltage,
  });

  final int wearId;
  final int seq;
  final DateTime measuredAt;

  /// blood sugar mmol/L；abnormal behavior null。
  final double? value;
  final bool warmup;
  final bool abnormal;

  /// live / backfill / replay。
  final String source;
  final double? rawCurrent;
  final double? temperature;

  /// Voltage mV。
  final double? voltage;

  Map<String, Object?> toMap() => {
    'wearId': wearId,
    'seq': seq,
    'measuredAt': _ms(measuredAt),
    'value': value,
    'warmup': warmup,
    'abnormal': abnormal,
    'source': source,
    'rawCurrent': rawCurrent,
    'temperature': temperature,
    'voltage': voltage,
  };

  static GlucoseSample? fromMap(Map<Object?, Object?>? m) {
    if (m == null) return null;
    final at = _dt(m['measuredAt']);
    if (at == null) return null;
    return GlucoseSample(
      wearId: _i(m['wearId']) ?? 0,
      seq: _i(m['seq']) ?? 0,
      measuredAt: at,
      value: _d(m['value']),
      warmup: m['warmup'] == true,
      abnormal: m['abnormal'] == true,
      source: (m['source'] as String?) ?? 'live',
      rawCurrent: _d(m['rawCurrent']),
      temperature: _d(m['temperature']),
      voltage: _d(m['voltage']),
    );
  }
}

/// Device raw data (interface 20）。
class RawSample {
  const RawSample({
    required this.wearId,
    required this.seq,
    required this.measuredAt,
    this.current,
    this.temperature,
    this.voltage,
    this.lactate,
  });

  final int wearId;
  final int seq;
  final DateTime measuredAt;
  final double? current;
  final double? temperature;

  /// Voltage mV。
  final double? voltage;

  /// Lactic acid; the lactic acid in the current firmware frame is not dropped into the library and is always null。
  final double? lactate;

  Map<String, Object?> toMap() => {
    'wearId': wearId,
    'seq': seq,
    'measuredAt': _ms(measuredAt),
    'current': current,
    'temperature': temperature,
    'voltage': voltage,
    'lactate': lactate,
  };
}

/// connection status (event 1）。
enum CgmConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
}

/// device status (event 2）。
class DeviceStatus {
  const DeviceStatus({
    required this.connected,
    this.batteryMv,
    this.temperature,
    this.latestSeq,
    required this.measuring,
    required this.flashFull,
    required this.warmupRemainingMin,
    required this.remainingDays,
    this.abnormal,
  });

  final bool connected;
  final int? batteryMv;
  final double? temperature;
  final int? latestSeq;
  final bool measuring;
  final bool flashFull;
  final int warmupRemainingMin;
  final int remainingDays;

  /// deviceFault / lowBattery / dataAbnormal / dataInterrupted；Normally null。
  final String? abnormal;

  Map<String, Object?> toMap() => {
    'connected': connected,
    'batteryMv': batteryMv,
    'temperature': temperature,
    'latestSeq': latestSeq,
    'measuring': measuring,
    'flashFull': flashFull,
    'warmupRemainingMin': warmupRemainingMin,
    'remainingDays': remainingDays,
    'abnormal': abnormal,
  };
}

/// Algorithm complete output (event 4）。
class AlgoResult {
  const AlgoResult({
    required this.seq,
    required this.value,
    required this.current,
    required this.currentIirFilter,
    required this.currentMedianFilter,
    required this.currentBase,
    required this.sensitivityUsed,
    required this.dayKalmanQ,
    required this.dayKalmanR,
    required this.nightKalmanQ,
    required this.nightKalmanR,
    this.currentRemoveSqueeze1 = 0,
    this.currentRemoveSqueeze2 = 0,
    this.glucosePre = 0,
  });

  final int seq;
  final double value;
  final double current;
  final double currentIirFilter;
  final double currentMedianFilter;
  final double currentBase;
  final double sensitivityUsed;
  final double dayKalmanQ, dayKalmanR, nightKalmanQ, nightKalmanR;

  /// Current value after squeezing noise removal 1 / 2、Predict blood glucose levels (algorithm library V1.2.7 New）。
  final double currentRemoveSqueeze1, currentRemoveSqueeze2, glucosePre;

  Map<String, Object?> toMap() => {
    'seq': seq,
    'value': value,
    'current': current,
    'currentIirFilter': currentIirFilter,
    'currentMedianFilter': currentMedianFilter,
    'currentBase': currentBase,
    'sensitivityUsed': sensitivityUsed,
    'dayKalmanQ': dayKalmanQ,
    'dayKalmanR': dayKalmanR,
    'nightKalmanQ': nightKalmanQ,
    'nightKalmanR': nightKalmanR,
    'currentRemoveSqueeze1': currentRemoveSqueeze1,
    'currentRemoveSqueeze2': currentRemoveSqueeze2,
    'glucosePre': glucosePre,
  };
}

/// progress(event 5）：kind = warmup / backfill / replay。
class ProgressEvent {
  const ProgressEvent({
    required this.kind,
    required this.done,
    required this.total,
  });
  final String kind;
  final int done;
  final int total;

  Map<String, Object?> toMap() => {'kind': kind, 'done': done, 'total': total};
}

/// Errors and warnings (events 6）。
class SdkErrorEvent {
  const SdkErrorEvent({
    required this.code,
    required this.severity,
    required this.message,
  });
  final String code;
  final String severity;
  final String message;

  Map<String, Object?> toMap() => {
    'code': code,
    'severity': severity,
    'message': message,
  };
}

/// SDK log(event 7）。
class SdkLogEvent {
  const SdkLogEvent({
    required this.at,
    required this.level,
    required this.tag,
    required this.message,
  });
  final DateTime at;
  final LogLevel level;
  final String tag;
  final String message;

  Map<String, Object?> toMap() => {
    'at': _ms(at),
    'level': level.name,
    'tag': tag,
    'message': message,
  };
}

/// Map Time field parsing in (for facade/Channel multiplexing）。
DateTime? parseSdkTime(Object? v) => _dt(v);
