import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide LogLevel;

import 'package:cgm_sdk/src/algorithm/glucose_value.dart';
import 'package:cgm_sdk/src/algorithm/jni_algorithm_gateway.dart';
import 'package:cgm_sdk/src/ble/fbp_ble_adapter_monitor.dart';
import 'package:cgm_sdk/src/ble/real_cgm_ble_gate.dart';
import 'package:cgm_sdk/src/collection/cgm_replay_dataset.dart';
import 'package:cgm_sdk/src/collection/flutter_foreground_service_controller.dart';
import 'package:cgm_sdk/src/collection/foreground_service_controller.dart';
import 'package:cgm_sdk/src/collection/glucose_collection_runner.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';
import 'package:cgm_sdk/src/db/database_key_store.dart';
import 'package:cgm_sdk/src/domain/activation_check.dart';
import 'package:cgm_sdk/src/domain/bind_activation_service.dart';
import 'package:cgm_sdk/src/domain/bind_hooks.dart';
import 'package:cgm_sdk/src/domain/ble_adapter_monitor.dart';
import 'package:cgm_sdk/src/domain/cgm_ble_gate.dart';
import 'package:cgm_sdk/src/domain/device_scan_result.dart';
import 'package:cgm_sdk/src/domain/sdk_tuning.dart';
import 'package:cgm_sdk/src/domain/wear_lifecycle_resolver.dart';
import 'package:cgm_sdk/src/facade/errors.dart';
import 'package:cgm_sdk/src/facade/file_export.dart' as fx;
import 'package:cgm_sdk/src/facade/models.dart';
import 'package:cgm_sdk/src/facade/qr_parser.dart' as qr;
import 'package:cgm_sdk/src/facade/signal_rules.dart';
import 'package:cgm_sdk/src/glucose/algo_param_store.dart';
import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';
import 'package:cgm_sdk/src/status/backfill_status.dart';
import 'package:cgm_sdk/src/status/connect_status.dart';
import 'package:cgm_sdk/src/status/link_activity.dart';
import 'package:cgm_sdk/src/wear/wear_repository.dart';

/// SDK version, with pubspec.yaml synchronous。
const String cgmSdkVersion = '4';

/// bind The host callback: called after the verification is passed and before activation. The host calls its own backend binding interface here.。
typedef BeforeActivate = Future<BeforeActivateResult> Function(BindCheck check);

/// CGM SDK facade（《CGM SDK Interface Document》Three-terminal interface with the same name Flutter version）。
///
/// All interfaces are static methods; events are broadcast streams. Internal self-built encryption library / Bluetooth gateway / Wear warehouse / collection runner，
/// Assembly and App `core/di/injection.dart` Same set, remove upload / Cloud / Accounts (those belong to the host）。
/// App I don’t show off myself, I still use core classes directly.。
class CgmSdk {
  CgmSdk._();

  static _Core? _c;

  static _Core _core() {
    final c = _c;
    if (c == null) throw CgmSdkException(CgmErrorCode.notInitialized);
    return c;
  }

  // ───────────────────────── 1~4 life cycle ─────────────────────────

  /// Initialization: Open the encryption library, assemble the Bluetooth gateway and collection runner、Verification algorithm library. Repeated calls have no side effects。
  /// Automatically resume collection when there are unfinished wearing records (cold start / reopen App）。
  static Future<void> init({
    SdkConfig config = const SdkConfig(),
    @visibleForTesting CgmDatabase? database,
    @visibleForTesting CgmBleGate? gate,
    @visibleForTesting BleAdapterMonitor? adapterMonitor,
    @visibleForTesting bool checkAlgorithm = true,
    @visibleForTesting Future<CgmReplayDataset> Function()? replayLoader,
  }) async {
    if (_c != null) return;
    SdkTuning.warmupMinutes = config.warmupMinutes;
    SdkTuning.bindMinBatteryMv = config.minBatteryMv;
    final c = _Core(config);
    final mobile = Platform.isAndroid || Platform.isIOS;
    try {
      c.db = database ?? CgmDatabase.encrypted(keyStore: c.keyStore);
      await c.db.customSelect('SELECT 1').get();
    } catch (e) {
      throw CgmSdkException(CgmErrorCode.storageFailed, '$e');
    }
    c.wearRepo = WearRepository(c.db);
    c.algoStore = AlgoParamStore(c.db);
    c.gate =
        gate ??
        (mobile
            ? RealCgmBleGate(
                savePeripheralId: c.algoStore.savePeripheralId,
                readPeripheralId: c.algoStore.readPeripheralId,
              )
            : MockCgmBleGate());
    c.adapter =
        adapterMonitor ?? (mobile ? const FbpBleAdapterMonitor() : null);
    c.runner = GlucoseCollectionRunner(
      db: c.db,
      wearRepo: c.wearRepo,
      gate: c.gate,
      adapterMonitor: c.adapter,
      foregroundService: Platform.isAndroid
          ? _NoticeForegroundService(
              FlutterForegroundServiceController(),
              config.foregroundNotice,
            )
          : null,
      onFrameComputed: c._onFrame,
      replayLoader: replayLoader,
    );
    if (mobile && checkAlgorithm) {
      try {
        c.algoVersion = _cleanVersion(await JniAlgorithmGateway().version());
      } catch (e) {
        await c.runner.dispose();
        throw CgmSdkException(CgmErrorCode.algoInitFailed, '$e');
      }
    }
    c.attach();
    _c = c;
    c.log(
      'init Finish config: preheat=${config.warmupMinutes}min voltage gate=${config.minBatteryMv}mV',
    );
    // After cold start, if you are wearing it, just pull up the collection (reconnect → 0xD3 cover → real time）
    if (await c.wearRepo.currentWearSnapshot() != null) {
      unawaited(c.runner.ensureRunning().then((_) => c.refreshConnection()));
    }
  }

  /// Release: disconnect the device, stop collection, close the library, close the event stream。
  static Future<void> dispose() async {
    final c = _c;
    if (c == null) return;
    _c = null;
    await c.detach();
  }

  /// SDK version number。
  static Future<String> version() async => cgmSdkVersion;

  /// Algorithm library（.so / .a）version number。
  static Future<String> algorithmVersion() async {
    final c = _core();
    final cached = c.algoVersion;
    if (cached != null) return cached;
    try {
      return c.algoVersion = _cleanVersion(
        await JniAlgorithmGateway().version(),
      );
    } catch (e) {
      throw CgmSdkException(CgmErrorCode.algoInitFailed, '$e');
    }
  }

  /// .so The returned version string has a non-trailer UTF-8 Garbage bytes（vivo Actual measurement "V1.2.4_r1\uFFFD\uFFFD"），Only printable ASCII。
  static String _cleanVersion(String v) =>
      v.replaceAll(RegExp(r'[^\x20-\x7e]'), '').trim();

  // ───────────────────────── 5~7 QR code / scanning ─────────────────────────

  /// Parsing the device QR code, not connected to the Internet, no need init。
  static QrInfo parseQrCode(String code) => qr.parseQrCode(code);

  /// Scan nearby CGM device (broadcast name `CGM-Device number`），Sent once per device; timeout or [stopScan] end of backflow。
  static Stream<ScanDevice> scan({int timeoutSeconds = 10}) {
    final c = _core();
    final ctrl = StreamController<ScanDevice>();
    ctrl.onListen = () => c.runScan(ctrl, Duration(seconds: timeoutSeconds));
    return ctrl.stream;
  }

  /// End scan early。
  static Future<void> stopScan() async {
    _core();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  // ───────────────────────── 8~14 binding / connect / wear ─────────────────────────

  /// Bind and activate: connect → Read voltage → check → [beforeActivate] Hand over the host and bind the backend → activation → Drop wearing record → Start collecting。
  static Future<WearInfo> bind({
    required String deviceId,
    required String form,
    required AlgoParams calibration,
    DateTime? expireDate,
    String? transmitterSn,
    String? sensorSn,
    BeforeActivate? beforeActivate,
  }) async {
    final c = _core();
    final mac = macFromDeviceId(deviceId);
    if (mac == null) {
      throw CgmSdkException(
        CgmErrorCode.deviceNotFound,
        'The device number is invalid: $deviceId',
      );
    }
    final f = _parseForm(form);
    _checkAlgoParams(calibration);
    c.checkAdapterOn();
    return c.exclusive(() async {
      c.log('bind deviceId=$deviceId form=$form');
      c.connecting = true;
      c.refreshConnection();
      try {
        await c.runner.stop();
        final svc = BindActivationService(
          ble: c.gate,
          wearRepo: c.wearRepo,
          hooks: _HostBindHooks(beforeActivate),
          algoParamStore: c.algoStore,
        );
        final outcome = await svc.bindAndActivate(
          form: f,
          transmitterId: 0,
          transmitterSn: transmitterSn ?? deviceId.toUpperCase(),
          sensorId: 0,
          sensorSn: sensorSn ?? deviceId.toUpperCase(),
          bluetoothAddr: mac,
          userId: 0,
          expireDate: expireDate?.toIso8601String(),
          sensorAttr: SensorAttr(
            k: calibration.tempCoef1,
            b: calibration.tempCoef2,
          ),
        );
        if (outcome.connectionFailed) {
          throw CgmSdkException(
            CgmErrorCode.connectFailed,
            'Failed to connect to the device, please move closer to the device and try again',
          );
        }
        switch (outcome.reject) {
          case ActivationReject.lowVoltage:
            throw CgmSdkException(CgmErrorCode.lowVoltage);
          case ActivationReject.expired:
            throw CgmSdkException(CgmErrorCode.deviceExpired);
          case ActivationReject.inUseFull:
          case ActivationReject.inUseHalf:
          case null:
            break;
        }
        if (outcome.message != null) {
          throw CgmSdkException(CgmErrorCode.bindRejected, outcome.message);
        }
        // Full set of coverage: not transmitted bgmBase / Clear the parameter setting and the last value worn will not be used.
        await c.algoStore.saveCgmBase(calibration.bgmBase, clearIfNull: true);
        await c.algoStore.saveAlgoTuning(calibration.tuning);
        c.resetWearState();
        await c.runner.ensureRunning();
        final wear = await c.currentWearInfo();
        if (wear == null) {
          throw CgmSdkException(
            CgmErrorCode.storageFailed,
            'Wearing record writing failed',
          );
        }
        return wear;
      } finally {
        c.connecting = false;
        c.refreshConnection();
      }
    });
  }

  /// Restore the bound device (change the device / Reinstall / Cold start): drop wearing records, direct connection, pull back all history in the device and recalculate。
  static Future<void> resume(WearInfo info) async {
    final c = _core();
    final mac = macFromDeviceId(info.deviceId);
    if (mac == null) {
      throw CgmSdkException(
        CgmErrorCode.notBound,
        'The device number is invalid: ${info.deviceId}',
      );
    }
    c.checkAdapterOn();
    await c.exclusive(() async {
      c.log('resume wearId=${info.wearId} deviceId=${info.deviceId}');
      final snap = await c.wearRepo.currentWearSnapshot();
      final same =
          snap != null &&
          snap.wearId == info.wearId &&
          snap.handleStatus != '$kWearStatusUnbound';
      if (!same) {
        await c.runner.stop();
        await c.wearRepo.saveActivation(
          userId: 0,
          wearId: info.wearId,
          transmitterId: 0,
          transmitterSn: info.transmitterSn ?? info.deviceId.toUpperCase(),
          sensorId: 0,
          sensorSn: info.sensorSn ?? info.deviceId.toUpperCase(),
          bluetoothAddr: mac,
          deviceForm: info.form,
          activeTime: info.activatedAt,
        );
        c.resetWearState();
      }
      final cal = info.calibration;
      if (cal != null) {
        _checkAlgoParams(cal);
        await c.algoStore.saveSensorCalibration(
          k: cal.tempCoef1,
          b: cal.tempCoef2,
        );
        await c.algoStore.saveCgmBase(cal.bgmBase, clearIfNull: true);
        await c.algoStore.saveAlgoTuning(cal.tuning);
      }
      await c.algoStore.saveBluetoothAddr(mac);
      // iOS of bleId yes CoreBluetooth Handle, save it to connect directly without scanning
      if (info.bleId.isNotEmpty && info.bleId.toUpperCase() != mac) {
        await c.algoStore.savePeripheralId(info.bleId);
      }
      await c.connectNow();
    });
  }

  /// Manually connect the currently bound device (not normally required，SDK Automatically reconnect）。
  static Future<void> connect() async {
    final c = _core();
    if (await c.wearRepo.currentWearSnapshot() == null) {
      throw CgmSdkException(CgmErrorCode.notBound);
    }
    c.checkAdapterOn();
    await c.exclusive(c.connectNow);
  }

  /// Manual disconnect: stop collecting and disconnect the link, do not wear the record without moving; adjust again [connect] or restart App will automatically recover。
  static Future<void> disconnect() async {
    final c = _core();
    await c.runner.stop();
    c.refreshConnection();
  }

  /// Unbind: Disconnect the device, end local wearing records, and stop collection. Local blood glucose data retention。
  static Future<void> unbind() async {
    final c = _core();
    final snap = await c.wearRepo.currentWearSnapshot();
    if (snap == null) throw CgmSdkException(CgmErrorCode.notBound);
    await c.exclusive(() async {
      c.log('unbind wearId=${snap.wearId}');
      await c.runner.stop();
      await c.wearRepo.recordUnbind(
        userId: snap.userId,
        accountId: snap.accountId,
        wearId: snap.wearId,
        reason: 'Host unbinding',
      );
      await c.algoStore.clearBluetoothAddr();
      await c.gate.disconnect();
      c.resetWearState();
      c.refreshConnection();
    });
  }

  /// Current wearing record; not bound / Returned after unbinding null。
  static Future<WearInfo?> currentWear() => _core().currentWearInfo();

  /// Read the current status to the device once（0xE3 / 0xE1 / 0xE7）。The device is not connected E_CONNECT_FAILED。
  static Future<CgmDeviceInfo> deviceInfo() async {
    final c = _core();
    if (!c.runner.isDeviceLinked) {
      throw CgmSdkException(CgmErrorCode.connectFailed, 'Device not connected');
    }
    final wear = await c.currentWearInfo();
    try {
      final st = await c.gate.readMeasureState();
      final mv = await c.gate.readBatteryMv();
      String fw = '';
      try {
        fw = await c.gate.readFirmwareVersion() ?? '';
      } catch (e) {
        c.log('Failed to read firmware version(neglect): $e');
      }
      return CgmDeviceInfo(
        deviceId: wear?.deviceId ?? '',
        firmware: fw,
        batteryMv: mv,
        latestSeq: st.latestSn,
        measuring: st.measuring,
        measuredSec: st.measuredSec,
      );
    } catch (e) {
      if (e is CgmSdkException) rethrow;
      throw CgmSdkException(
        CgmErrorCode.connectFailed,
        'Failed to read device status: $e',
      );
    }
  }

  // ───────────────────────── 15~16 Algorithm parameters ─────────────────────────

  /// Set the algorithm parameters and persist them; while the collection is running, hot restart and recalculate and write back all the history of this wearing period according to the new parameters.，
  /// If you are not running, the breakpoint will be dropped, and the collection will be supplemented from the next time.。
  static Future<void> setAlgoParams(AlgoParams p) async {
    final c = _core();
    _checkAlgoParams(p);
    await c.algoStore.saveSensorCalibration(k: p.tempCoef1, b: p.tempCoef2);
    await c.algoStore.saveCgmBase(p.bgmBase, clearIfNull: true);
    await c.algoStore.saveAlgoTuning(p.tuning);
    c.log(
      'setAlgoParams tempCoef1=${p.tempCoef1} tempCoef2=${p.tempCoef2} '
      'bgmBase=${p.bgmBase} Adjust parameters=${p.tuning}',
    );
    var recomputed = 0;
    if (c.runner.isRunning) {
      await c.runner
          .ensureRunning(); // The calibration fingerprint has changed → Hot restart to change new parameters
      recomputed = await c.runner.recomputeCurrentWear();
    }
    if (recomputed == 0 && !c.runner.isRunning) {
      final snap = await c.wearRepo.currentWearSnapshot();
      if (snap != null) {
        await GlucosePipelineRepository.markPendingRecompute(
          c.db,
          snap.wearId,
          snap.activeTime.toUtc().millisecondsSinceEpoch,
        );
      }
    }
  }

  /// Read the current algorithm parameters; no return null。
  static Future<AlgoParams?> getAlgoParams() async {
    final c = _core();
    return c.readAlgoParams();
  }

  /// Kalman Q/R Paired and equal parameter constraints, illegal throw E_INVALID_ARGUMENT。
  static void _checkAlgoParams(AlgoParams p) {
    final reason = p.invalidReason;
    if (reason != null) {
      throw CgmSdkException(CgmErrorCode.invalidArgument, reason);
    }
  }

  // ───────────────────────── 17~23 local data ─────────────────────────

  /// Check blood glucose records by time period, in ascending order of measurement time。
  static Future<List<GlucoseSample>> query({
    DateTime? from,
    DateTime? to,
    int? wearId,
    int limit = 5000,
  }) => _core().querySamples(from: from, to: to, wearId: wearId, limit: limit);

  /// The latest blood sugar; no return null。
  static Future<GlucoseSample?> latest() async {
    final rows = await _core().querySamples(limit: 1, newestFirst: true);
    return rows.isEmpty ? null : rows.first;
  }

  /// Subscribe to add new blood sugar: push a batch first when subscribing [from] If there are existing ones after that, they will be pushed once for each new batch.。
  static Stream<List<GlucoseSample>> watch({DateTime? from}) {
    final c = _core();
    late StreamController<List<GlucoseSample>> ctrl;
    StreamSubscription<void>? sub;
    var lastId = 0;
    var chain = Future<void>.value();
    void pump() {
      chain = chain
          .then((_) async {
            if (ctrl.isClosed) return;
            final rows = await c.rowsAfterId(lastId, from);
            if (rows.isEmpty) return;
            lastId = rows.last.$1;
            ctrl.add(rows.map((r) => r.$2).toList());
          })
          .catchError((Object e) {
            if (!ctrl.isClosed) ctrl.addError(e);
          });
    }

    ctrl = StreamController<List<GlucoseSample>>(
      onListen: () {
        pump();
        sub = c.db
            .tableUpdates(TableUpdateQuery.onTable(c.db.userlocalGlucoseData))
            .listen((_) => pump());
      },
      onCancel: () async {
        await sub?.cancel();
        await ctrl.close();
      },
    );
    return ctrl.stream;
  }

  /// Check device raw data。
  static Future<List<RawSample>> queryRaw({DateTime? from, DateTime? to}) =>
      _core().queryRaw(from: from, to: to);

  /// Export data file（csv / json），Return absolute path。
  static Future<String> export({
    DateTime? from,
    DateTime? to,
    String format = 'csv',
  }) async {
    if (format != 'csv' && format != 'json') {
      throw CgmSdkException(
        CgmErrorCode.invalidArgument,
        'format can only be csv / json',
      );
    }
    final rows = await _core().querySamples(from: from, to: to, limit: 1 << 31);
    return fx.exportSamples(rows, format: format);
  }

  /// Delete local data (blood glucose + raw data + unprocessed frames), neither is transmitted = Delete all; return the number of deleted blood glucose records。
  static Future<int> deleteData({DateTime? from, DateTime? to, int? wearId}) =>
      _core().deleteData(from: from, to: to, wearId: wearId);

  /// Number of local blood sugar bars。
  static Future<int> count({int? wearId}) => _core().count(wearId: wearId);

  // ───────────────────────── 24~25 log / diagnosis ─────────────────────────

  /// Set log level (only affects [log] Event filtering）。
  static Future<void> setLogLevel(LogLevel level) async {
    _core().logLevel = level;
  }

  /// Export diagnostic package zip（Clear text library copy + log, without key), returns the absolute path。
  static Future<String> exportDiagnostics() async {
    final c = _core();
    final snap = await c.wearRepo.currentWearSnapshot();
    final state = StringBuffer()
      ..writeln('sdk=$cgmSdkVersion algo=${c.algoVersion}')
      ..writeln('platform=${Platform.operatingSystem}')
      ..writeln('wear=$snap')
      ..writeln(
        'running=${c.runner.isRunning} linked=${c.runner.isDeviceLinked}',
      )
      ..writeln('hint=${ConnectStatus.hint.value}')
      ..writeln(
        'lastFrameAt=${LinkActivity.lastFrameAt} lastComputedAt=${LinkActivity.lastComputedAt}',
      )
      ..writeln('calibration=${(await getAlgoParams())?.toMap()}');
    return fx.exportDiagnostics(c.db, extraText: state.toString());
  }

  // ───────────────────────── event ─────────────────────────

  static Stream<CgmConnectionState> get connectionState =>
      _core().connState.stream;
  static Stream<DeviceStatus> get deviceStatus => _core().devStatus.stream;
  static Stream<GlucoseSample> get glucose => _core().glucoseCtrl.stream;
  static Stream<AlgoResult> get algoResult => _core().algoCtrl.stream;
  static Stream<ProgressEvent> get progress => _core().progressCtrl.stream;
  static Stream<SdkErrorEvent> get error => _core().errorCtrl.stream;
  static Stream<SdkLogEvent> get log => _core().logCtrl.stream;

  // ───────────────────────── helpers ─────────────────────────

  static DeviceForm _parseForm(String form) {
    switch (form) {
      case 'half':
        return DeviceForm.half;
      case 'full':
        return DeviceForm.full;
      default:
        throw CgmSdkException(
          CgmErrorCode.invalidArgument,
          'form can only be half / full',
        );
    }
  }
}

/// Facade internal state: assembled core object + 7 event stream + derived state。
class _Core {
  _Core(this.config);

  final SdkConfig config;
  final keyStore = DatabaseKeyStore();
  late final CgmDatabase db;
  late final WearRepository wearRepo;
  late final AlgoParamStore algoStore;
  late final CgmBleGate gate;
  BleAdapterMonitor? adapter;
  late final GlucoseCollectionRunner runner;
  String? algoVersion;
  LogLevel logLevel = LogLevel.info;

  final connState = StreamController<CgmConnectionState>.broadcast();
  final devStatus = StreamController<DeviceStatus>.broadcast();
  final glucoseCtrl = StreamController<GlucoseSample>.broadcast();
  final algoCtrl = StreamController<AlgoResult>.broadcast();
  final progressCtrl = StreamController<ProgressEvent>.broadcast();
  final errorCtrl = StreamController<SdkErrorEvent>.broadcast();
  final logCtrl = StreamController<SdkLogEvent>.broadcast();

  bool connecting = false;
  bool scanning = false;
  bool busy = false;
  CgmConnectionState? lastConn;

  // The latest scene，deviceStatus For events
  int? lastBatteryMv;
  double? lastTemp;
  int? lastSeq;

  // Exception judgment buffer (press wear clear）
  final warmupSamples = <SignalSample>[];
  final recentSamples = <SignalSample>[];
  final firedOnce = <CgmErrorCode>{}; // Every wear Only reported once
  final active =
      <
        CgmErrorCode
      >{}; // Have a beginning and an end（onset Report once, you can report again after recovery）
  String? currentAbnormal;
  int? stateWearId;

  Timer? tick;
  int tickCount = 0;
  StreamSubscription<bool>? linkSub;
  StreamSubscription<List<ScanResult>>? scanSub;
  DevLogEntry? lastLogSeen;
  String? lastHint;

  void log(String msg) => DevLog.instance.add('sdk', msg);

  // ── assembly / Disassembly ──

  void attach() {
    ConnectStatus.hint.addListener(_onHint);
    BackfillStatus.progress.addListener(_onProgress);
    DevLog.instance.addListener(_onDevLog);
    linkSub = gate.connectionChanges.listen((_) => refreshConnection());
    tick = Timer.periodic(const Duration(seconds: 5), (_) => _onTick());
  }

  Future<void> detach() async {
    tick?.cancel();
    ConnectStatus.hint.removeListener(_onHint);
    BackfillStatus.progress.removeListener(_onProgress);
    DevLog.instance.removeListener(_onDevLog);
    await linkSub?.cancel();
    await scanSub?.cancel();
    await runner.dispose();
    try {
      await gate.disconnect();
    } catch (_) {}
    await db.close();
    for (final s in [
      connState,
      devStatus,
      glucoseCtrl,
      algoCtrl,
      progressCtrl,
      errorCtrl,
      logCtrl,
    ]) {
      await s.close();
    }
  }

  /// bind / resume / connect / unbind mutually exclusive, overlap E_BUSY。
  Future<T> exclusive<T>(Future<T> Function() op) async {
    if (busy) throw CgmSdkException(CgmErrorCode.busy);
    busy = true;
    try {
      return await op();
    } finally {
      busy = false;
    }
  }

  void checkAdapterOn() {
    final a = adapter;
    if (a != null && !a.isOnNow) throw CgmSdkException(CgmErrorCode.bleOff);
  }

  /// Start collecting and ask for connection on the spot. If connection fails, report E_CONNECT_FAILED（runner Still in the background, press escape to try again）。
  Future<void> connectNow() async {
    connecting = true;
    refreshConnection();
    try {
      await runner.ensureRunning();
    } finally {
      connecting = false;
      refreshConnection();
    }
    if (!runner.isDeviceLinked) {
      throw CgmSdkException(
        CgmErrorCode.connectFailed,
        'The device is not connected yet，SDK Will automatically retry',
      );
    }
  }

  void resetWearState() {
    _snapCache = null;
    _snapAt = null;
    warmupSamples.clear();
    recentSamples.clear();
    firedOnce.clear();
    active.clear();
    currentAbnormal = null;
    stateWearId = null;
    lastBatteryMv = null;
    lastTemp = null;
    lastSeq = null;
  }

  // ── wear ──

  Future<WearInfo?> currentWearInfo() async {
    final snap = await wearRepo.currentWearSnapshot();
    if (snap == null || snap.handleStatus == '$kWearStatusUnbound') return null;
    final bind = await wearRepo.currentDeviceBind();
    final cur = await wearRepo.currentWear();
    final addr =
        bind?.bluetoothAddr ?? await algoStore.readBluetoothAddr() ?? '';
    final deviceId = addr.replaceAll(':', '').toUpperCase();
    final peripheral = await algoStore.readPeripheralId();
    return WearInfo(
      wearId: snap.wearId,
      deviceId: deviceId.isEmpty ? (bind?.transmitterSn ?? '') : deviceId,
      bleId: peripheral ?? addr,
      form: bind?.deviceType ?? 'full',
      activatedAt: snap.activeTime,
      warmupEndAt: snap.activeTime.add(SdkTuning.warmupDuration),
      expiresAt: snap.activeTime.add(const Duration(days: kWearLifetimeDays)),
      calibration: await readAlgoParams(),
      transmitterSn: cur?.transmitterSn ?? bind?.transmitterSn,
      sensorSn: cur?.sensorSn ?? bind?.sensorSn,
    );
  }

  /// Locally stored algorithm parameters are combined into external objects; none tempCoef1/2 return null。
  Future<AlgoParams?> readAlgoParams() async {
    final cal = await algoStore.readSensorCalibration();
    if (cal == null) return null;
    final t = await algoStore.readAlgoTuning();
    return AlgoParams(
      tempCoef1: cal.k,
      tempCoef2: cal.b,
      bgmBase: await algoStore.readCgmBase(),
      positiveSlope1: t.positiveSlope1,
      negativeSlope1: t.negativeSlope1,
      positiveSlope2: t.positiveSlope2,
      positiveSlope2Fixed: t.positiveSlope2Fixed,
      negativeSlope2: t.negativeSlope2,
      dayKalmanQ: t.dayKalmanQ,
      dayKalmanR: t.dayKalmanR,
      nightKalmanQ: t.nightKalmanQ,
      nightKalmanR: t.nightKalmanR,
    );
  }

  // ── scanning ──

  Future<void> runScan(
    StreamController<ScanDevice> ctrl,
    Duration timeout,
  ) async {
    try {
      bool supported;
      try {
        supported = await FlutterBluePlus.isSupported;
      } catch (_) {
        supported = false;
      }
      if (!supported) throw CgmSdkException(CgmErrorCode.bleUnavailable);
      checkAdapterOn();
      scanning = true;
      refreshConnection();
      final seen = <String>{};
      await scanSub?.cancel();
      scanSub = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          final adv = r.advertisementData.advName;
          final name = adv.isNotEmpty ? adv : r.device.platformName;
          final upper = name.toUpperCase();
          final hasFff0 = r.advertisementData.serviceUuids.any(
            (u) => u.str.toLowerCase().contains('fff0'),
          );
          final isCgm =
              upper.contains('CGM') ||
              upper.contains('SIMULATOR') ||
              upper.contains('GLUCO') ||
              hasFff0;
          if (!isCgm) continue;
          final id = r.device.remoteId.str;
          if (!seen.add(id)) continue;

          String devId = '26082400C221';
          if (upper.startsWith('CGM-')) {
            devId = name.substring(4).trim().toUpperCase();
          } else if (RegExp(
            r'[0-9A-F]{12}',
            caseSensitive: false,
          ).hasMatch(upper)) {
            devId = RegExp(
              r'[0-9A-F]{12}',
              caseSensitive: false,
            ).firstMatch(upper)!.group(0)!.toUpperCase();
          }

          ctrl.add(
            ScanDevice(
              deviceId: devId,
              name: name.isNotEmpty ? name : 'CGM Continuous Sensor',
              bleId: id,
              rssi: r.rssi,
            ),
          );
        }
      });
      await FlutterBluePlus.startScan(
        timeout: timeout,
        continuousUpdates: true,
      );
      await FlutterBluePlus.isScanning.where((s) => !s).first;
    } on CgmSdkException catch (e) {
      ctrl.addError(e);
    } catch (e) {
      final msg = '$e';
      final code =
          msg.toLowerCase().contains('permission') ||
              msg.contains('Permissions')
          ? CgmErrorCode.permissionDenied
          : CgmErrorCode.bleUnavailable;
      ctrl.addError(CgmSdkException(code, msg));
    } finally {
      await scanSub?.cancel();
      scanSub = null;
      scanning = false;
      refreshConnection();
      await ctrl.close();
    }
  }

  // ── Query ──

  static const _backfillLag = Duration(minutes: 3);

  GlucoseSample toSample(
    UserlocalGlucoseDataRow g,
    UserlocalGlucoseRawDataRow? raw,
  ) {
    final created = g.createTime;
    final String source;
    if (g.uploadFlag == '2') {
      source = 'replay';
    } else if (created != null &&
        created.difference(g.measureTime) > _backfillLag) {
      source = 'backfill';
    } else {
      source = 'live';
    }
    final v = raw?.voltageValue?.toString();
    return GlucoseSample(
      wearId: g.wearId,
      seq: g.recordSeq ?? 0,
      measuredAt: g.measureTime.toLocal(),
      value: g.glucoseValue1,
      warmup: g.warmupFlag == '1',
      abnormal: g.abnormalFlag == '1' || g.glucoseValue1 == null,
      source: source,
      rawCurrent: raw?.rawCurrent1,
      temperature: raw?.temperature1,
      voltage: v == null ? null : _mv(double.tryParse(v)),
    );
  }

  static double? _mv(double? volts) =>
      volts == null ? null : (volts * 1000).roundToDouble();

  Future<List<GlucoseSample>> querySamples({
    DateTime? from,
    DateTime? to,
    int? wearId,
    required int limit,
    bool newestFirst = false,
  }) async {
    final g = db.userlocalGlucoseData;
    final r = db.userlocalGlucoseRawData;
    final q = db.select(g).join([
      leftOuterJoin(
        r,
        r.wearId.equalsExp(g.wearId) & r.measureTime.equalsExp(g.measureTime),
      ),
    ]);
    final conds = <Expression<bool>>[];
    if (from != null) {
      conds.add(
        g.measureTime.isBiggerOrEqualValue(from.toUtc().millisecondsSinceEpoch),
      );
    }
    if (to != null) {
      conds.add(
        g.measureTime.isSmallerThanValue(to.toUtc().millisecondsSinceEpoch),
      );
    }
    if (wearId != null) conds.add(g.wearId.equals(wearId));
    if (conds.isNotEmpty) q.where(conds.reduce((a, b) => a & b));
    q.orderBy([
      OrderingTerm(
        expression: g.measureTime,
        mode: newestFirst ? OrderingMode.desc : OrderingMode.asc,
      ),
    ]);
    q.limit(limit);
    final rows = await q.get();
    return [
      for (final row in rows)
        toSample(row.readTable(g), row.readTableOrNull(r)),
    ];
  }

  /// id > [afterId] rows (insertion order），watch use。
  Future<List<(int, GlucoseSample)>> rowsAfterId(
    int afterId,
    DateTime? from,
  ) async {
    final g = db.userlocalGlucoseData;
    final r = db.userlocalGlucoseRawData;
    final q = db.select(g).join([
      leftOuterJoin(
        r,
        r.wearId.equalsExp(g.wearId) & r.measureTime.equalsExp(g.measureTime),
      ),
    ]);
    var cond = g.id.isBiggerThanValue(afterId);
    if (from != null) {
      cond =
          cond &
          g.measureTime.isBiggerThanValue(from.toUtc().millisecondsSinceEpoch);
    }
    q.where(cond);
    q.orderBy([OrderingTerm.asc(g.id)]);
    final rows = await q.get();
    return [
      for (final row in rows)
        (
          row.readTable(g).id,
          toSample(row.readTable(g), row.readTableOrNull(r)),
        ),
    ];
  }

  Future<List<RawSample>> queryRaw({DateTime? from, DateTime? to}) async {
    final r = db.userlocalGlucoseRawData;
    final q = db.select(r);
    if (from != null) {
      q.where(
        (t) => t.measureTime.isBiggerOrEqualValue(
          from.toUtc().millisecondsSinceEpoch,
        ),
      );
    }
    if (to != null) {
      q.where(
        (t) =>
            t.measureTime.isSmallerThanValue(to.toUtc().millisecondsSinceEpoch),
      );
    }
    q.orderBy([(t) => OrderingTerm.asc(t.measureTime)]);
    final rows = await q.get();
    return [
      for (final x in rows)
        RawSample(
          wearId: x.wearId ?? 0,
          seq: x.recordSeq ?? 0,
          measuredAt: x.measureTime.toLocal(),
          current: x.rawCurrent1,
          temperature: x.temperature1,
          voltage: _mv(double.tryParse(x.voltageValue?.toString() ?? '')),
          lactate: null,
        ),
    ];
  }

  Future<int> deleteData({DateTime? from, DateTime? to, int? wearId}) async {
    final fromMs = from?.toUtc().millisecondsSinceEpoch;
    final toMs = to?.toUtc().millisecondsSinceEpoch;
    var deleted = 0;
    await db.transaction(() async {
      final g = db.delete(db.userlocalGlucoseData);
      if (fromMs != null) {
        g.where((t) => t.measureTime.isBiggerOrEqualValue(fromMs));
      }
      if (toMs != null) g.where((t) => t.measureTime.isSmallerThanValue(toMs));
      if (wearId != null) g.where((t) => t.wearId.equals(wearId));
      deleted = await g.go();
      final r = db.delete(db.userlocalGlucoseRawData);
      if (fromMs != null) {
        r.where((t) => t.measureTime.isBiggerOrEqualValue(fromMs));
      }
      if (toMs != null) r.where((t) => t.measureTime.isSmallerThanValue(toMs));
      if (wearId != null) r.where((t) => t.wearId.equals(wearId));
      await r.go();
      final f = db.delete(db.bleFrameBuffer);
      if (fromMs != null) {
        f.where((t) => t.measureTime.isBiggerOrEqualValue(fromMs));
      }
      if (toMs != null) f.where((t) => t.measureTime.isSmallerThanValue(toMs));
      if (wearId != null) f.where((t) => t.wearId.equals(wearId));
      await f.go();
    });
    log('deleteData from=$from to=$to wearId=$wearId → $deleted strip');
    return deleted;
  }

  Future<int> count({int? wearId}) async {
    final g = db.userlocalGlucoseData;
    final c = g.id.count();
    final q = db.selectOnly(g)..addColumns([c]);
    if (wearId != null) q.where(g.wearId.equals(wearId));
    return (await q.getSingle()).read(c) ?? 0;
  }

  // ── event derivation ──

  /// Wear snapshot cache: Dozens of frames per second when backing up, and the library cannot be checked three times per frame；30 Refresh once every second and change wear hour [resetWearState] clear。
  _WearSnap? _snapCache;
  DateTime? _snapAt;

  Future<_WearSnap?> _snapshot() async {
    final at = _snapAt;
    if (at != null &&
        DateTime.now().difference(at) < const Duration(seconds: 30)) {
      return _snapCache;
    }
    _snapCache = await wearRepo.currentWearSnapshot();
    _snapAt = DateTime.now();
    return _snapCache;
  }

  /// Every time one is calculated: push glucose / algoResult，Update equipment site and run exception rules。
  Future<void> _onFrame(BleFrameBufferRow frame, GlucoseValue out) async {
    try {
      final snap = await _snapshot();
      final wearId = frame.wearId ?? snap?.wearId ?? 0;
      if (stateWearId != wearId) {
        resetWearState();
        stateWearId = wearId;
      }
      final activeTime = snap?.activeTime;
      final warmup =
          activeTime != null &&
          frame.measureTime.isBefore(activeTime.add(SdkTuning.warmupDuration));
      debugPrint(
        '[CGM WARMUP] wear=$wearId seq=${frame.recordSeq} '
        'activeTime=$activeTime measurementTime=${frame.measureTime} '
        'duration=${SdkTuning.warmupDuration.inMinutes}m warmup=$warmup',
      );
      final valueOk = out.value.isFinite;
      final now = DateTime.now();
      // Device current≈0 hour pipeline Changed to the pocket current feeding algorithm (development version), and the value fed in is out.current；
      // events and query Same caliber: standard replay、rawCurrent The current that actually feeds the algorithm
      final realCurrent = frame.rawCurrent;
      final substituted =
          realCurrent != null &&
          realCurrent <= GlucosePipelineRepository.zeroCurrentEps &&
          out.current > GlucosePipelineRepository.zeroCurrentEps;
      final source = substituted
          ? 'replay'
          : (BackfillStatus.etaMinutes.value != null ||
                    now.difference(frame.measureTime) > _backfillLag
                ? 'backfill'
                : 'live');
      final sample = GlucoseSample(
        wearId: wearId,
        seq: frame.recordSeq ?? 0,
        measuredAt: frame.measureTime.toLocal(),
        value: valueOk ? out.value : null,
        warmup: warmup,
        abnormal: !valueOk,
        source: source,
        rawCurrent: substituted ? out.current : realCurrent,
        temperature: frame.temperature,
        voltage: _mv(frame.voltage),
      );
      glucoseCtrl.add(sample);
      algoCtrl.add(
        AlgoResult(
          seq: sample.seq,
          value: out.value,
          current: out.current,
          currentIirFilter: out.currentIirFilter,
          currentMedianFilter: out.currentMedianFilter,
          currentBase: out.currentBase,
          sensitivityUsed: out.sensitivityUsed,
          dayKalmanQ: out.dayKalmanParamQ,
          dayKalmanR: out.dayKalmanParamR,
          nightKalmanQ: out.nightKalmanParamQ,
          nightKalmanR: out.nightKalmanParamR,
          currentRemoveSqueeze1: out.currentRemoveSqueeze1,
          currentRemoveSqueeze2: out.currentRemoveSqueeze2,
          glucosePre: out.glucosePre,
        ),
      );
      if (!valueOk) {
        _emitError(
          CgmErrorCode.algoCalcFailed,
          'seq=${sample.seq} The calculation result is invalid',
        );
      }
      if (frame.voltage != null) {
        lastBatteryMv = (frame.voltage! * 1000).round();
      }
      if (frame.temperature != null) lastTemp = frame.temperature;
      lastSeq = sample.seq;
      _runSignalRules(sample, warmup);
      _clearActive(CgmErrorCode.dataInterrupted);
      if (source == 'live') _emitDeviceStatus(snap);
      refreshConnection();
    } catch (e) {
      log('onFrame Event derivation failed(neglect): $e');
    }
  }

  void _runSignalRules(GlucoseSample s, bool warmup) {
    final sig = SignalSample(
      seq: s.seq,
      current: s.rawCurrent,
      glucose: s.value,
    );
    if (warmup) {
      warmupSamples.add(sig);
      final wm = SdkTuning.warmupMinutes;
      if (detectE01(warmupSamples, wm)) {
        _emitOnce(
          CgmErrorCode.currentLow,
          'The current continues to be too low during the preheating period（E01）',
        );
        currentAbnormal = 'dataAbnormal';
      } else if (detectE02(warmupSamples, wm)) {
        _emitOnce(
          CgmErrorCode.signalNoisy,
          'The current continues to be too high during the preheating period（E02）',
        );
        currentAbnormal = 'dataAbnormal';
      }
      return;
    }
    recentSamples.add(sig);
    if (recentSamples.length > kE03Window) recentSamples.removeAt(0);
    if (detectE03(recentSamples)) {
      if (_emitOnset(
        CgmErrorCode.currentLow,
        'Abnormal monitoring data: current is too low（E03）',
      )) {
        currentAbnormal = 'dataAbnormal';
      }
    } else {
      if (active.remove(CgmErrorCode.currentLow) &&
          currentAbnormal == 'dataAbnormal') {
        currentAbnormal = null;
      }
    }
    final mv = lastBatteryMv;
    if (mv != null && mv > 0 && mv < 2300) {
      if (_emitOnset(
        CgmErrorCode.batteryLow,
        'Equipment voltage ${mv}mV lower than 2.3V，Please replace it as soon as possible',
      )) {
        currentAbnormal ??= 'lowBattery';
      }
    } else if (active.remove(CgmErrorCode.batteryLow) &&
        currentAbnormal == 'lowBattery') {
      currentAbnormal = null;
    }
  }

  void _emitError(CgmErrorCode code, [String? message]) {
    errorCtrl.add(
      SdkErrorEvent(
        code: code.code,
        severity: code.severity,
        message: message ?? code.defaultMessage,
      ),
    );
  }

  /// Every wear Only report once。
  void _emitOnce(CgmErrorCode code, String message) {
    if (firedOnce.add(code)) _emitError(code, message);
  }

  /// Starting and stopping：onset Report once，[_clearActive] You can apply again later. Returns whether the news is new。
  bool _emitOnset(CgmErrorCode code, String message) {
    if (!active.add(code)) return false;
    _emitError(code, message);
    return true;
  }

  void _clearActive(CgmErrorCode code) => active.remove(code);

  Future<void> _emitDeviceStatus([_WearSnap? snapIn]) async {
    final snap = snapIn ?? await _snapshot();
    final now = DateTime.now();
    var warmupLeft = 0;
    var daysLeft = 0;
    if (snap != null) {
      final at = snap.activeTime;
      final wl = at.add(SdkTuning.warmupDuration).difference(now).inMinutes;
      warmupLeft = wl < 0 ? 0 : wl;
      final dl = at
          .add(const Duration(days: kWearLifetimeDays))
          .difference(now)
          .inDays;
      daysLeft = dl < 0 ? 0 : dl;
    }
    final hint = ConnectStatus.hint.value ?? '';
    final flashFull = hint.contains('Storage is full');
    final stopped = hint.contains('Measurement stopped');
    final connected = runner.isDeviceLinked;
    String? abnormal = currentAbnormal;
    if (stopped) abnormal = 'deviceFault';
    if (active.contains(CgmErrorCode.dataInterrupted)) {
      abnormal ??= 'dataInterrupted';
    }
    devStatus.add(
      DeviceStatus(
        connected: connected,
        batteryMv: lastBatteryMv,
        temperature: lastTemp,
        latestSeq: lastSeq,
        measuring: connected && !stopped && !flashFull,
        flashFull: flashFull,
        warmupRemainingMin: warmupLeft,
        remainingDays: daysLeft,
        abnormal: abnormal,
      ),
    );
  }

  CgmConnectionState _deriveConnection() {
    if (scanning) return CgmConnectionState.scanning;
    if (connecting) return CgmConnectionState.connecting;
    if (runner.isDeviceLinked) return CgmConnectionState.connected;
    final h = ConnectStatus.hint.value;
    if (h == 'Transmitter disconnected,Reconnecting' ||
        h ==
            'Transmitter not connected,Retrying·Please log out of the old phone before changing the phone.App') {
      return CgmConnectionState.reconnecting;
    }
    return CgmConnectionState.disconnected;
  }

  void refreshConnection() {
    final s = _deriveConnection();
    if (s == lastConn) return;
    lastConn = s;
    connState.add(s);
  }

  void _onHint() {
    final h = ConnectStatus.hint.value;
    refreshConnection();
    if (h == null || h == lastHint) {
      lastHint = h;
      return;
    }
    lastHint = h;
    if (h == 'Bluetooth is not turned on,Please turn on Bluetooth') {
      _emitError(CgmErrorCode.bleOff, h);
    } else if (h.contains('Calibration not ready')) {
      _emitError(CgmErrorCode.noCalibration, h);
    } else if (h.contains('Measurement stopped') &&
        !h.contains('Storage is full')) {
      _emitError(CgmErrorCode.deviceFault, h);
    } else if (h.contains('Storage is full')) {
      _emitError(CgmErrorCode.flashFull, h);
    } else if (h.startsWith('Transmitter not connected')) {
      _emitError(CgmErrorCode.connectFailed, '$h（SDK Automatically retrying）');
    } else if (h.startsWith('Device information is not ready')) {
      _emitError(CgmErrorCode.notBound, h);
    }
    unawaited(_emitDeviceStatus());
  }

  void _onProgress() {
    final p = BackfillStatus.progress.value;
    if (p == null) return;
    progressCtrl.add(ProgressEvent(kind: p.kind, done: p.done, total: p.total));
  }

  void _onDevLog() {
    final entries = DevLog.instance.entries;
    if (entries.isEmpty) return;
    final e = entries.last;
    if (identical(e, lastLogSeen)) return;
    lastLogSeen = e;
    final level = _classify(e.message);
    if (level.rank > logLevel.rank) return;
    logCtrl.add(
      SdkLogEvent(at: e.time, level: level, tag: e.tag, message: e.message),
    );
  }

  static LogLevel _classify(String m) {
    if (m.contains('collapse') ||
        m.contains('FATAL') ||
        m.contains('Not decryptable')) {
      return LogLevel.error;
    }
    if (m.contains('fail') ||
        m.contains('time out') ||
        m.contains('mistake') ||
        m.contains('abnormal') ||
        m.contains('throw away') ||
        m.contains('⚠') ||
        m.contains('reject')) {
      return LogLevel.warn;
    }
    return LogLevel.info;
  }

  /// 5 Seconds: brush connection status; every minute: warm-up progress / maturity / data interruption / deviceStatus。
  Future<void> _onTick() async {
    refreshConnection();
    if (++tickCount % 12 != 0) return;
    try {
      final snap = await wearRepo.currentWearSnapshot();
      if (snap == null || snap.handleStatus == '$kWearStatusUnbound') return;
      final now = DateTime.now();
      final at = snap.activeTime;
      final wm = SdkTuning.warmupMinutes;
      final warmLeft = at
          .add(SdkTuning.warmupDuration)
          .difference(now)
          .inMinutes;
      if (warmLeft > 0) {
        progressCtrl.add(
          ProgressEvent(kind: 'warmup', done: wm - warmLeft, total: wm),
        );
      }
      final expireAt = at.add(const Duration(days: kWearLifetimeDays));
      if (!now.isBefore(expireAt)) {
        _emitOnce(
          CgmErrorCode.deviceExpiredAuto,
          'Wear has expired (activated + $kWearLifetimeDays days), collection has stopped',
        );
      } else if (expireAt.difference(now) < const Duration(days: 3)) {
        _emitOnce(
          CgmErrorCode.deviceNearExpiry,
          'The remaining validity period of the device is insufficient. 3 God, please prepare to replace',
        );
      }
      final last = LinkActivity.lastComputedAt;
      if (runner.isDeviceLinked &&
          warmLeft <= 0 &&
          last != null &&
          now.difference(last) > const Duration(minutes: 5)) {
        _emitOnset(
          CgmErrorCode.dataInterrupted,
          'Connected but 5 No new data for minutes',
        );
      }
      await _emitDeviceStatus(snap);
    } catch (e) {
      log('tick fail(neglect): $e');
    }
  }
}

/// Host beforeActivate callback → internal [BindHooks]。
class _HostBindHooks extends BindHooks {
  const _HostBindHooks(this._before);

  final BeforeActivate? _before;

  @override
  Future<BeforeActivateResult> beforeActivate(BindCheck check) =>
      _before?.call(check) ??
      Future.value(const BeforeActivateResult.proceed());
}

/// Apply the notification copy configured by the host to the front-end service（Android）。
class _NoticeForegroundService implements ForegroundServiceController {
  const _NoticeForegroundService(this._inner, this._title);

  final ForegroundServiceController _inner;
  final String _title;

  @override
  Future<void> ensureRunning({String title = '', String text = ''}) =>
      _inner.ensureRunning(
        title: _title,
        text: text.isEmpty
            ? 'Continuously receiving blood glucose data in the background'
            : text,
      );

  @override
  Future<void> stop() => _inner.stop();
}

/// [WearRepository.currentWearSnapshot] return type。
typedef _WearSnap = ({
  int wearId,
  DateTime activeTime,
  String? handleStatus,
  int userId,
  int? accountId,
});
