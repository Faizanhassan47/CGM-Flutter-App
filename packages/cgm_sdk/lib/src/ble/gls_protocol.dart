import 'dart:math' as math;
import 'dart:typed_data';

/// Bluetooth SIG Glucose Service (GLS) / Glucose Profile (GLP) helpers.
/// Assigned numbers: Service 0x1808, Measurement 0x2A18, Context 0x2A34,
/// Feature 0x2A51, Record Access Control Point 0x2A52.
/// Also recognizes Continuous Glucose Monitoring Service 0x181F (separate adapter).
class GlsUuids {
  static const service = '1808';
  static const cgmService = '181f';
  static const measurement = '2a18';
  static const measurementContext = '2a34';
  static const feature = '2a51';
  static const racp = '2a52';
  static const deviceInfo = '180a';
  static const manufacturerName = '2a29';
  static const modelNumber = '2a24';
  static const serialNumber = '2a25';
  static const firmwareRevision = '2a26';
  static const hardwareRevision = '2a27';
}

class GlsMeasurement {
  const GlsMeasurement({
    required this.sequenceNumber,
    required this.measuredAt,
    required this.glucoseMgDl,
    required this.flags,
    this.contextFollows = false,
  });

  final int sequenceNumber;
  final DateTime measuredAt;
  final double? glucoseMgDl;
  final int flags;
  final bool contextFollows;
}

class GlsMeasurementContext {
  const GlsMeasurementContext({
    required this.sequenceNumber,
    required this.flags,
    this.carbohydrateId,
    this.carbohydrateKg,
    this.meal,
    this.tester,
    this.health,
    this.exerciseDurationSec,
    this.exerciseIntensityPercent,
    this.medicationId,
    this.medicationKg,
    this.hba1cPercent,
    this.notes,
  });

  final int sequenceNumber;
  final int flags;
  final int? carbohydrateId;
  final double? carbohydrateKg;
  final int? meal;
  final int? tester;
  final int? health;
  final int? exerciseDurationSec;
  final int? exerciseIntensityPercent;
  final int? medicationId;
  final double? medicationKg;
  final double? hba1cPercent;
  final String? notes;
}

class GlsRacpResponse {
  const GlsRacpResponse({
    required this.opCode,
    required this.operator,
    required this.requestOpCode,
    required this.responseCode,
  });

  final int opCode;
  final int operator;
  final int requestOpCode;
  final int responseCode;

  bool get isSuccess =>
      opCode == GlsProtocol.racpResponseCode &&
      (responseCode == GlsProtocol.racpSuccess ||
          responseCode == GlsProtocol.racpNoRecordsFound);

  String get message {
    return switch (responseCode) {
      GlsProtocol.racpSuccess => 'Success',
      GlsProtocol.racpOpcodeNotSupported => 'Op Code not supported',
      GlsProtocol.racpInvalidOperator => 'Invalid Operator',
      GlsProtocol.racpOperatorNotSupported => 'Operator not supported',
      GlsProtocol.racpInvalidOperand => 'Invalid Operand',
      GlsProtocol.racpNoRecordsFound => 'No records found',
      GlsProtocol.racpAbortUnsuccessful => 'Abort unsuccessful',
      GlsProtocol.racpProcedureNotCompleted => 'Procedure not completed',
      GlsProtocol.racpOperandNotSupported => 'Operand not supported',
      _ => 'Unknown response 0x${responseCode.toRadixString(16)}',
    };
  }
}

class GlsDeviceInfo {
  const GlsDeviceInfo({
    this.manufacturer,
    this.model,
    this.serial,
    this.firmware,
    this.hardware,
  });

  final String? manufacturer;
  final String? model;
  final String? serial;
  final String? firmware;
  final String? hardware;
}

enum BleProtocolKind { cgm181f, gls, fff0, unsupported }

class GlsProtocol {
  GlsProtocol._();

  static const int racpReportStoredRecords = 0x01;
  static const int racpAbortOperation = 0x02;
  static const int racpReportNumberOfRecords = 0x04;
  static const int racpResponseNumberOfRecords = 0x05;
  static const int racpResponseCode = 0x06;

  static const int racpOperatorNull = 0x00;
  static const int racpOperatorAll = 0x01;
  static const int racpOperatorLessOrEqual = 0x02;
  static const int racpOperatorGreaterOrEqual = 0x03;
  static const int racpOperatorWithinRange = 0x04;
  static const int racpOperatorFirst = 0x05;
  static const int racpOperatorLast = 0x06;

  static const int racpFilterSequenceNumber = 0x01;

  static const int racpSuccess = 0x01;
  static const int racpOpcodeNotSupported = 0x02;
  static const int racpInvalidOperator = 0x03;
  static const int racpOperatorNotSupported = 0x04;
  static const int racpInvalidOperand = 0x05;
  static const int racpNoRecordsFound = 0x06;
  static const int racpAbortUnsuccessful = 0x07;
  static const int racpProcedureNotCompleted = 0x08;
  static const int racpOperandNotSupported = 0x09;

  static const Duration procedureTimeout = Duration(seconds: 30);

  static bool uuidEndsWith(String uuid, String short) {
    final u = uuid.toLowerCase().replaceAll('-', '');
    final s = short.toLowerCase().replaceAll('-', '');
    return u == s || u.endsWith(s.padLeft(4, '0')) || u.endsWith(s);
  }

  static BleProtocolKind detectProtocol(Iterable<String> serviceUuids) {
    var has181f = false;
    var has1808 = false;
    var hasFff0 = false;
    for (final raw in serviceUuids) {
      if (uuidEndsWith(raw, GlsUuids.cgmService)) has181f = true;
      if (uuidEndsWith(raw, GlsUuids.service)) has1808 = true;
      if (raw.toLowerCase().contains('fff0')) hasFff0 = true;
    }
    if (has181f) return BleProtocolKind.cgm181f;
    if (has1808) return BleProtocolKind.gls;
    if (hasFff0) return BleProtocolKind.fff0;
    return BleProtocolKind.unsupported;
  }

  /// IEEE 11073-20601 SFLOAT (16-bit).
  static double? parseSfloat(int raw) {
    final v = raw & 0xFFFF;
    if (v == 0x07FF || v == 0x0800 || v == 0x07FE || v == 0x0802 || v == 0x0801) {
      return null;
    }
    var mantissa = v & 0x0FFF;
    if (mantissa >= 0x0800) mantissa -= 0x1000;
    var exponent = (v >> 12) & 0x0F;
    if (exponent >= 0x08) exponent -= 0x10;
    return mantissa * math.pow(10.0, exponent).toDouble();
  }

  static int encodeSfloatMgDl(double mgDl) {
    var mantissa = mgDl.round().clamp(-2048, 2047);
    const exponent = -5;
    final expNibble = exponent & 0x0F;
    if (mantissa < 0) mantissa += 0x1000;
    return ((expNibble << 12) | (mantissa & 0x0FFF)) & 0xFFFF;
  }

  static GlsMeasurement? parseMeasurement(List<int> bytes) {
    if (bytes.length < 10) return null;
    final flags = bytes[0] & 0xFF;
    final seq = bytes[1] | (bytes[2] << 8);
    var o = 3;
    if (bytes.length < o + 7) return null;
    final year = bytes[o] | (bytes[o + 1] << 8);
    final month = bytes[o + 2];
    final day = bytes[o + 3];
    final hour = bytes[o + 4];
    final minute = bytes[o + 5];
    final second = bytes[o + 6];
    o += 7;
    var offsetMin = 0;
    if ((flags & 0x01) != 0) {
      if (bytes.length < o + 2) return null;
      offsetMin = bytes[o] | (bytes[o + 1] << 8);
      if (offsetMin >= 0x8000) offsetMin -= 0x10000;
      o += 2;
    }
    DateTime base;
    try {
      base = DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      base = DateTime.now();
    }
    final at = base.add(Duration(minutes: offsetMin));

    double? mgDl;
    if ((flags & 0x02) != 0) {
      if (bytes.length < o + 2) return null;
      final sfloat = bytes[o] | (bytes[o + 1] << 8);
      final conc = parseSfloat(sfloat);
      o += 2;
      if (conc != null) {
        final molUnit = (flags & 0x04) != 0;
        mgDl = molUnit ? conc * 18.0182 : conc * 100000.0;
      }
      if (bytes.length >= o + 1) o += 1; // type-location
    }
    if ((flags & 0x08) != 0 && bytes.length >= o + 2) {
      o += 2; // sensor status annunciation
    }
    return GlsMeasurement(
      sequenceNumber: seq,
      measuredAt: at,
      glucoseMgDl: mgDl,
      flags: flags,
      contextFollows: (flags & 0x10) != 0,
    );
  }

  static GlsMeasurementContext? parseMeasurementContext(List<int> bytes) {
    if (bytes.length < 3) return null;
    final flags = bytes[0] & 0xFF;
    final seq = bytes[1] | (bytes[2] << 8);
    var o = 3;
    int? carbId;
    double? carbKg;
    int? meal;
    int? tester;
    int? health;
    int? exerciseSec;
    int? exercisePct;
    int? medId;
    double? medKg;
    double? hba1c;
    if ((flags & 0x01) != 0) {
      // extended flags
      if (bytes.length < o + 1) return null;
      o += 1;
    }
    if ((flags & 0x02) != 0) {
      if (bytes.length < o + 3) return null;
      carbId = bytes[o];
      carbKg = parseSfloat(bytes[o + 1] | (bytes[o + 2] << 8));
      o += 3;
    }
    if ((flags & 0x04) != 0) {
      if (bytes.length < o + 1) return null;
      meal = bytes[o++];
    }
    if ((flags & 0x08) != 0) {
      if (bytes.length < o + 1) return null;
      final packed = bytes[o++];
      tester = packed & 0x0F;
      health = (packed >> 4) & 0x0F;
    }
    if ((flags & 0x10) != 0) {
      if (bytes.length < o + 3) return null;
      exerciseSec = bytes[o] | (bytes[o + 1] << 8);
      exercisePct = bytes[o + 2];
      o += 3;
    }
    if ((flags & 0x20) != 0) {
      if (bytes.length < o + 3) return null;
      medId = bytes[o];
      medKg = parseSfloat(bytes[o + 1] | (bytes[o + 2] << 8));
      o += 3;
    }
    if ((flags & 0x40) != 0) {
      if (bytes.length < o + 2) return null;
      hba1c = parseSfloat(bytes[o] | (bytes[o + 1] << 8));
    }
    return GlsMeasurementContext(
      sequenceNumber: seq,
      flags: flags,
      carbohydrateId: carbId,
      carbohydrateKg: carbKg,
      meal: meal,
      tester: tester,
      health: health,
      exerciseDurationSec: exerciseSec,
      exerciseIntensityPercent: exercisePct,
      medicationId: medId,
      medicationKg: medKg,
      hba1cPercent: hba1c,
    );
  }

  static GlsRacpResponse? parseRacpResponse(List<int> bytes) {
    if (bytes.length < 4) return null;
    if ((bytes[0] & 0xFF) != racpResponseCode) return null;
    return GlsRacpResponse(
      opCode: bytes[0] & 0xFF,
      operator: bytes[1] & 0xFF,
      requestOpCode: bytes[2] & 0xFF,
      responseCode: bytes[3] & 0xFF,
    );
  }

  /// Build a proprietary-looking 0xB0 frame so the existing collection pipeline
  /// can ingest GLS glucose via reverse linear conversion.
  static Uint8List toLegacyB0Frame({
    required double glucoseMgDl,
    required int sequenceNumber,
    required DateTime at,
    double slope = 2.8632,
    double intercept = -0.04,
  }) {
    final mmol = glucoseMgDl / 18.0182;
    final currentNa = slope.abs() < 1e-9 ? 0.0 : (mmol - intercept) / slope;
    final ts = at.toUtc().millisecondsSinceEpoch ~/ 1000;
    final we1 = (currentNa * 100).round().clamp(-32768, 32767);
    final temp = 325;
    final voltage = 3000;
    int i16(int v) => v < 0 ? (v + 0x10000) & 0xFFFF : v & 0xFFFF;
    final body = <int>[
      0xAA,
      0x10,
      0xB0,
      ts & 0xFF,
      (ts >> 8) & 0xFF,
      (ts >> 16) & 0xFF,
      (ts >> 24) & 0xFF,
      sequenceNumber & 0xFF,
      (sequenceNumber >> 8) & 0xFF,
      voltage & 0xFF,
      (voltage >> 8) & 0xFF,
      temp & 0xFF,
      (temp >> 8) & 0xFF,
      i16(we1) & 0xFF,
      (i16(we1) >> 8) & 0xFF,
    ];
    var sum = 0;
    for (final b in body) {
      sum = (sum + b) & 0xFF;
    }
    body.add((0x100 - sum) & 0xFF);
    body[1] = body.length;
    return Uint8List.fromList(body);
  }

  static Uint8List racpReportAll() =>
      Uint8List.fromList([racpReportStoredRecords, racpOperatorAll]);

  /// Report records with sequence number >= [minSequence] (incremental sync).
  static Uint8List racpReportGreaterOrEqual(int minSequence) {
    final seq = minSequence.clamp(0, 0xFFFF);
    return Uint8List.fromList([
      racpReportStoredRecords,
      racpOperatorGreaterOrEqual,
      racpFilterSequenceNumber,
      seq & 0xFF,
      (seq >> 8) & 0xFF,
    ]);
  }

  static Uint8List racpAbort() =>
      Uint8List.fromList([racpAbortOperation, racpOperatorNull]);

  static List<int> buildMeasurementNotification({
    required int sequenceNumber,
    required DateTime at,
    required double glucoseMgDl,
    bool contextFollows = false,
  }) {
    final sfloat = encodeSfloatMgDl(glucoseMgDl);
    return [
      0x02 | (contextFollows ? 0x10 : 0x00),
      sequenceNumber & 0xFF,
      (sequenceNumber >> 8) & 0xFF,
      at.year & 0xFF,
      (at.year >> 8) & 0xFF,
      at.month,
      at.day,
      at.hour,
      at.minute,
      at.second,
      sfloat & 0xFF,
      (sfloat >> 8) & 0xFF,
      0x01,
    ];
  }

  static List<int> buildContextNotification({
    required int sequenceNumber,
    int meal = 1,
  }) {
    return [
      0x04, // meal present
      sequenceNumber & 0xFF,
      (sequenceNumber >> 8) & 0xFF,
      meal & 0xFF,
    ];
  }
}
