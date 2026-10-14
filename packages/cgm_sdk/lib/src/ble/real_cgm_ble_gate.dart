import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:cgm_sdk/src/constants/app_constants.dart';
import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/domain/cgm_ble_gate.dart';
import 'package:cgm_sdk/src/domain/device_scan_result.dart';
import 'package:cgm_sdk/src/ble/ble_link_tuning.dart';
import 'package:cgm_sdk/src/collection/device_clock_skew.dart';
import 'package:cgm_sdk/src/ble/ble_frame_codec.dart';
import 'package:cgm_sdk/src/ble/cgm_command.dart';

/// CGM equipment BLE Real machine realization（flutter_blue_plus）。
///
/// by broadcast name `CGM-{MACNo colon}` scan match（iOS Can’t get it MAC），Subscribe after connecting 0xFFF1，
/// After writing the command, it will respond with the same command number. Binding activation is a single packet of short frames, and the history of multiple frames is 0xFFF2。
class RealCgmBleGate implements CgmBleGate {
  RealCgmBleGate({
    this.scanTimeout = const Duration(seconds: 10),
    this.connectTimeout = const Duration(seconds: 15),
    this.handleConnectTimeout = const Duration(seconds: 8),
    this.commandTimeout = const Duration(seconds: 8),
    this.savePeripheralId,
    this.readPeripheralId,
  });

  final Duration scanTimeout;
  final Duration connectTimeout;

  /// The upper limit when taking the saved handle for ”blind connection” is higher than [connectTimeout] short。
  ///
  /// The direct connection of the handle is waiting for the next broadcast window of the device. When it is full, it will be pure white; the fallback scan will only connect when it sees the broadcast, but it will be stable.。
  /// 8 Seconds is a round-off value. Adjusting it to a lower value will cut off some of the connections that could have been successful, while scanning is waiting for the same broadcast window.，
  /// Scanning fails when the device is silent。
  final Duration handleConnectTimeout;

  /// The upper limit of a single command and other responses。
  ///
  /// must ≥ 8 Seconds: The firmware read command itself has a second-level response delay.（1.0 ~ 2.6 More than seconds, regardless of the connection interval），
  /// 3 The command will time out in seconds and then try again.；1000 ms In the steady state of the connection interval, there will be another round trip of the connection event.。
  final Duration commandTimeout;

  /// Save this device after connecting peripheral handle（`remoteId`），Even read it back before。
  ///
  /// iOS Backend reconnection relies entirely on it：iOS Can’t get it MAC，`remoteId` yes CoreBluetooth of peripheral UUID；
  /// iOS Background scanning is required service UUID However, our broadcast package does not include it, so we can only use the handle to connect directly.。
  /// Android superior `remoteId` that is MAC，By the way, save every time 10 Scan in seconds。
  final Future<void> Function(String remoteId)? savePeripheralId;
  final Future<String?> Function()? readPeripheralId;

  BluetoothDevice? _device;

  /// Connection in progress (solo guard): concurrent dual connection with the same device will open two GATT / two ways notify，
  /// trigger native Crash and collect twice per frame。
  Future<bool>? _connectInFlight;

  /// Write command characteristics (priority 0xFFF1）and notification response features; the serial port module often writes/The notification is split into two features。
  BluetoothCharacteristic? _writeChar;

  /// Read-only feature, used by link delay probes (see [measureLinkLatency]）。Choose standards GATT feature：
  /// The protocol stack responds directly, and the round-trip time only reflects the air interface and does not include firmware processing delays.。
  BluetoothCharacteristic? _probeChar;
  BluetoothCharacteristic? _notifyChar;

  /// Real-time measurement reporting bypass: command response and device active reporting share the same notification feature, and are divided according to the command number.。
  final _measureController = StreamController<List<int>>.broadcast();
  final List<StreamSubscription<List<int>>> _measureSubs = [];

  /// GATT Link status bypass: non-active disconnect push false，The collection side immediately stops production.。
  final _connectionController = StreamController<bool>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connStateSub;

  @override
  Stream<bool> get connectionChanges => _connectionController.stream;

  /// FLASH Full Bypass (Protocol 6.3 of 0xF1）：The device stops measuring at this point, and the collection side should be visible to the user.。
  final _flashOverflowController = StreamController<void>.broadcast();

  @override
  Stream<void> get flashOverflow => _flashOverflowController.stream;

  /// All notification features。0xD3 Data frame walks FFF2、Answer and go FFF1（protocol 4.2），Collecting traffic requires crossing features。
  final List<BluetoothCharacteristic> _notifyCharsAll = [];

  static final Guid _fff1Uuid = Guid(AppConstants.bleCharFff1);

  /// Check the system for connected devices service filter, see [_scanForDevice] Description in。
  static final List<Guid> _systemDeviceServices = [
    Guid(AppConstants.bleServiceUuid),
    Guid('1800'),
  ];

  @override
  Future<bool> connect(String bluetoothAddr) {
    final inflight = _connectInFlight;
    if (inflight != null) {
      _log(
        'The connection is already in progress. Reuse this connection (to avoid concurrent dual connections to the same device). native collapse）',
      );
      return inflight;
    }
    final f = _connectImpl(bluetoothAddr);
    _connectInFlight = f;
    f.whenComplete(() {
      if (identical(_connectInFlight, f)) _connectInFlight = null;
    });
    return f;
  }

  Future<bool> _connectImpl(String bluetoothAddr) async {
    _log('connect start: addr=$bluetoothAddr');
    // Take what you saved first peripheral Handle direct connection (see [readPeripheralId]），If the connection fails, go back to scanning.。
    final saved = await _savedPeripheralId();
    if (saved != null) {
      if (await _attach(
        BluetoothDevice.fromId(saved),
        from: 'Saved handle',
        timeout: handleConnectTimeout,
      )) {
        return true;
      }
      _log('Saved handle $saved Can’t connect → rollback scan');
    }
    final device = await _scanForDevice(bluetoothAddr);
    if (device == null) return false;
    return _attach(device, from: 'scanning');
  }

  Future<String?> _savedPeripheralId() async {
    try {
      final v = await readPeripheralId?.call();
      return (v == null || v.isEmpty) ? null : v;
    } catch (e) {
      _log('read peripheral Handle failed(neglect,Scan): $e');
      return null;
    }
  }

  /// Connect to this device and establish the link（MTU→service discovery→Full features notify）。Success means remembering the handle。
  Future<bool> _attach(
    BluetoothDevice? device, {
    required String from,
    Duration? timeout,
  }) async {
    try {
      if (device == null) return false;
      _log('Matched ${device.remoteId.str}（source=$from），connect…');
      await _connectWithRetry(device, timeout: timeout);
      _device = device;
      _log('GATT Connected');
      try {
        await savePeripheralId?.call(device.remoteId.str);
      } catch (e) {
        _log(
          'live peripheral Handle failed(Does not affect this connection): $e',
        );
      }
      await _watchConnectionState(device);

      // Negotiate MTU 512：Some firmware does not negotiate MTU will be abnormal. Ignore on failure，iOS auto-negotiation。
      try {
        final mtu = await device.requestMtu(512);
        _log('MTU=$mtu');
      } catch (e) {
        _log('requestMtu fail(neglect): $e');
      }

      // Once connected, it will be considered successful and the service will not be stuck. UUID（Firmware varies from company to company); if a failure is found, the connection will not be judged as failed.。
      try {
        final services = await device.discoverServices();
        for (final svc in services) {
          for (final c in svc.characteristics) {
            final p = c.properties;
            _log(
              'Serve ${svc.uuid.str} feature ${c.uuid.str} '
              '[w=${p.write} wnr=${p.writeWithoutResponse} '
              'n=${p.notify} i=${p.indicate}]',
            );
          }
        }
        _probeChar = _pickProbeChar(services);
        final picked = _pickChars(services);
        _writeChar = picked.write;
        _notifyChar = picked.notify;
        _log(
          'write features=${_writeChar?.uuid.str} Notification features=${_notifyChar?.uuid.str}',
        );
        // respond with 0xB0 Reports may fall into different notification characteristics. Turn on notifications for all and monitor each one.
        final notifyChars = <BluetoothCharacteristic>[];
        for (final svc in services) {
          for (final c in svc.characteristics) {
            if (c.properties.notify || c.properties.indicate) {
              notifyChars.add(c);
            }
          }
        }
        await _cancelMeasureSubs();
        _notifyCharsAll.clear();
        for (final c in notifyChars) {
          try {
            await c.setNotifyValue(true);
            _log('Notifications turned on ${c.uuid.str}');
          } catch (e) {
            _log('Failed to enable notifications ${c.uuid.str}(neglect): $e');
            continue;
          }
          _notifyCharsAll.add(c);
          _measureSubs.add(
            c.onValueReceived.listen((v) {
              final isMeasure =
                  v.length >= 3 &&
                  v[0] == CgmCommand.respHead &&
                  v[2] == CgmCommand.cmdMeasureReport;
              // protocol 6.3：FLASH After the storage is full, the device stops measuring and pushes this item, and then there is no more 0xB0，
              // The performance is the same as disconnection but reconnection is useless. Let the upper level see it.。
              final isFlashFull = CgmCommand.isFlashOverflowFrame(v);
              _log(
                'Report frame ${c.uuid.str} len=${v.length} '
                '${isMeasure
                    ? "→0xB0Measurement·Advanced Algorithm"
                    : isFlashFull
                    ? "→0xF1 FLASHThe bank is full and the device has been stopped for testing."
                    : "Non-measurement and non-advanced algorithm"}'
                ': ${_hex(v)}',
              );
              _printRx(c.uuid.str, v, isMeasure);
              if (isMeasure) _measureController.add(v);
              if (isFlashFull) _flashOverflowController.add(null);
            }),
          );
        }
        if (notifyChars.isEmpty) {
          _log(
            'Without any notifiable characteristics, the command response is the same as 0xB0 I can’t even receive the measurement report.',
          );
        }
        // wait CCCD Send the command after it takes effect: Send the command immediately after subscribing on Android race Drop the first reply。
        await Future.delayed(const Duration(milliseconds: 300));
        if (_writeChar == null) {
          _log(
            'Writable characteristics not found (connection still successful, command interaction may not be available）',
          );
        }
      } catch (e) {
        _log(
          'Serve/Abnormal feature discovery (does not affect connection determination）: $e',
        );
      }
      return true;
    } catch (e) {
      _log('Connection failed: $e');
      // must be disconnected device，otherwise GATT Leakage, equipment is occupied and no longer broadcast。
      await _cancelMeasureSubs();
      await _connStateSub?.cancel();
      _connStateSub = null;
      _device = null;
      _writeChar = null;
      _probeChar = null;
      _notifyChar = null;
      _notifyCharsAll.clear();
      try {
        await device?.disconnect();
      } catch (_) {}
      return false;
    }
  }

  /// Connection retry: Android first time connect regular newspaper 133/62，Trying again immediately will most likely succeed; other errors will be thrown directly.。
  Future<void> _connectWithRetry(
    BluetoothDevice device, {
    int maxAttempts = 3,
    Duration? timeout,
  }) async {
    for (var i = 1; ; i++) {
      try {
        await device.connect(timeout: timeout ?? connectTimeout);
        return;
      } catch (e) {
        final s = e.toString();
        final transient =
            s.contains('CONNECTION_FAILED_ESTABLISHMENT') ||
            s.contains('android-code: 133') ||
            s.contains('android-code: 62');
        _log('connect No. $i failed: $e');
        if (i >= maxAttempts || !transient) rethrow;
        try {
          await device.disconnect();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  /// Pick a read-only feature that measures link round-trips。
  ///
  /// priority criteria GATT（0x2A00 Device name / 0x2A24-2A28 Device information): Directly answered by the protocol stack，
  /// One round trip to read≈Two connection events can infer the connection interval; manufacturer-defined features are mostly passed through the firmware application layer，
  /// What is measured is the firmware response delay。
  BluetoothCharacteristic? _pickProbeChar(List<BluetoothService> services) {
    BluetoothCharacteristic? fallback;
    for (final svc in services) {
      for (final c in svc.characteristics) {
        if (!c.properties.read) continue;
        final u = c.uuid.str.toLowerCase();
        // 16 bit standard UUID will be flutter_blue_plus abbreviated to 4 Bit
        final short = u.length == 4
            ? u
            : (u.length >= 8 ? u.substring(4, 8) : u);
        if (short == '2a00' ||
            (short.startsWith('2a2') && short.compareTo('2a24') >= 0)) {
          return c;
        }
        fallback ??= c;
      }
    }
    return fallback;
  }

  /// Measure a link round trip: continuous reading [rounds] Read-only feature, returns the time taken for each time (milliseconds)）。
  ///
  /// Used to view the current connection interval，iOS There is no other way to see this number. once ATT Reading requires two connection events，
  /// So the connection interval ≈ Median round trip ÷ 2（Reading standards GATT It is established only when the characteristics）。
  Future<List<int>> measureLinkLatency({int rounds = 10}) async {
    final c = _probeChar;
    if (c == null) {
      throw StateError(
        'Device is not connected or has no readable characteristics',
      );
    }
    final out = <int>[];
    for (var i = 0; i < rounds; i++) {
      final sw = Stopwatch()..start();
      try {
        await c.read();
      } catch (e) {
        _log('Link Probe Section ${i + 1} Read failed: $e');
        continue;
      }
      out.add(sw.elapsedMilliseconds);
    }
    if (out.isNotEmpty) {
      final sorted = [...out]..sort();
      final mid = sorted[sorted.length ~/ 2];
      _log(
        'link probe ${c.uuid.str}: ${out.join("/")} ms，'
        'median $mid ms → The connection interval is approx. ${(mid / 2).round()} ms',
      );
    }
    return out;
  }

  ({BluetoothCharacteristic? write, BluetoothCharacteristic? notify})
  _pickChars(List<BluetoothService> services) {
    BluetoothCharacteristic? write;
    BluetoothService? writeSvc;
    for (final s in services) {
      for (final c in s.characteristics) {
        if (!(c.properties.write || c.properties.writeWithoutResponse)) {
          continue;
        }
        if (write == null) {
          write = c;
          writeSvc = s;
        }
        if (c.uuid == _fff1Uuid) {
          write = c;
          writeSvc = s;
        }
      }
    }

    BluetoothCharacteristic? notify;
    for (final c
        in writeSvc?.characteristics ?? const <BluetoothCharacteristic>[]) {
      if (c.properties.notify || c.properties.indicate) {
        notify = c;
        break;
      }
    }
    if (notify == null) {
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            notify = c;
            break;
          }
        }
        if (notify != null) break;
      }
    }
    return (write: write, notify: notify);
  }

  void _log(String msg) => DevLog.instance.add('ble', msg);

  /// Scan for matching target device: broadcast name `CGM-{Device number}`，Used when the name is missing occasionally MAC reveal all the details。
  Future<BluetoothDevice?> _scanForDevice(String bluetoothAddr) async {
    final deviceId = bluetoothAddr.replaceAll(':', '').toUpperCase();
    final wantName = bleNameFromDeviceId(deviceId);
    final wantMac = macFromDeviceId(deviceId);
    _log('Scan target: name=$wantName mac=$wantMac');

    // The last connection was not released（app Caused by crash GATT leakage), the device cannot be scanned if it is occupied and broadcasting is stopped.，
    // First check if the system is connected/Connect the paired device directly
    try {
      // Can’t pass `const []`：iOS of retrieveConnectedPeripherals(withServices:) Pass empty array
      // Always returns empty, the bottom of this pocket is iPhone It will be invalid if it is on Android side. getConnectedDevices(GATT) Do not look at this parameter。
      // FFF0=Equipment own service，1800=Generic Access reveal all the details。
      final sys = await FlutterBluePlus.systemDevices(_systemDeviceServices);
      for (final d in sys) {
        final mac = d.remoteId.str.toUpperCase();
        final hit =
            (wantMac != null && mac == wantMac) ||
            (wantName.isNotEmpty && d.platformName == wantName);
        if (hit) {
          _log(
            'Hit system is connected/Paired device ${d.remoteId.str}，Skip scanning and connect directly (bypassing and not broadcasting）',
          );
          return d;
        }
      }
    } catch (e) {
      _log('Failed to check system equipment(Ignore, scan instead): $e');
    }

    // Summary of scanned devices（remoteId Remove duplicates), if no match is found, enter the entire list
    final seen = <String, String>{};
    final completer = Completer<BluetoothDevice?>();
    late final StreamSubscription<List<ScanResult>> sub;
    sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final ad = r.advertisementData;
        final mac = r.device.remoteId.str;
        // iOS superior advName and platformName Same source (both from broadcast Local Name），may be empty together；
        // Android platformName It can also be added from the system cache. Whichever one you get counts.。
        final advName = ad.advName;
        final platName = r.device.platformName;
        seen[mac] =
            '${advName.isEmpty ? (platName.isEmpty ? "(nameless)" : platName) : advName}'
            '|$mac|${r.rssi}dBm'
            '|adv="$advName" plat="$platName"'
            '|svc=[${ad.serviceUuids.map((u) => u.str).join(",")}]'
            '|msd={${ad.manufacturerData.entries.map((e) => "0x${e.key.toRadixString(16)}=${_hex(e.value)}").join("; ")}}';
        final matchName =
            _sameBleName(advName, wantName) || _sameBleName(platName, wantName);
        // iOS Shangheng is not established：CoreBluetooth of remoteId is assigned by it UUID，no MAC；Only Android works。
        final matchMac = wantMac != null && mac.toUpperCase() == wantMac;
        final hasFff0 = ad.serviceUuids.any(
          (u) => u.str.toLowerCase().contains('fff0'),
        );
        final isCgmFuzzy =
            advName.toUpperCase().contains('CGM') ||
            platName.toUpperCase().contains('CGM') ||
            advName.toUpperCase().contains('SIMULATOR') ||
            platName.toUpperCase().contains('SIMULATOR');
        if (matchName || matchMac || hasFff0 || isCgmFuzzy) {
          if (!completer.isCompleted) completer.complete(r.device);
          break;
        }
      }
    });

    // Don’t press service UUID Filtering: Some firmware broadcast main packages do not include 0xFFF0，will be filtered out by the system layer。
    //
    // continuousUpdates=true exist iOS Must be on: default false When the plug-in is not set
    // `CBCentralManagerScanOptionAllowDuplicatesKey`，iOS Callback only once per device，
    // The first frame is not included Local Name（name in SCAN_RSP ) will never be made up, and there is no MAC It can cover the entire equipment and cannot be scanned。
    // Android calls back every frame and remoteId that is MAC，not affected。
    await FlutterBluePlus.startScan(
      timeout: scanTimeout,
      continuousUpdates: true,
    );
    final device = await completer.future.timeout(
      scanTimeout,
      onTimeout: () => null,
    );
    await sub.cancel();
    await FlutterBluePlus.stopScan();
    if (device == null) {
      _log(
        'Scan ends: Scanned in total ${seen.length} devices, none matched the target。'
        'list=${seen.values.toList()}',
      );
    }
    return device;
  }

  @override
  Future<int> readBatteryMv() async {
    final resp = await _invoke(
      CgmCommand.buildReadVoltage(),
      CgmCommand.cmdReadVoltage,
    );
    return CgmCommand.voltageMvFrom(resp.payload);
  }

  @override
  Future<bool> readInUse() async {
    final resp = await _invoke(
      CgmCommand.buildReadReset(),
      CgmCommand.cmdReadReset,
    );
    // Number of resets > 0 Indicates that the device has been measured and is in use (protocol 5.6）。
    return CgmCommand.resetCountFrom(resp.payload) > 0;
  }

  @override
  Future<void> activate(DateTime at) async {
    // Activation must go through the complete startup sequence: only send one 0xD1 The device is in ”Measurement”, but the upload period is not set.
    // Didn’t do it either 0xE5 Write back confirmation，SN No increase, no push 0xB0。
    await startMeasureSequence(at);
  }

  @override
  Future<void> startReporting(DateTime at) async {
    // protocol 6.1 It should be automatically reported periodically next time 0xB0，This is just a summary of recovery after a long period of silence.：
    // Silence is probably due to the upload cycle not being set, so add it once. 0xC4。
    // Can’t post here 0xD1(keepSn=true)：The firmware does not accept keepSn=1，Still SN cleared, and FLASH history
    // according to SN Addressing, after clearing 0xD3/0xD4 I can no longer read that history。0xD1 Only active/When replacing the sensor。
    _log(
      'Restoring the reporting process: Write measurement parameters(0xC4 cycle=60)；Not sent 0xD1(Will be cleared SN、Abolish FLASH history)',
    );
    await _invoke(CgmCommand.buildMeasureParams(), CgmCommand.cmdMeasureParams);
    _log(
      'The measurement parameters have been acknowledged and the device should start pushing 0xB0（Wait for the frame to be reported in the next minute）',
    );
  }

  @override
  Future<void> syncClock(DateTime at) async {
    // There is currently no caller: the firmware does not recognize it. keepSn=1， SN。The interface is retained and can be enabled directly after the firmware is modified.。
    _log(
      'Equipment time calibration: Issue 0xD1(keepSn=1) time base=${_hhmmss(at)}',
    );
    await _invoke(
      CgmCommand.buildStartMeasure(at, keepSn: true),
      CgmCommand.cmdStartMeasure,
    );
    _log('Equipment time calibration: Answered');
  }

  static String _hhmmss(DateTime t) =>
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  @override
  Future<({bool measuring, int measuredSec, int latestSn})>
  readMeasureState() async {
    final resp = await _invoke(
      CgmCommand.buildReadLatestSn(),
      CgmCommand.cmdReadLatestSn,
    );
    final s = CgmCommand.parseLatestSn(resp.payload);
    _log(
      'Read device status(0xE3): ${s.measuring ? "Measuring" : "Not measured"} '
      'up to dateSN=${s.latestSn} Tested${s.measuredSec}s',
    );
    debugPrint(
      'CGM_RX Device measurement status(0xE3): ${s.measuring ? "Measuring" : "Not measured"} '
      '| up to dateSN=${s.latestSn} | Tested=${s.measuredSec}s',
    );
    return s;
  }

  @override
  Future<String?> readFirmwareVersion() async {
    final resp = await _invoke(
      CgmCommand.buildReadVersion(),
      CgmCommand.cmdReadVersion,
    );
    final p = resp.payload;
    if (p.isEmpty) return null;
    // Real machine actual test response `00 c0 41 32 30 35`：The first two bytes are non-printable, followed by ASCII "A205"。
    // Take the longest printable ASCII The section is used as the version number; there is no return even after a section. 2 byte major.minor / hexadecimal。
    var best = '';
    var cur = '';
    for (final b in [...p, 0]) {
      if (b >= 0x20 && b < 0x7f) {
        cur += String.fromCharCode(b);
      } else {
        if (cur.length > best.length) best = cur;
        cur = '';
      }
    }
    if (best.trim().length >= 2) return best.trim();
    if (p.length == 2) return '${p[0]}.${p[1]}';
    return _hex(p).replaceAll(' ', '');
  }

  @override
  Future<GlucoseRecord?> readSingle(int sn) async {
    try {
      final resp = await _invoke(
        CgmCommand.buildReadSingle(sn),
        CgmCommand.cmdReadSingle,
      );
      final r = _shift(CgmCommand.parseSingleData(resp.payload));
      final t = DateTime.fromMillisecondsSinceEpoch(
        r.timestampSec * 1000,
        isUtc: true,
      );
      final ts =
          '${t.year}-${_two(t.month)}-${_two(t.day)} '
          '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
      debugPrint(
        'CGM_RX Actively read single frame(0xD4) seq=${r.recordSeq} time=$ts '
        'Voltage=${r.voltage.toStringAsFixed(3)}V temperature=${r.temperature.toStringAsFixed(1)}℃ '
        'WE1current=${r.rawCurrent.toStringAsFixed(2)}nA',
      );
      return r;
    } catch (e) {
      _log('Actively read single frame(0xD4) seq=$sn fail: $e');
      return null;
    }
  }

  /// Translate the timestamp of a record from the device axis to the real axis, see [DeviceClockSkew]；If the deviation is not measured, it will be returned as it is.。
  static GlucoseRecord _shift(GlucoseRecord r) => DeviceClockSkew.isKnown
      ? GlucoseRecord(
          timestampSec: DeviceClockSkew.toRealSec(r.timestampSec),
          recordSeq: r.recordSeq,
          voltage: r.voltage,
          temperature: r.temperature,
          rawCurrent: r.rawCurrent,
          lactate: r.lactate,
        )
      : r;

  /// Use in batch package SN The biggest one（＝(just measured by the equipment) determine the deviation, and then translate the entire batch to the true axis。
  static void _observeAndShift(List<GlucoseRecord> records) {
    if (records.isEmpty) return;
    var newest = records.first;
    for (final r in records) {
      if (r.recordSeq > newest.recordSeq) newest = r;
    }
    DeviceClockSkew.observe(newest.timestampSec, DateTime.now(), live: false);
    if (!DeviceClockSkew.isKnown) return;
    for (var i = 0; i < records.length; i++) {
      records[i] = _shift(records[i]);
    }
  }

  /// 0xD3 Streaming idle timeout: The interval between data frames is much less than this value. When the timeout expires, the stream is deemed to have ended./interrupt。
  static const Duration _multiReadIdleTimeout = Duration(seconds: 5);

  @override
  Future<({List<GlucoseRecord> records, bool complete})> readMulti(
    int fromSn, {
    void Function(int received)? onProgress,
  }) async {
    if (_writeChar == null) {
      throw StateError('Device not connected(no write feature)');
    }
    final records = <GlucoseRecord>[];
    var sawEnd = false;
    var sawCorrupt = false;
    final done = Completer<void>();
    Timer? idle;
    void bump() {
      idle?.cancel();
      idle = Timer(_multiReadIdleTimeout, () {
        if (!done.isCompleted) done.complete();
      });
    }

    void handleFrame(List<int> f) {
      if (CgmCommand.isMultiDataEnd(f)) {
        sawEnd = true;
        if (!done.isCompleted) done.complete();
        return;
      }
      try {
        final rs = CgmCommand.parseMultiData(f);
        if (rs.isEmpty) return;
        records.addAll(rs);
        onProgress?.call(records.length);
      } on BleFrameException catch (e) {
        // The record in the bad frame has been lost, and the rectification is downgraded to incomplete to let the gap go. 0xD4 confirm，
        // Otherwise, it will be regarded as ”the device does not have this data” and the space will be interpolated.。
        sawCorrupt = true;
        _log(
          '0xD3 Data frame corruption(Rectification is treated as incomplete): $e',
        );
      }
      bump();
    }

    // The data frame is in FFF2、confirmed in FFF1(protocol 4.2)，Receive traffic across all notification features；
    // Single feature independent reassembly buffer: frames may be fragmented across notifications(Maximum frame length 227 > Some models MTU)。
    final subs = <StreamSubscription<List<int>>>[];
    for (final c in _notifyCharsAll) {
      final buf = <int>[];
      subs.add(
        c.onValueReceived.listen((v) {
          buf.addAll(v);
          while (true) {
            while (buf.isNotEmpty && buf[0] != CgmCommand.respHead) {
              buf.removeAt(0);
            }
            if (buf.length < 4) break;
            // end frame LEN May differ from actual byte count(Agreement caliber3/Real machine5)，Special judgment to remove the entire frame。
            if (CgmCommand.isMultiDataEnd(buf)) {
              handleFrame(buf.sublist(0, 5 <= buf.length ? 5 : 4));
              buf.clear();
              continue;
            }
            final len = buf[1];
            if (len < 4) {
              buf.removeAt(0);
              continue;
            }
            if (buf.length < len) break;
            final frame = buf.sublist(0, len);
            buf.removeRange(0, len);
            handleFrame(frame);
          }
        }),
      );
    }

    try {
      bump();
      await _invoke(CgmCommand.buildReadMulti(fromSn), CgmCommand.cmdReadMulti);
      await done.future;
    } finally {
      idle?.cancel();
      for (final s in subs) {
        await s.cancel();
      }
    }
    // Use in batch package SN The largest one corresponds to the device clock deviation, and then the entire batch is translated to the true axis，
    // Downstream (removal of duplication/anchor point/Dropped into the library/Upload) no longer need to be converted separately。
    _observeAndShift(records);
    final complete = sawEnd && !sawCorrupt;
    _log(
      '0xD3 Batch read: startSN=$fromSn receive ${records.length} strip '
      '${complete
          ? "whole(end frame)"
          : sawEnd
          ? "Contains bad frames"
          : "interrupt(idle timeout)"}',
    );
    debugPrint(
      'CGM_RX Batch read(0xD3) startSN=$fromSn common ${records.length} strip '
      '${complete ? "whole" : "incomplete"}',
    );
    return (records: records, complete: complete);
  }

  @override
  Future<void> setFastLink(bool on) async {
    final d = _device;
    if (d == null) return;
    if (!BleLinkTuning.ownStableInterval) {
      // A/B File: No priority request is sent, allowing the connection parameters negotiated by the firmware to take effect throughout the process. Android central have the right
      // Directly deliver connection parameter updates. If the firmware negotiates a longer interval, we will pull it back at any time, consuming more power.。
      // Lift high You must also stop along the way: if you only block ”downshift”, make up for the upshift. high(11.25-15ms/latency0)
      // It will never come back down, transmitter 3-4 The day is exhausted. Covering itself is unreliable high，200ms The interval is only a second or two slower.。
      _log(
        'Connection priority is not delivered(A/B: Let the parameters negotiated by the firmware take effect throughout the process, on=$on)',
      );
      return;
    }
    // For steady state lowPower instead of balanced：balanced It is the default file of Android(30-50ms,latency 0)，
    // Wake frequency exceeds coin cell battery budget；lowPower about 17µA，The price is 0xB0 at most late 0.4 Seconds to arrive。
    // Must try again: if failed once, the whole game will stop balanced，Wake-up frequency difference 10 times; when first connected GATT Still busy，
    // It is common for the first request to be rejected。
    Object? lastErr;
    for (var i = 1; i <= _connPriorityRetries; i++) {
      try {
        await d.requestConnectionPriority(
          connectionPriorityRequest: on
              ? ConnectionPriority.high
              : ConnectionPriority.lowPower,
        );
        _log(
          'Connection priority → ${on ? "high(interval11.25-15ms,speed up0xD4)" : "lowPower(interval100-125ms+latency2,Save transmitter power)"}'
          '${i > 1 ? "(No. $i success)" : ""}',
        );
        return;
      } catch (e) {
        lastErr = e;
        // iOS throw androidOnly，It’s useless to try again, just cancel the first time
        if (e.toString().contains('androidOnly')) break;
        if (i < _connPriorityRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    // It will also be thrown if the device is disconnected. In that case, the connection will be reset naturally, so it is not a problem.
    _log(
      '${on ? "Lift high" : "drop lowPower"} fail'
      '($_connPriorityRetries Second-rate): $lastErr'
      '${on ? "，Only affects the recovery speed" : "，⚠️The link may stop at 30-50ms High power consumption level"}',
    );
  }

  /// Number of retries for connection priority requests, see [setFastLink]。
  static const int _connPriorityRetries = 3;

  /// low battery threshold 2300mV，and equipment cycle alarm thresholds 2.3V Consistent: below this level, only alarms are issued but no blocking is performed.。
  static const int _minBatteryMv = 2300;

  @override
  Future<void> startMeasureSequence(DateTime at) async {
    // Timing 0xE5→0xE1→0xC4→0xC0→0xD1，lack 0xE5 Write a reply to the meeting"Measuring SN=0、Don’t push 0xB0"。
    // Failure of the first two read commands will not block subsequent startups.。

    // resetCount≠1 It means that the abnormality has been reset, and the same value is written back to confirm.
    try {
      final r = await _invoke(
        CgmCommand.buildReadReset(),
        CgmCommand.cmdReadReset,
      );
      final info = CgmCommand.resetInfoFrom(r.payload);
      _log(
        'Measurement startup sequence: 0xE5 reset message resetCount=${info.resetCount} '
        'resetFlag=0x${info.resetFlag.toRadixString(16)}',
      );
      if (info.resetCount != 1) {
        _log(
          'Measurement startup sequence: 0xE5 resetCount≠1 → Write the reply bit information to confirm the reset…',
        );
        await _invoke(
          CgmCommand.buildResetResetInfo(info.resetCount, info.resetFlag),
          CgmCommand.cmdReadReset,
        );
      }
    } catch (e) {
      _log(
        'Measurement startup sequence: 0xE5 Read reset information/Write failed(Ignore continue): $e',
      );
    }

    try {
      final v = await _invoke(
        CgmCommand.buildReadVoltage(),
        CgmCommand.cmdReadVoltage,
      );
      final mv = CgmCommand.voltageMvFrom(v.payload);
      _log(
        'Measurement startup sequence: 0xE1 Power=${mv}mV'
        '${mv > 0 && mv < _minBatteryMv ? " ⚠️lower than${_minBatteryMv}mV(Still continuing)" : ""}',
      );
    } catch (e) {
      _log(
        'Measurement startup sequence: 0xE1 Failed to read battery capacity(Ignore continue): $e',
      );
    }

    _log(
      'Measurement startup sequence: 0xC4 Write measurement parameters(freq=3/t=0/cycle=60)…',
    );
    await _invoke(CgmCommand.buildMeasureParams(), CgmCommand.cmdMeasureParams);
    _log('Measurement startup sequence: 0xC0 Hall lock…');
    await _invoke(CgmCommand.buildHallControl(true), CgmCommand.cmdHallControl);
    _log('Measurement startup sequence: 0xD1 Start measuring…');
    await _invoke(CgmCommand.buildStartMeasure(at), CgmCommand.cmdStartMeasure);
    _log(
      'Measurement start sequence completed(0xE5→0xE1→0xC4→0xC0→0xD1)，The device should press cycle frames per minute、'
      'SN Increment (wait for first frame 0xB0；SN If it still doesn’t rise, the sensor is not plugged in properly./prenatal signal）',
    );
    debugPrint(
      'CGM_TX Measurement start sequence completed(0xE5→0xE1→0xC4→0xC0→0xD1)，about 1 It should be in minutes 0xB0',
    );
  }

  @override
  Stream<List<int>> measurements() => _measureController.stream;

  @override
  Future<void> disconnect() => _safeDisconnect();

  /// Connection status subscription for watch reconnection (separate from the regular link, does not affect each other)）。
  StreamSubscription<BluetoothConnectionState>? _watchSub;

  @override
  Future<void> watchReconnect() async {
    // Android There is a front-end service to pin the process + 2 Reconnect and retry every minute. This path is only for iOS exist；
    // exist Android Hang another one autoConnect Will crash with regular reconnection。
    if (!Platform.isIOS) return;
    final saved = await _savedPeripheralId();
    final d = _device ?? (saved == null ? null : BluetoothDevice.fromId(saved));
    if (d == null) {
      _log(
        'Watch and reconnect: No peripheral The handle is available, skip (it will be saved next time you connect)）',
      );
      return;
    }
    await _watchSub?.cancel();
    _watchSub = d.connectionState.listen((st) {
      if (st != BluetoothConnectionState.connected) return;
      _log(
        'Watch and reconnect: The device is back → Notification collection side recovery',
      );
      _watchSub?.cancel();
      _watchSub = null;
      _connectionController.add(true);
    });
    _log(
      'Watch and reconnect: hang pending connect(No timeout)，The device automatically connects and wakes up when it returns within range. App',
    );
    // autoConnect and mtu mutually exclusive（FBP assertion), the regular path will negotiate by itself after connecting. MTU
    unawaited(
      d
          .connect(autoConnect: true, mtu: null)
          .catchError(
            (Object e) =>
                _log('Watch and reconnect: pending connect fail(neglect): $e'),
          ),
    );
  }

  /// Write the command and wait for the response frame with the same command number. If it times out, throw [TimeoutException]。
  Future<CgmResponse> _invoke(Uint8List request, int expectedCmd) async {
    final w = _writeChar;
    if (w == null) {
      throw StateError('Device not connected(no write feature)');
    }
    final source =
        _notifyChar ??
        w; // If there is no independent notification feature, it will fall back to writing the feature itself to monitor.
    final cmdHex = expectedCmd.toRadixString(16).padLeft(2, '0');
    // Only supports writeWithoutResponse The characteristics must be passed true，Otherwise report WRITE property not supported
    final withoutResponse =
        !w.properties.write && w.properties.writeWithoutResponse;
    _log(
      'write command 0x$cmdHex → ${_hex(request)} '
      '(Write=${w.uuid.str}${withoutResponse ? " No response" : " There is a response"} listen=${source.uuid.str})',
    );
    debugPrint(
      'CGM_TX 0x$cmdHex → ${_hex(request)} Write=${w.uuid.str}'
      '${withoutResponse ? " (No reply to write)" : ""} listen=${source.uuid.str}',
    );

    // Build the monitor first and then write to avoid missing fast responses and bad frames/Extraneous frame skipping
    final logSub = source.onValueReceived.listen(
      (b) => _log('frame received ${source.uuid.str}: ${_hex(b)}'),
    );
    final future = source.onValueReceived
        .map((b) => _tryParse(b))
        .where((r) => r != null && r.commandId == expectedCmd)
        .cast<CgmResponse>()
        .first
        .timeout(commandTimeout);
    try {
      await w.write(request, withoutResponse: withoutResponse);
      final resp = await future;
      debugPrint('CGM_TX 0x$cmdHex ✓ Device answered');
      return resp;
    } on TimeoutException {
      _log(
        'Order 0x$cmdHex time out ${commandTimeout.inMilliseconds}ms，No matching reply received',
      );
      debugPrint(
        'CGM_TX 0x$cmdHex ✗ time out${commandTimeout.inMilliseconds}ms，Device not answering',
      );
      rethrow;
    } finally {
      await logSub.cancel();
    }
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  /// Broadcast name comparison: remove leading and trailing blanks + Case is ignored. Empty names are never counted as hits.。
  static bool _sameBleName(String got, String want) {
    final g = got.trim();
    return g.isNotEmpty && g.toUpperCase() == want.trim().toUpperCase();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Hit every frame sent from the device to the console。
  static void _printRx(String charUuid, List<int> v, bool isMeasure) {
    final hex = _hex(v);
    if (!isMeasure) {
      debugPrint(
        'CGM_RX frame received(non-measurement,${v.length}byte): $hex   [$charUuid]',
      );
      return;
    }
    try {
      final r = CgmCommand.parseMeasurement(Uint8List.fromList(v));
      final t = DateTime.fromMillisecondsSinceEpoch(
        r.timestampSec * 1000,
        isUtc: true,
      );
      final ts =
          '${t.year}-${_two(t.month)}-${_two(t.day)} '
          '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
      debugPrint(
        'CGM_RX receiveCGMraw data(0xB0,${v.length}byte): $hex'
        '  →Decode serial number=${r.recordSeq} time=$ts '
        'Voltage=${r.voltage.toStringAsFixed(3)}V '
        'temperature=${r.temperature.toStringAsFixed(1)}℃ '
        'WE1current=${r.rawCurrent.toStringAsFixed(2)}nA   [$charUuid]',
      );
    } catch (e) {
      debugPrint(
        'CGM_RX receiveCGMraw data(0xB0,Decoding failed:$e,${v.length}byte): $hex   [$charUuid]',
      );
    }
  }

  static CgmResponse? _tryParse(List<int> bytes) {
    try {
      return CgmCommand.parseResponse(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelMeasureSubs() async {
    for (final s in _measureSubs) {
      await s.cancel();
    }
    _measureSubs.clear();
  }

  /// subscription GATT Link status: non-active disconnect push false Let the collection side stop output；
  /// Actively disconnect and go away [_safeDisconnect] Unsubscribe first without pushing events。
  Future<void> _watchConnectionState(BluetoothDevice device) async {
    await _connStateSub?.cancel();
    _connStateSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected &&
          identical(_device, device)) {
        _log(
          'GATT Link down(Inactive)→Notify the collection side to stop output',
        );
        _connectionController.add(false);
      }
    });
  }

  Future<void> _safeDisconnect() async {
    final device = _device;
    await _connStateSub?.cancel();
    _connStateSub = null;
    await _watchSub?.cancel();
    _watchSub = null;
    await _cancelMeasureSubs();
    _writeChar = null;
    _notifyChar = null;
    _notifyCharsAll.clear();
    _device = null;
    if (device == null) return;
    try {
      await device.disconnect();
    } catch (_) {
      // It doesn’t matter if the disconnect fails, the reference has been cleared
    }
  }
}
