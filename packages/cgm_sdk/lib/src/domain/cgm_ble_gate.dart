import 'dart:async';

import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';

/// CGM equipment BLE Interactive seams. Real machine uses Bluetooth protocol V3.0，desktop/test injection [MockCgmBleGate]。
abstract class CgmBleGate {
  /// Connect the device (Bluetooth address) and return whether it is successful。
  Future<bool> connect(String bluetoothAddr);

  /// Read battery voltage（mV）。BLE 0xE1。
  Future<int> readBatteryMv();

  /// read"Is it in use"。BLE 0xE5 Reset detection bit (the device has measured → in use）。
  Future<bool> readInUse();

  /// Activation: Go through the complete boot sequence（0xE5 reset writeback → 0xE1 Power → 0xC4 Write measurement parameters → 0xC0 Hall lock
  /// → 0xD1 Start measurement, clear SN）。Only send 0xD1 If no period is set, the device will not output frames.。
  Future<void> activate(DateTime at);

  /// Unable to receive messages for a long time after reconnecting 0xB0 The bottom line when it comes to time: just make up for it 0xC4 Write measurement parameters。
  /// No need to adjust for normal reconnection, protocol 6.1 Will automatically report periodically。
  Future<void> startReporting(DateTime at);

  /// school hours：0xD1 + keepSn=true reset time base。
  ///
  /// Currently disabled, no caller. The firmware does not accept keepSn=1，receive 0xD1 Always SN cleared while the device FLASH
  /// History button SN Addressing, after clearing 0xD3/0xD4 Can’t pull the disconnected data. Time base drift can be corrected in the presentation layer，
  /// History is lost irreversibly. It will not be cleared until the firmware is provided. SN The time adjustment method is then restored and called。
  Future<void> syncClock(DateTime at);

  /// Live measurement stream: device pushes one frame of raw bytes every minute（0xB0），use [CgmCommand.parseMeasurement] parse。
  Stream<List<int>> measurements();

  /// equipment FLASH Full (agreement 6.3 of 0xF1 Take the initiative to report）。
  ///
  /// After receiving the device has stopped measuring and there is no more 0xB0，Reconnecting is useless, it must be visible to users。
  /// FLASH Stop when full, not circular overwriting, previous history is still available 0xD3 pull back。
  Stream<void> get flashOverflow;

  /// Read device measurement status + up to date SN（0xE3）。
  Future<({bool measuring, int measuredSec, int latestSn})> readMeasureState();

  /// Read firmware version（0xE7）。The protocol does not specify the response format: printable ASCII Return as is, otherwise press `major.minor` /
  /// Hexadecimal has the bottom line. False implementation returns null。
  Future<String?> readFirmwareVersion() async => null;

  /// according to SN Read one frame of measurement data（0xD4），Used for complementing numbers after disconnection; if not obtained, return null。
  Future<GlucoseRecord?> readSingle(int sn);

  /// from [fromSn] Read the latest in batches SN（0xD3 Streaming multiple frames, per frame≤16bar), large gap covering ratio 0xD4 Express one by one。
  /// complete=false Indicates flow interruption/Contains bad frames, missing ones SN Want to retreat 0xD4 Confirm item by item; throw exception if sending fails。
  Future<({List<GlucoseRecord> records, bool complete})> readMulti(
    int fromSn, {
    void Function(int received)? onProgress,
  });

  /// Complete start of measurement sequence：`0xC4 Write measurement parameters(Assume upload cycle) → 0xC0 Hall lock → 0xD1 Start measuring`。
  /// Only send 0xD1 There is no cycle, although the equipment"Measuring"but no frame(SN No increase)。
  Future<void> startMeasureSequence(DateTime at);

  /// Cut high-throughput links during the recovery period (Android reduces the connection interval to 11.25-15ms），Completion and return lowPower
  /// （100-125ms + latency 2）；Downshifting is only done when entering steady state. During the connection period, commands must be fast links.。iOS Not adjustable, empty implementation。
  Future<void> setFastLink(bool on) async {}

  Future<void> disconnect();

  /// After disconnection, hang up a ”Watch Reconnect”: do not actively scan, wait for the device to come back on its own。
  ///
  /// iOS The only recovery path available in the background: Backend Dart Timer Full stop and background scanning are required service UUID，
  /// and CoreBluetooth of pending connect There is no timeout, the device automatically connects and wakes up when it returns within range. App。
  /// Join the posterior meridian [connectionChanges] push true。Default empty implementation，Android There is a foreground service and scheduled retries。
  Future<void> watchReconnect() async {}

  /// link state flow：false=disconnect，true=Connected; the collection side stops output accordingly. initiative [disconnect] No incident。
  Stream<bool> get connectionChanges => const Stream<bool>.empty();
}

/// test / The desktop is implemented with fake: a healthy unused device by default, which can be overridden item by item to simulate each rejection state.。
class MockCgmBleGate implements CgmBleGate {
  MockCgmBleGate({
    this.connectOk = true,
    this.batteryMv = 3000,
    this.inUse = false,
  });

  bool connectOk;
  int batteryMv;
  bool inUse;

  /// Whether activation has been issued for test assertion。
  bool activated = false;
  DateTime? activatedAt;

  /// Number of connections / Whether it has been disconnected for testing the assertion timing。
  int connectCalls = 0;
  bool disconnectCalled = false;

  /// push here 0xB0 Raw frame simulation device reporting。
  final measurementController = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> measurements() => measurementController.stream;

  /// push here false Analog device disconnection。
  final connectionController = StreamController<bool>.broadcast();

  @override
  Stream<bool> get connectionChanges => connectionController.stream;

  /// Push the simulated device here once FLASH Full（0xF1）。
  final flashOverflowController = StreamController<void>.broadcast();

  @override
  Stream<void> get flashOverflow => flashOverflowController.stream;

  @override
  Future<bool> connect(String bluetoothAddr) async {
    connectCalls++;
    return connectOk;
  }

  /// The number of watch reconnections is used for test assertions (if false connection is achieved, it depends on [connectionController] push true）。
  int watchReconnectCalls = 0;

  @override
  Future<void> watchReconnect() async => watchReconnectCalls++;

  @override
  Future<int> readBatteryMv() async => batteryMv;

  @override
  Future<bool> readInUse() async => inUse;

  @override
  Future<void> activate(DateTime at) async {
    activated = true;
    activatedAt = at;
    // Real machine activation follows a complete startup sequence, and the device generates frames periodically accordingly.
    reportingStarted = true;
  }

  /// Whether a continuation report has been issued for testing assertions。
  bool reportingStarted = false;

  @override
  Future<void> startReporting(DateTime at) async {
    reportingStarted = true;
  }

  /// School time issuance time for test assertion。
  DateTime? clockSyncedAt;

  @override
  Future<void> syncClock(DateTime at) async => clockSyncedAt = at;

  /// Overridable device status, not measured by default、SN=0。
  ({bool measuring, int measuredSec, int latestSn}) measureState = (
    measuring: false,
    measuredSec: 0,
    latestSn: 0,
  );

  @override
  Future<({bool measuring, int measuredSec, int latestSn})>
  readMeasureState() async => measureState;

  /// Overridable firmware version, default null。
  String? firmwareVersion;

  @override
  Future<String?> readFirmwareVersion() async => firmwareVersion;

  /// 0xD4 Pile: press SN Return a simulation history record。
  GlucoseRecord? Function(int sn)? onReadSingle;

  @override
  Future<GlucoseRecord?> readSingle(int sn) async => onReadSingle?.call(sn);

  /// 0xD3 The piles read in batches will be thrown away if not injected. [UnsupportedError]。
  ({List<GlucoseRecord> records, bool complete}) Function(int fromSn)?
  onReadMulti;

  @override
  Future<({List<GlucoseRecord> records, bool complete})> readMulti(
    int fromSn, {
    void Function(int received)? onProgress,
  }) async {
    final f = onReadMulti;
    if (f == null) throw UnsupportedError('mock Not injected onReadMulti');
    final r = f(fromSn);
    onProgress?.call(r.records.length);
    return r;
  }

  /// 「”Start Measurement Sequence” was called several times for testing assertions. last step 0xD1(keepSn=false) Will clear the device SN，
  /// Only allowed in binding activation paths。
  int startMeasureSequenceCalls = 0;

  @override
  Future<void> startMeasureSequence(DateTime at) async {
    startMeasureSequenceCalls++;
    reportingStarted = true;
  }

  /// setFastLink Calling sequence for testing assertions。
  final fastLinkCalls = <bool>[];

  @override
  Future<void> setFastLink(bool on) async => fastLinkCalls.add(on);

  @override
  Future<void> disconnect() async => disconnectCalled = true;
}
