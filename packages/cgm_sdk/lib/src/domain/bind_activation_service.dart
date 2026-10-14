import 'dart:async';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/domain/sdk_tuning.dart';
import 'package:cgm_sdk/src/domain/activation_check.dart';
import 'package:cgm_sdk/src/domain/bind_hooks.dart';
import 'package:cgm_sdk/src/domain/cgm_ble_gate.dart';
import 'package:cgm_sdk/src/domain/device_scan_result.dart';
import 'package:cgm_sdk/src/glucose/algo_param_store.dart';
import 'package:cgm_sdk/src/wear/wear_repository.dart';

/// Activation result: pass band wearId + Preheating end time；3 The barrier refuses to take [reject]；
/// If Bluetooth cannot connect [connectionFailed]（Different from rejection state，UI bomb"Device connection failed"Reconnectable）。
class ActivationOutcome {
  const ActivationOutcome.activated({
    required int this.wearId,
    required DateTime this.preheatEndAt,
  }) : reject = null,
       connectionFailed = false,
       message = null;

  const ActivationOutcome.rejected(ActivationReject this.reject)
    : wearId = null,
      preheatEndAt = null,
      connectionFailed = false,
      message = null;

  const ActivationOutcome.connectionFailed()
    : wearId = null,
      preheatEndAt = null,
      reject = null,
      connectionFailed = true,
      message = null;

  /// rear end bind Interface failed（BLE Connected, verification passed, but the binding request was rejected）。message Directly to the user。
  const ActivationOutcome.bindFailed(String this.message)
    : wearId = null,
      preheatEndAt = null,
      reject = null,
      connectionFailed = false;

  final int? wearId;
  final DateTime? preheatEndAt;
  final ActivationReject? reject;

  /// Bluetooth connection failed (device not connected, not entered) 3 gate）。
  final bool connectionFailed;

  /// bind Interface failure prompt, if it is not empty, it will fail.。
  final String? message;

  bool get ok => reject == null && !connectionFailed && message == null;
}

/// 「CGM Verify activation” arrangement: connection → Read voltage/Use status → 3 gate → Dropped into the library → activation(0xD1)。
/// Binding is completed first and then activated; the rejected state is not activated or dropped into the library, and the reason is thrown to UI。
/// Backend binding / Positioning is not done here. [hooks] Give it to the host (the timing is the same as before)）。
class BindActivationService {
  BindActivationService({
    required this.ble,
    required this.wearRepo,
    this.hooks,
    this.algoParamStore,
  });

  final CgmBleGate ble;
  final WearRepository wearRepo;

  /// When binding, put the sensor sensorAttr Implemented locally for algorithm adoption；null then it does not exist。
  final AlgoParamStore? algoParamStore;

  /// Host hook: preparation before connection / Adjust backend binding after verification / Write after activation。
  /// null（desktop / (Part of the test) Skip cloud binding and only log in locally。
  final BindHooks? hooks;

  /// Binding confirmation voltage threshold（mV），The voltage source is BLE 0xE1。Default development file 500，The formal standard is 2800，
  /// Change it back before official packaging；SDK Facade by host config cover [SdkTuning.bindMinBatteryMv]。
  ///
  /// This is the only place in the entire project where people are stopped on a voltage basis; the operation period is less than 2.3V Only reports ”Battery is too low”」，
  /// collection/cover/Uploading does not stop due to voltage。
  static int get minBatteryMv => SdkTuning.bindMinBatteryMv;

  /// Preheating time. Derived from [SdkTuning.warmupMinutes]，Change the duration and only change that part。
  static Duration get preheatDuration => SdkTuning.warmupDuration;

  Future<ActivationOutcome> bindAndActivate({
    required DeviceForm form,
    required int transmitterId,
    required String transmitterSn,
    required int sensorId,
    required String sensorSn,
    required String bluetoothAddr,
    required int userId,
    int? accountId,
    String? expireDate,
    String? instanceForm,
    String? firmwareVersion,
    SensorAttr? sensorAttr,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();

    // The host’s time-consuming preparation (positioning) starts here, and BLE connect/3 Gate parallel
    hooks?.onBindStart(BindStart(bluetoothAddr: bluetoothAddr, at: at));

    DevLog.instance.add(
      'ble',
      '=== Start activation verification form=${form.name} addr=$bluetoothAddr ===',
    );
    if (!await ble.connect(bluetoothAddr)) {
      DevLog.instance.add('ble', 'Connection failed, no access 3 gate');
      return const ActivationOutcome.connectionFailed();
    }
    DevLog.instance.add(
      'ble',
      'Connection successful, start reading device status',
    );

    // If an error occurs after connecting, disconnect the release device, otherwise GATT Leak, device no longer broadcasts, cannot scan after reconnection
    try {
      DevLog.instance.add('ble', '① Read voltage(0xE1)…');
      final mv = await _readStableBatteryMv();
      DevLog.instance.add(
        'ble',
        '① Voltage=${mv}mV (threshold$minBatteryMv → foot=${mv >= minBatteryMv})',
      );

      DevLog.instance.add('ble', '② Read active sign/reset(0xE5)…');
      final inUse = await ble.readInUse();
      DevLog.instance.add(
        'ble',
        '② In use=$inUse（Log only, no longer deny connections based on this）',
      );

      final expired = _isExpired(expireDate, at);
      final verdict = checkActivation(
        voltageSufficient: mv >= minBatteryMv,
        expired: expired,
      );
      DevLog.instance.add(
        'ble',
        '③ Check gate: Sufficient voltage=${mv >= minBatteryMv} Overdue=$expired (In use=$inUse Don’t stop) '
            '→ ${verdict.canActivate ? "pass" : "reject(${verdict.reject})"}',
      );
      if (!verdict.canActivate) {
        await ble.disconnect();
        return ActivationOutcome.rejected(verdict.reject!);
      }

      // Only after verification can the backend bind，If it fails, it will not be dropped into the database and will not be activated.；wearId/The end time of preheating shall be subject to the backend
      int? remoteWearId;
      DateTime? remotePreheatEnd;
      final h = hooks;
      if (h != null) {
        DevLog.instance.add(
          'ble',
          '④ Hand over to host to execute binding preset(rear end bind)…',
        );
        final r = await h.beforeActivate(
          BindCheck(
            transmitterId: transmitterId,
            transmitterSn: transmitterSn,
            sensorId: sensorId,
            sensorSn: sensorSn,
            bluetoothAddr: bluetoothAddr,
            batteryMv: mv,
            inUse: inUse,
            at: at,
          ),
        );
        if (!r.ok) {
          DevLog.instance.add('ble', '④ Host aborts binding: ${r.message}');
          await ble.disconnect();
          return ActivationOutcome.bindFailed(r.message!);
        }
        remoteWearId = r.wearId;
        remotePreheatEnd = r.preheatEndAt;
        DevLog.instance.add('ble', '④ host release wearId=$remoteWearId');
      }

      final wearId = await wearRepo.saveActivation(
        userId: userId,
        accountId: accountId,
        wearId: remoteWearId,
        transmitterId: transmitterId,
        transmitterSn: transmitterSn,
        sensorId: sensorId,
        sensorSn: sensorSn,
        bluetoothAddr: bluetoothAddr,
        deviceForm: form.name,
        instanceForm: instanceForm,
        expireDate: expireDate,
        firmwareVersion: firmwareVersion,
        activeTime: at,
      );

      // Sensor factory calibration(k/b/l3~g5)Implemented locally and provided for algorithm setGluCalcParameter take
      final cal = sensorAttr;
      if (cal != null && cal.hasCalibration && algoParamStore != null) {
        await algoParamStore!.saveSensorCalibration(
          k: cal.k,
          b: cal.b,
          l3: cal.l3,
          g3: cal.g3,
          l4: cal.l4,
          g4: cal.g4,
          l5: cal.l5,
          g5: cal.g5,
        );
      }
      // Save the Bluetooth address for automatically connecting devices to get the real current
      await algoParamStore?.saveBluetoothAddr(bluetoothAddr);

      DevLog.instance.add(
        'ble',
        '⑤ Issue activation and start measurement(0xD1)…',
      );
      await ble.activate(at);
      DevLog.instance.add('ble', '⑤ Activation successful wearId=$wearId');

      // Host complement (latitude and longitude/Prefectures, cities and counties), do not block activation return; abnormally silent
      if (h != null) {
        unawaited(
          h.afterActivate(wearId).catchError((Object e) {
            DevLog.instance.add('ble', 'Host afterActivate fail(neglect): $e');
          }),
        );
      }

      return ActivationOutcome.activated(
        wearId: wearId,
        preheatEndAt: remotePreheatEnd ?? at.add(preheatDuration),
      );
    } catch (e) {
      DevLog.instance.add(
        'ble',
        'Activation process failed(After connecting): $e',
      );
      await ble.disconnect();
      return const ActivationOutcome.connectionFailed();
    }
  }

  /// Reading voltage debounce: The battery will sag instantly when it is connected to a load. A single cold reading will misjudge a device with sufficient power to be low voltage.。
  /// Read at most 3 Take the maximum value every time, and return early if the threshold is reached; only if all reads fail, will it be thrown to the upper layer.。
  Future<int> _readStableBatteryMv() async {
    var best = 0;
    Object? lastErr;
    for (var i = 1; i <= 3; i++) {
      try {
        final mv = await ble.readBatteryMv();
        if (mv > best) best = mv;
        DevLog.instance.add(
          'ble',
          'Battery reading $i: ${mv}mV (maximum=$best)',
        );
        if (best >= minBatteryMv) break;
      } catch (e) {
        lastErr = e;
        DevLog.instance.add('ble', 'Battery reading $i failed: $e');
      }
      if (i < 3) await Future.delayed(const Duration(milliseconds: 400));
    }
    if (best == 0 && lastErr != null) throw lastErr;
    return best;
  }

  /// Whether the factory expiration date has passed. Parsing failed / If it is empty, it will not be intercepted (processed as not expired)）。
  bool _isExpired(String? expireDate, DateTime now) {
    if (expireDate == null || expireDate.isEmpty) return false;
    final d = DateTime.tryParse(expireDate);
    if (d == null) return false;
    return now.isAfter(d);
  }
}
