import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart' show AlgoTuning;
import 'package:cgm_sdk/src/db/cgm_database.dart';

/// Calibration change broadcast: write locally +1，After monitoring on the acquisition side, press the calibration fingerprint to determine whether to hot restart。
final ValueNotifier<int> calibrationTick = ValueNotifier<int>(0);

/// Local cache of algorithm calibration parameters, drop `app_meta` KV：Factory calibration k/b/l3~g5 From scan code
/// sensorAttr，Finger blood reference cgmbase From user information interface（= algorithm paramBGMbase）；
/// Optional tuning parameters (algorithm library setXxx）from SDK facade setAlgoParams。
/// Read out when the algorithm starts init；Only logs are recorded for read and write failures, and the fallback default cannot be obtained.。
class AlgoParamStore {
  AlgoParamStore(this._db);

  final CgmDatabase _db;

  static const _kK = 'algo_sensor_k';
  static const _kB = 'algo_sensor_b';
  static const _kL3 = 'algo_sensor_l3';
  static const _kG3 = 'algo_sensor_g3';
  static const _kL4 = 'algo_sensor_l4';
  static const _kG4 = 'algo_sensor_g4';
  static const _kL5 = 'algo_sensor_l5';
  static const _kG5 = 'algo_sensor_g5';
  static const _kCgmBase = 'algo_cgm_base';
  static const _kBtAddr = 'device_bt_addr';

  // Algorithm library optional parameters, one click per item；positiveSlope2Fixed live 1/0
  static const _kPosSlope1 = 'algo_tune_positive_slope1';
  static const _kNegSlope1 = 'algo_tune_negative_slope1';
  static const _kPosSlope2 = 'algo_tune_positive_slope2';
  static const _kPosSlope2Fixed = 'algo_tune_positive_slope2_fixed';
  static const _kNegSlope2 = 'algo_tune_negative_slope2';
  static const _kDayQ = 'algo_tune_day_kalman_q';
  static const _kDayR = 'algo_tune_day_kalman_r';
  static const _kNightQ = 'algo_tune_night_kalman_q';
  static const _kNightR = 'algo_tune_night_kalman_r';
  static const _tuningKeys = [
    _kPosSlope1,
    _kNegSlope1,
    _kPosSlope2,
    _kPosSlope2Fixed,
    _kNegSlope2,
    _kDayQ,
    _kDayR,
    _kNightQ,
    _kNightR,
  ];

  /// equipment BLE peripheral handle（`remoteId`）：iOS yes CoreBluetooth of peripheral UUID
  /// （Can’t get it MAC），Android that is MAC。It is saved to connect directly without scanning，iOS Background scanning is required
  /// service UUID，Can only rely on handle。
  static const _kPeripheralId = 'device_ble_peripheral_id';

  /// Save the factory calibration of this sensor (scan the QR code sensorAttr）。Any one is null Do not write this item。
  Future<void> saveSensorCalibration({
    double? k,
    double? b,
    double? l3,
    double? g3,
    double? l4,
    double? g4,
    double? l5,
    double? g5,
  }) async {
    final pairs = <String, double?>{
      _kK: k,
      _kB: b,
      _kL3: l3,
      _kG3: g3,
      _kL4: l4,
      _kG4: g4,
      _kL5: l5,
      _kG5: g5,
    };
    await _putAll(pairs);
    calibrationTick.value++;
  }

  /// Deposit index blood benchmark (user information cgmbase = algorithm paramBGMbase）。null Not written by default；
  /// [clearIfNull] hour null Indicates clearing the stored value（SDK Complete set of facade coverage semantics）。
  Future<void> saveCgmBase(double? cgmBase, {bool clearIfNull = false}) async {
    if (cgmBase == null) {
      if (!clearIfNull) return;
      await _deleteKeys([_kCgmBase]);
    } else {
      await _putAll({_kCgmBase: cgmBase});
    }
    calibrationTick.value++;
  }

  /// The entire set of coverage algorithm library optional tuning parameters: write if passed, write if not passed(null)Cleared → Algorithm library returns to built-in default。
  Future<void> saveAlgoTuning(AlgoTuning t) async {
    final pairs = <String, double?>{
      _kPosSlope1: t.positiveSlope1,
      _kNegSlope1: t.negativeSlope1,
      _kPosSlope2: t.positiveSlope2,
      _kPosSlope2Fixed: t.positiveSlope2 == null
          ? null
          : (t.positiveSlope2Fixed ? 1 : 0),
      _kNegSlope2: t.negativeSlope2,
      _kDayQ: t.dayKalmanQ,
      _kDayR: t.dayKalmanR,
      _kNightQ: t.nightKalmanQ,
      _kNightR: t.nightKalmanR,
    };
    await _deleteKeys([
      for (final e in pairs.entries)
        if (e.value == null) e.key,
    ]);
    await _putAll(pairs);
    calibrationTick.value++;
  }

  /// Read the optional parameters. The unsaved items are null。
  Future<AlgoTuning> readAlgoTuning() async {
    final m = await _readAll();
    return AlgoTuning(
      positiveSlope1: m[_kPosSlope1],
      negativeSlope1: m[_kNegSlope1],
      positiveSlope2: m[_kPosSlope2],
      positiveSlope2Fixed: m[_kPosSlope2Fixed] == 1,
      negativeSlope2: m[_kNegSlope2],
      dayKalmanQ: m[_kDayQ],
      dayKalmanR: m[_kDayR],
      nightKalmanQ: m[_kNightQ],
      nightKalmanR: m[_kNightR],
    );
  }

  /// Read factory calibration, any key item（k/b）If missing, it will be returned as no calibration. null。
  Future<SensorCalibration?> readSensorCalibration() async {
    final m = await _readAll();
    final k = m[_kK];
    final b = m[_kB];
    if (k == null || b == null) return null;
    return SensorCalibration(
      k: k,
      b: b,
      l3: m[_kL3] ?? 0,
      g3: m[_kG3] ?? 0,
      l4: m[_kL4] ?? 0,
      g4: m[_kG4] ?? 0,
      l5: m[_kL5] ?? 0,
      g5: m[_kG5] ?? 0,
    );
  }

  /// Reading refers to the blood standard, otherwise null。
  Future<double?> readCgmBase() async => (await _readAll())[_kCgmBase];

  /// Save the Bluetooth address of the device (obtained during binding and used to automatically connect to the device). Leave nothing to write。
  Future<void> saveBluetoothAddr(String? addr) async {
    if (addr == null || addr.trim().isEmpty) return;
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    try {
      await _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.appMeta, [
          AppMetaCompanion.insert(
            key: _kBtAddr,
            value: Value(addr.trim()),
            updatedAt: ts,
          ),
        ]),
      );
    } catch (e, st) {
      developer.log(
        'The device Bluetooth address failed to be logged into the library (ignored）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// storage device peripheral Handle (used for automatic connection of devices). Leave nothing to write。
  Future<void> savePeripheralId(String remoteId) async {
    if (remoteId.trim().isEmpty) return;
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    try {
      await _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.appMeta, [
          AppMetaCompanion.insert(
            key: _kPeripheralId,
            value: Value(remoteId.trim()),
            updatedAt: ts,
          ),
        ]),
      );
    } catch (e, st) {
      developer.log(
        'peripheral Failed to drop the handle into the library (ignored）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<String?> readPeripheralId() async {
    try {
      final row = await (_db.select(
        _db.appMeta,
      )..where((t) => t.key.equals(_kPeripheralId))).getSingleOrNull();
      final v = row?.value?.trim();
      return (v == null || v.isEmpty) ? null : v;
    } catch (e, st) {
      developer.log(
        'peripheral Handle read failed (ignored）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Clear the device Bluetooth address stored in this machine and cancel the connection. CGM Association of: collection runner Read before connecting
  /// [readBluetoothAddr]，If it cannot be read, it will not be connected; it will be 423 Clear it when you go offline, so that the old machine will not remove the transmitter
  /// Grab it back. This device does not require system pairing, no bond solvable。
  Future<void> clearBluetoothAddr() async {
    try {
      await (_db.delete(_db.appMeta)..where(
            (t) => t.key.equals(_kBtAddr) | t.key.equals(_kPeripheralId),
          ))
          .go();
    } catch (e, st) {
      developer.log(
        'Device Bluetooth address clearing failed (ignored）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Read the device Bluetooth address, otherwise null。
  Future<String?> readBluetoothAddr() async {
    try {
      final row = await (_db.select(
        _db.appMeta,
      )..where((t) => t.key.equals(_kBtAddr))).getSingleOrNull();
      final v = row?.value?.trim();
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  Future<void> _putAll(Map<String, double?> pairs) async {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rows = [
      for (final e in pairs.entries)
        if (e.value != null)
          AppMetaCompanion.insert(
            key: e.key,
            value: Value(e.value.toString()),
            updatedAt: ts,
          ),
    ];
    if (rows.isEmpty) return;
    try {
      await _db.batch((b) => b.insertAllOnConflictUpdate(_db.appMeta, rows));
    } catch (e, st) {
      developer.log(
        'Algorithm calibration failed (ignored)）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _deleteKeys(List<String> keys) async {
    if (keys.isEmpty) return;
    try {
      await (_db.delete(_db.appMeta)..where((t) => t.key.isIn(keys))).go();
    } catch (e, st) {
      developer.log(
        'Algorithm parameter clearing failed (ignored）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<Map<String, double>> _readAll() async {
    try {
      final keys = [
        _kK,
        _kB,
        _kL3,
        _kG3,
        _kL4,
        _kG4,
        _kL5,
        _kG5,
        _kCgmBase,
        ..._tuningKeys,
      ];
      final rows = await (_db.select(
        _db.appMeta,
      )..where((t) => t.key.isIn(keys))).get();
      final out = <String, double>{};
      for (final r in rows) {
        final v = double.tryParse(r.value ?? '');
        if (v != null) out[r.key] = v;
      }
      return out;
    } catch (e, st) {
      developer.log(
        'Algorithm calibration reading failed (fallback to default, ignore）',
        name: 'AlgoParamStore',
        error: e,
        stackTrace: st,
      );
      return const {};
    }
  }
}

/// Factory calibration of a sensor：k=Sensitivity(slope)、b=intercept(intercept)、l3~g5=Segmentation parameters。
class SensorCalibration {
  const SensorCalibration({
    required this.k,
    required this.b,
    required this.l3,
    required this.g3,
    required this.l4,
    required this.g4,
    required this.l5,
    required this.g5,
  });

  final double k;
  final double b;
  final double l3;
  final double g3;
  final double l4;
  final double g4;
  final double l5;
  final double g5;
}
