import 'dart:typed_data';

import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';

/// CGM Device command sending and receiving codec。
class CgmCommand {
  CgmCommand._();

  static const int reqHead = 0x55;
  static const int respHead = 0xAA;

  static const int cmdReadVoltage = 0xE1;
  static const int cmdReadReset = 0xE5;
  static const int cmdReadVersion = 0xE7;
  static const int cmdStartMeasure = 0xD1;

  /// Read the latest measurement data SN + Measurement status（0xE3）：Whether it is measuring, latest serial number, measured time。
  static const int cmdReadLatestSn = 0xE3;

  /// Read single frame measurement data（0xD4）：according to SN Read a frame, the response field layout is the same 0xB0。
  static const int cmdReadSingle = 0xD4;

  /// Read multiple frames of data（0xD3）：from start SN Read the latest SN，Confirm to go FFF1、Data frame streaming FFF2（protocol 4.2）。
  static const int cmdReadMulti = 0xD3;

  /// Write measurement parameters（0xC4）：If not, the equipment will"Measuring"But the frame is not output according to the period, and it must be sent before starting the measurement.。
  static const int cmdMeasureParams = 0xC4;

  /// Hall control（0xC0）：locking(0x00)/Unlock(0x01)。
  static const int cmdHallControl = 0xC0;

  /// Measurement data is proactively reported (the device pushes one piece every minute, protocol 6.1）。Real-time current source。
  static const int cmdMeasureReport = 0xB0;

  /// equipment FLASH Overflow proactive reporting (protocol 6.3）：MCU internal FLASH When the storage is full, the device stops measuring and pushes this。
  /// After that, the device will no longer 0xB0，The performance is the same as disconnection, and reconnection is useless.。
  static const int cmdFlashOverflow = 0xF1;

  /// 0xF1 overflow flag：Data[0]（whole frame 3 byte）== 0x44 express FLASH Space is full。
  static const int flashFullFlag = 0x44;

  /// A history record on the device FLASH The number of bytes occupied (protocol 4.2：0xD3 each group 14 byte）。
  /// Cooperate 0xE0「read FLASH ”Remaining space” can be converted into how many minutes can be measured.。
  ///
  /// 0xE0 Not yet implemented: protocol 5.1 Example of ”remaining 120000 byte：AA 0D E0 00 C0 D4 01 00 …」Instead of
  /// formula `Data[3] + Data[4]<<8 + Data[5]<<16 + Data[6]<<24` One byte difference (according to the formula
  /// 30720000，Move the starting point to frame number 4 Bytes are 120000），No analysis will be written before the caliber is confirmed.。
  static const int flashBytesPerRecord = 14;

  /// 0xF1 Is the payload ”full?”」。
  static bool flashFullFrom(List<int> payload) =>
      payload.isNotEmpty && payload[0] == flashFullFlag;

  /// Is the whole frame「FLASH Actively report when the balance is full（`AA 0D F1 44 …`，protocol 6.3）。
  /// The notification callback is divided according to the command number to avoid mistaking it as an ordinary non-measurement frame and discarding it.。
  static bool isFlashOverflowFrame(List<int> v) =>
      v.length >= 4 &&
      v[0] == respHead &&
      v[2] == cmdFlashOverflow &&
      v[3] == flashFullFlag;

  /// 0xE0 Number of bytes remaining in the response：Data[0..3] little endian。
  static int flashFreeBytesFrom(List<int> payload) {
    if (payload.length < 4) return 0;
    return payload[0] |
        (payload[1] << 8) |
        (payload[2] << 16) |
        (payload[3] << 24);
  }

  /// Read command data segment length: whole frame LEN=0x0D（13），data segment 9 byte。
  static const int infoDataLen = 9;

  /// Group a command frame：HEAD(0x55) + LEN + CMD + DATA + CS。
  static Uint8List buildCommand(int cmd, {List<int> data = const []}) {
    final len = 3 + data.length + 1;
    final body = <int>[reqHead, len, cmd, ...data];
    return Uint8List.fromList([...body, BleFrameCodec.checksumOf(body)]);
  }

  /// Read battery voltage request（0xE1）。
  static Uint8List buildReadVoltage() =>
      buildCommand(cmdReadVoltage, data: List.filled(infoDataLen, 0));

  /// Read reset detection request（0xE5）。
  static Uint8List buildReadReset() =>
      buildCommand(cmdReadReset, data: List.filled(infoDataLen, 0));

  /// Write reply bit information（0xE5）：resetCount≠1 The value reported by the device is written back as it is, and the device clears the abnormal reset.
  /// After marking, it is recorded in cycles. data segment=Number of resets(1)+reset flag(2,little endian)+6 reserve。
  static Uint8List buildResetResetInfo(int resetCount, int resetFlag) =>
      buildCommand(
        cmdReadReset,
        data: [
          resetCount & 0xFF,
          resetFlag & 0xFF,
          (resetFlag >> 8) & 0xFF,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      );

  /// Read software version request（0xE7），No data segment。
  static Uint8List buildReadVersion() => buildCommand(cmdReadVersion);

  /// Read the latest SN + Measurement status request（0xE3）。
  static Uint8List buildReadLatestSn() =>
      buildCommand(cmdReadLatestSn, data: List.filled(infoDataLen, 0));

  /// Read single frame data request（0xD4）：before data segment 2 byte = start SN（little endian), the rest are complemented 0。
  static Uint8List buildReadSingle(int sn) => buildCommand(
    cmdReadSingle,
    data: [sn & 0xFF, (sn >> 8) & 0xFF, 0, 0, 0, 0, 0, 0, 0],
  );

  /// Read multi-frame data request（0xD3）：before data segment 2 byte = start SN（little endian), the rest are complemented 0。
  static Uint8List buildReadMulti(int sn) => buildCommand(
    cmdReadMulti,
    data: [sn & 0xFF, (sn >> 8) & 0xFF, 0, 0, 0, 0, 0, 0, 0],
  );

  /// 0xD3 end frame: protocol 4.2 Write LEN=3，Firmware released LEN=5（SN=0x7FFF Sentinel), recognize both。
  /// data frame LEN smallest 18（1 Group 14 bytes), there will be no misjudgment。
  static bool isMultiDataEnd(List<int> f) =>
      f.length >= 4 &&
      f[0] == respHead &&
      (f[1] == 0x03 || f[1] == 0x05) &&
      f[2] == cmdReadMulti &&
      f[3] == 0xFF;

  /// parse 0xD3 data frame（`AA LEN D3 [14byte×n] CS`，protocol 4.2）for record list。
  /// Little endian per group: timestamp(4) SN(2) Voltage(2,mV) temperature(2,×10) WE1(2,×100nA) lactic acid(2,×100)。
  /// The number of groups is calculated based on the actual frame length to tolerate LEN Unmatched firmware; verification failure throws [BleFrameException]。
  static List<GlucoseRecord> parseMultiData(List<int> f) {
    if (f.length < 4 || f[0] != respHead || f[2] != cmdReadMulti) {
      return const [];
    }
    if (isMultiDataEnd(f)) return const [];
    final bytes = Uint8List.fromList(f);
    if (!_verifyChecksum(bytes)) {
      throw BleFrameException('0xD3 Data frame verification failed', bytes);
    }
    int u16(int o) => (bytes[o] & 0xFF) | ((bytes[o + 1] & 0xFF) << 8);
    int i16(int o) {
      final v = u16(o);
      return v >= 0x8000 ? v - 0x10000 : v;
    }

    final n = (bytes.length - 4) ~/ 14;
    return List.generate(n, (i) {
      final o = 3 + i * 14;
      final ts =
          (bytes[o] & 0xFF) |
          ((bytes[o + 1] & 0xFF) << 8) |
          ((bytes[o + 2] & 0xFF) << 16) |
          ((bytes[o + 3] & 0xFF) << 24);
      return GlucoseRecord(
        timestampSec: ts,
        recordSeq: u16(o + 4),
        voltage: u16(o + 6) / 1000.0,
        temperature: i16(o + 8) / 10.0,
        rawCurrent: i16(o + 10) / 100.0,
        lactate: i16(o + 12) / 100.0,
      );
    });
  }

  /// Write measurement parameter request（0xC4）：`[Write0x57/read0x52] [freq] [t 0=average/1=all] [cycle Second] +5reserve`。
  /// cycle default 60 alignment protocol 6.1（one per minute），t=0 That is, the average data is reported per minute。
  static Uint8List buildMeasureParams({
    bool write = true,
    int freq = 3,
    int t = 0,
    int cycle = 60,
  }) => buildCommand(
    cmdMeasureParams,
    data: [write ? 0x57 : 0x52, freq, t, cycle, 0, 0, 0, 0, 0],
  );

  /// Hall control request（0xC0）：lock=true locking(0x00) / false Unlock(0x01)。
  static Uint8List buildHallControl(bool lock) => buildCommand(
    cmdHallControl,
    data: [lock ? 0x00 : 0x01, 0, 0, 0, 0, 0, 0, 0, 0],
  );

  /// Start measurement request（0xD1）：Data segment (little endian) year(2) Month Day Hour Minute Second Week SNcontrol。
  /// [keepSn] true=reserve SN continuation measurement(0x01)，false=Clear(0x00)，Clear for new activation。
  static Uint8List buildStartMeasure(
    DateTime at, {
    int? weekday,
    bool keepSn = false,
  }) {
    final year = at.year;
    final data = <int>[
      year & 0xFF,
      (year >> 8) & 0xFF,
      at.month,
      at.day,
      at.hour,
      at.minute,
      at.second,
      weekday ?? at.weekday,
      keepSn ? 0x01 : 0x00,
    ];
    return buildCommand(cmdStartMeasure, data: data);
  }

  /// Parse a frame response: check the frame header(0xAA)/length/Complement checksum, returns command number and data segment。
  /// data segment = before removing 3 Byte and end 1 Byte check; if illegal, throw [BleFrameException]。
  static CgmResponse parseResponse(Uint8List bytes) {
    if (bytes.length < BleFrameCodec.minFrameLength) {
      throw BleFrameException('Insufficient frame length', bytes);
    }
    if (bytes[0] != respHead) {
      throw BleFrameException(
        'Non-response frame header 0x${bytes[0].toRadixString(16)}',
        bytes,
      );
    }
    if (bytes[1] != bytes.length) {
      throw BleFrameException(
        'Length discrepancy: statement ${bytes[1]}，actual ${bytes.length}',
        bytes,
      );
    }
    if (!_verifyChecksum(bytes)) {
      throw BleFrameException('Two’s complement checksum failed', bytes);
    }
    return CgmResponse(
      commandId: bytes[2],
      payload: Uint8List.sublistView(bytes, 3, bytes.length - 1),
    );
  }

  /// parse 0xB0 Measurement data proactively reported (single, protocol 6.1），Real-time current source。
  /// Standard frame, 20 bytes, little-endian: AA 14 B0 timestamp (4 seconds), SN (2), voltage (2 mV), temperature (2, x10), WE1 current (2, x100 nA), reserved (4), CS.
  /// Also supports the simplified 16-byte simulator frame (no reserved section, 12-byte data segment). Output parameters are converted to V/C/nA, matching replay units.
  static GlucoseRecord parseMeasurement(Uint8List bytes) {
    if (bytes.length < 16) {
      throw BleFrameException('0xB0 Insufficient frame length', bytes);
    }
    if (bytes[0] != respHead || bytes[2] != cmdMeasureReport) {
      throw BleFrameException('No 0xB0 Measurement reporting frame', bytes);
    }
    if (bytes[1] != bytes.length) {
      throw BleFrameException('0xB0 Length does not match', bytes);
    }
    if (!_verifyChecksum(bytes)) {
      throw BleFrameException('0xB0 Verification failed', bytes);
    }
    int u16(int o) => (bytes[o] & 0xFF) | ((bytes[o + 1] & 0xFF) << 8);
    int i16(int o) {
      final v = u16(o);
      return v >= 0x8000 ? v - 0x10000 : v;
    }

    final ts =
        (bytes[3] & 0xFF) |
        ((bytes[4] & 0xFF) << 8) |
        ((bytes[5] & 0xFF) << 16) |
        ((bytes[6] & 0xFF) << 24);
    return GlucoseRecord(
      timestampSec: ts,
      recordSeq: u16(7),
      voltage: u16(9) / 1000.0,
      temperature: i16(11) / 10.0,
      rawCurrent: i16(13) / 100.0,
      lactate: 0.0,
    );
  }

  /// parse 0xE3 Response data segment: Measurement flag(byte0，0x01=Measuring) + Measured seconds(u32 little endian) +
  /// up to date SN(u16 little endian)。protocol 5.4。
  static ({bool measuring, int measuredSec, int latestSn}) parseLatestSn(
    Uint8List payload,
  ) {
    if (payload.length < 7) {
      throw BleFrameException(
        '0xE3 The response data segment is too short',
        payload,
      );
    }
    final measuredSec =
        (payload[1] & 0xFF) |
        ((payload[2] & 0xFF) << 8) |
        ((payload[3] & 0xFF) << 16) |
        ((payload[4] & 0xFF) << 24);
    return (
      measuring: (payload[0] & 0xFF) == 0x01,
      measuredSec: measuredSec,
      latestSn: (payload[5] & 0xFF) | ((payload[6] & 0xFF) << 8),
    );
  }

  /// parse 0xD4 The single frame response data segment is [GlucoseRecord]（The field layout is the same as 0xB0：
  /// Timestamp(4)/SN(2)/Voltage(2)/temperature(2)/WE1(2)…，little endian). protocol 4.3。
  static GlucoseRecord parseSingleData(Uint8List payload) {
    if (payload.length < 12) {
      throw BleFrameException(
        '0xD4 The response data segment is too short',
        payload,
      );
    }
    int u16(int o) => (payload[o] & 0xFF) | ((payload[o + 1] & 0xFF) << 8);
    int i16(int o) {
      final v = u16(o);
      return v >= 0x8000 ? v - 0x10000 : v;
    }

    final ts =
        (payload[0] & 0xFF) |
        ((payload[1] & 0xFF) << 8) |
        ((payload[2] & 0xFF) << 16) |
        ((payload[3] & 0xFF) << 24);
    return GlucoseRecord(
      timestampSec: ts,
      recordSeq: u16(4),
      voltage: u16(6) / 1000.0,
      temperature: i16(8) / 10.0,
      rawCurrent: i16(10) / 100.0,
      lactate: 0.0,
    );
  }

  /// Voltage(mV) = payload[0] + payload[1]<<8（0xE1 response, agreement 5.2）。
  static int voltageMvFrom(List<int> payload) =>
      (payload[0] & 0xFF) | ((payload[1] & 0xFF) << 8);

  /// Number of resets N = payload[0]（0xE5 response, agreement 5.6）。N>0 Indicates that the device has measured → in use。
  static int resetCountFrom(List<int> payload) => payload[0] & 0xFF;

  /// reset message（0xE5 response, agreement 5.6）：Number of resets(byte0) + reset flag(byte1~2,little endian)。
  /// resetCount≠1 = The device has been reset abnormally and needs to be written back with the same value.（[buildResetResetInfo]）confirm。
  static ({int resetCount, int resetFlag}) resetInfoFrom(List<int> payload) {
    if (payload.length < 3) {
      throw BleFrameException(
        '0xE5 The response data segment is too short',
        Uint8List.fromList(payload),
      );
    }
    return (
      resetCount: payload[0] & 0xFF,
      resetFlag: (payload[1] & 0xFF) | ((payload[2] & 0xFF) << 8),
    );
  }

  static bool _verifyChecksum(Uint8List bytes) {
    final last = bytes.length - 1;
    var sum = 0;
    for (var i = 0; i < last; i++) {
      sum += bytes[i];
    }
    return bytes[last] == ((~sum + 1) & 0xFF);
  }
}

/// Command response: command number + Data segment (header removed)/length/Order/check）。
class CgmResponse {
  final int commandId;
  final Uint8List payload;

  const CgmResponse({required this.commandId, required this.payload});
}
