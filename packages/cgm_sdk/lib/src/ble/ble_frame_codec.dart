import 'dart:typed_data';

import 'package:cgm_sdk/src/constants/app_constants.dart';

/// This is thrown when the device frame parsing fails, and the caller decides to discard the entire frame or log it accordingly.。
class BleFrameException implements Exception {
  final String reason;
  final Uint8List bytes;

  BleFrameException(this.reason, this.bytes);

  @override
  String toString() =>
      'BleFrameException($reason, bytes=${BleFrameCodec.toHex(bytes)})';
}

/// one piece 14 Byte measurement record, the smallest unit cut out from the frame payload。
class GlucoseRecord {
  /// Device timestamp in seconds。
  final int timestampSec;

  final int recordSeq;

  /// Electrode voltage in volts。
  final double voltage;

  /// Temperature, degrees Celsius。
  final double temperature;

  /// WE1 Original current, unit nA，i.e. algorithm dataProc of srcData。
  final double rawCurrent;

  /// Lactate value is not included in the blood sugar algorithm for the time being and is reserved for expansion.。
  final double lactate;

  const GlucoseRecord({
    required this.timestampSec,
    required this.recordSeq,
    required this.voltage,
    required this.temperature,
    required this.rawCurrent,
    required this.lactate,
  });
}

/// Parsing results: Carrying frame header, command number and several cut out records。
class ParsedFrame {
  /// Frame header：0x55 or 0xAA。
  final int head;

  /// Order number (No. 3 byte）。
  final int commandId;

  /// In the order given by the device, not sorted here。
  final List<GlucoseRecord> records;

  const ParsedFrame({
    required this.head,
    required this.commandId,
    required this.records,
  });
}

/// CLM equipment BLE Frame encoding and decoding, only frame splitting + Cut records。
///
/// Frame structure (little endian）：`[HEAD 0x55/0xAA] [LEN whole frame length] [CMD] [payload] [CHECKSUM]`，
/// Check byte = forward LEN-1 Byte sum and complement。payload by several articles 14 Byte records are spelled out, each：
/// Timestamp(4,Second) serial number(2) Voltage(2,mV) temperature(2,×10) WE1current(2,×100nA) lactic acid(2,×100)。
class BleFrameCodec {
  BleFrameCodec._();

  static const int frameHead55 = 0x55;
  static const int frameHeadAa = 0xAA;

  /// HEAD + LEN + CMD + CHECKSUM，Minimum frame length without any load。
  static const int minFrameLength = 4;

  /// The number of bytes in a single record, followed by [AppConstants.dataRecordBytes] Homology（14）。
  static const int recordBytes = AppConstants.dataRecordBytes;

  /// Parse a whole frame: check frame header/length/After the two’s complement checksum, press 14 Byte cut record。
  /// If there is less than one line at the end of the payload, it will be discarded as padding; frame header/length/Throw if verification is illegal [BleFrameException]，
  /// The entire frame is discarded and not fed to the algorithm。
  static ParsedFrame parse(Uint8List bytes) {
    if (bytes.length < minFrameLength) {
      throw BleFrameException(
        'Insufficient frame length $minFrameLength byte',
        bytes,
      );
    }

    final head = bytes[0];
    if (head != frameHead55 && head != frameHeadAa) {
      throw BleFrameException(
        'Illegal frame header 0x${head.toRadixString(16)}',
        bytes,
      );
    }

    final declaredLen = bytes[1];
    if (declaredLen != bytes.length) {
      throw BleFrameException(
        'Length mismatch: frame header declaration $declaredLen，actual ${bytes.length}',
        bytes,
      );
    }

    if (!_verifyChecksum(bytes)) {
      throw BleFrameException('Two’s complement checksum failed', bytes);
    }

    final commandId = bytes[2];

    // load = before removing 3 Byte frame header and end 1 Byte check
    final payload = Uint8List.sublistView(bytes, 3, bytes.length - 1);
    final records = <GlucoseRecord>[];
    var offset = 0;
    while (offset + recordBytes <= payload.length) {
      records.add(_readRecord(payload, offset));
      offset += recordBytes;
    }

    return ParsedFrame(head: head, commandId: commandId, records: records);
  }

  /// Checksum: ex LEN-1 Byte sum and complement `(~sum + 1) & 0xFF`，Compare with last byte。
  static bool _verifyChecksum(Uint8List bytes) {
    final last = bytes.length - 1;
    var sum = 0;
    for (var i = 0; i < last; i++) {
      sum += bytes[i];
    }
    final expected = (~sum + 1) & 0xFF;
    return bytes[last] == expected;
  }

  static GlucoseRecord _readRecord(Uint8List payload, int o) {
    return GlucoseRecord(
      timestampSec: _readUint32LE(payload, o + 0),
      recordSeq: _readUint16LE(payload, o + 4),
      voltage: _readUint16LE(payload, o + 6) / 1000.0,
      temperature: _readInt16LE(payload, o + 8) / 10.0,
      rawCurrent: _readInt16LE(payload, o + 10) / 100.0,
      lactate: _readInt16LE(payload, o + 12) / 100.0,
    );
  }

  static int _readUint16LE(Uint8List b, int o) => b[o] | (b[o + 1] << 8);

  static int _readInt16LE(Uint8List b, int o) {
    final v = _readUint16LE(b, o);
    return v >= 0x8000 ? v - 0x10000 : v;
  }

  static int _readUint32LE(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  /// [parse] The inverse of , framing numbers / For testing purposes. Fixed-point encoding must be [_readRecord] strict symmetry。
  static Uint8List encode(
    List<GlucoseRecord> records, {
    int head = frameHeadAa,
    int commandId = 0xB0,
  }) {
    final len = 3 + recordBytes * records.length + 1;
    assert(len <= 0xFF, 'LEN Single byte, too many records need to be framed');
    final out = Uint8List(len);
    out[0] = head & 0xFF;
    out[1] = len & 0xFF;
    out[2] = commandId & 0xFF;
    var o = 3;
    for (final r in records) {
      _writeUint32LE(out, o + 0, r.timestampSec);
      _writeUint16LE(out, o + 4, r.recordSeq);
      _writeUint16LE(out, o + 6, (r.voltage * 1000).round());
      _writeInt16LE(out, o + 8, (r.temperature * 10).round());
      _writeInt16LE(out, o + 10, (r.rawCurrent * 100).round());
      _writeInt16LE(out, o + 12, (r.lactate * 100).round());
      o += recordBytes;
    }
    out[len - 1] = checksumOf(Uint8List.sublistView(out, 0, len - 1));
    return out;
  }

  static void _writeUint16LE(Uint8List b, int o, int v) {
    b[o] = v & 0xFF;
    b[o + 1] = (v >> 8) & 0xFF;
  }

  static void _writeInt16LE(Uint8List b, int o, int v) =>
      _writeUint16LE(b, o, v & 0xFFFF);

  static void _writeUint32LE(Uint8List b, int o, int v) {
    b[o] = v & 0xFF;
    b[o + 1] = (v >> 8) & 0xFF;
    b[o + 2] = (v >> 16) & 0xFF;
    b[o + 3] = (v >> 24) & 0xFF;
  }

  /// Calculate the one’s complement check byte of a frame. Framing/for testing。
  static int checksumOf(List<int> frameWithoutChecksum) {
    var sum = 0;
    for (final v in frameWithoutChecksum) {
      sum += v & 0xFF;
    }
    return (~sum + 1) & 0xFF;
  }

  /// Byte to hexadecimal string, log/For abnormal use。
  static String toHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
