import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/cgm_database.dart';

/// user_wear_status_log.handle_status value。
class WearHandleStatus {
  WearHandleStatus._();

  /// Binding successful
  static const String bound = '1';

  /// End of warm-up
  static const String preheatEnded = '2';

  /// unbundle
  static const String unbound = '3';
}

/// app_device_bind.device_status，Based on activation time。
class WearDeviceStatus {
  WearDeviceStatus._();

  /// After activation 0~2h
  static const String warming = 'warming';

  /// overtake 2h
  static const String done = 'done';
}

/// Device binding / Activated local persistence, one activation writes three tables：`user_wear_cur`、
/// `app_device_bind`、`user_wear_status_log`；wearId Get the local maximum value +1。
/// app_device_bind Time column storage UTC epoch millisecond。
class WearRepository {
  WearRepository(this._db);

  final CgmDatabase _db;

  /// After the activation is successful, the library will be bound once and the locally generated one will be returned. wearId。
  Future<int> saveActivation({
    required int userId,
    int? accountId,
    required int transmitterId,
    required String transmitterSn,
    required int sensorId,
    required String sensorSn,
    String? bluetoothAddr,
    required String deviceForm,
    String? instanceForm,
    String? expireDate,
    String? firmwareVersion,
    DateTime? activeTime,
    int? wearId,
  }) async {
    final now = activeTime ?? DateTime.now();
    final resolvedWearId = wearId ?? await _nextWearId();

    await _db
        .into(_db.userWearCur)
        .insertOnConflictUpdate(
          UserWearCurCompanion.insert(
            userId: Value(userId),
            accountId: Value(accountId),
            wearId: Value(resolvedWearId),
            activeTime: Value(now),
            transmitterId: Value(transmitterId),
            transmitterSn: Value(transmitterSn),
            sensorId: Value(sensorId),
            sensorSn: Value(sensorSn),
            lastWearTime: Value(now),
            createTime: Value(now),
            updateTime: Value(now),
          ),
        );

    final nowMs = now.toUtc().millisecondsSinceEpoch;
    await _db
        .into(_db.appDeviceBind)
        .insert(
          AppDeviceBindCompanion.insert(
            userId: userId,
            wearId: Value(resolvedWearId),
            transmitterSn: Value(transmitterSn),
            sensorSn: Value(sensorSn),
            bluetoothAddr: Value(bluetoothAddr),
            deviceType: Value(deviceForm),
            instanceForm: Value(instanceForm),
            expireDate: Value(expireDate),
            firmwareVersion: Value(firmwareVersion),
            // Longitude and latitude, prefecture, city and county, soft and solid parameters updateBindExtras Follow-up writing。
            uploadStatus: const Value('0'),
            deviceStatus: const Value(WearDeviceStatus.warming),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await _appendStatus(
      userId: userId,
      accountId: accountId ?? 0,
      wearId: resolvedWearId,
      status: WearHandleStatus.bound,
      at: now,
    );

    return resolvedWearId;
  }

  /// Preheating ends: the device status changes to done And add a status change event。
  Future<void> recordPreheatEnded({
    required int userId,
    int? accountId,
    required int wearId,
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();
    await (_db.update(
      _db.appDeviceBind,
    )..where((t) => t.wearId.equals(wearId))).write(
      AppDeviceBindCompanion(
        deviceStatus: const Value(WearDeviceStatus.done),
        updatedAt: Value(when.toUtc().millisecondsSinceEpoch),
      ),
    );
    await _appendStatus(
      userId: userId,
      accountId: accountId ?? 0,
      wearId: wearId,
      status: WearHandleStatus.preheatEnded,
      at: when,
    );
  }

  /// Supplement the binding extension fields, update only the non-empty input parameters, and leave the default items unchanged.。
  Future<void> updateBindExtras({
    required int wearId,
    double? latitude,
    double? longitude,
    String? cityCode,
    String? districtCode,
    String? softParams,
    String? firmwareParams,
    DateTime? at,
  }) async {
    await (_db.update(
      _db.appDeviceBind,
    )..where((t) => t.wearId.equals(wearId))).write(
      AppDeviceBindCompanion(
        bindLatitude: latitude == null ? const Value.absent() : Value(latitude),
        bindLongitude: longitude == null
            ? const Value.absent()
            : Value(longitude),
        cityCode: cityCode == null ? const Value.absent() : Value(cityCode),
        districtCode: districtCode == null
            ? const Value.absent()
            : Value(districtCode),
        softParams: softParams == null
            ? const Value.absent()
            : Value(softParams),
        firmwareParams: firmwareParams == null
            ? const Value.absent()
            : Value(firmwareParams),
        updatedAt: Value((at ?? DateTime.now()).toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> recordUnbind({
    required int userId,
    int? accountId,
    required int wearId,
    String? reason,
    DateTime? at,
  }) {
    return _appendStatus(
      userId: userId,
      accountId: accountId ?? 0,
      wearId: wearId,
      status: WearHandleStatus.unbound,
      reason: reason,
      at: at ?? DateTime.now(),
    );
  }

  /// according to active_time Get the latest activated row in reverse order，user_wear_cur Old rows will remain。
  Future<UserWearCurRow?> currentWear() {
    return (_db.select(_db.userWearCur)
          ..orderBy([(t) => OrderingTerm.desc(t.activeTime)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<AppDeviceBindRow?> currentDeviceBind() {
    return (_db.select(_db.appDeviceBind)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<UserWearStatusLogRow>> statusHistory(int wearId) {
    return (_db.select(_db.userWearStatusLog)
          ..where((t) => t.wearId.equals(wearId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// wearId The mapping to the activation moment is taken as `user_wear_cur.active_time`。
  /// The ____ does not work app_device_bind.created_at：That was the time when the library was written locally, and it was later than the actual activation after the machine was replaced and restored.，
  /// Monitoring days will be undercounted。
  Future<Map<int, DateTime>> wearActiveTimes() async {
    final rows = await _db.select(_db.userWearCur).get();
    final map = <int, DateTime>{};
    for (final r in rows) {
      final id = r.wearId;
      final at = r.activeTime;
      if (id == null || at == null) continue;
      // same wearId If there are multiple lines remaining, the earliest activation will be used.。
      final cur = map[id];
      if (cur == null || at.isBefore(cur)) map[id] = at;
    }
    return map;
  }

  /// Wear all binding records, new ones first。
  Future<List<AppDeviceBindRow>> allBindings() {
    return (_db.select(
      _db.appDeviceBind,
    )..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
  }

  /// The only input for life cycle determination, homepage, collection runner、Preheat notification gate sharing。
  ///
  /// wear with `app_device_bind` The last line shall prevail and the activation time will be lost if the activation time is missing. `created_at`，With ”My Devices”」
  /// List the same caliber；`user_wear_cur` The primary key is userId、Each activation overwrites the same line, reading it individually would be the same as
  /// Device list judgment is inconsistent。
  Future<
    ({
      int wearId,
      DateTime activeTime,
      String? handleStatus,
      int userId,
      int? accountId,
    })?
  >
  currentWearSnapshot() async {
    final bind = await currentDeviceBind();
    final cur = await currentWear();
    final fromBind = bind?.wearId != null;
    final wearId = bind?.wearId ?? cur?.wearId;
    if (wearId == null) return null;
    final activeTime =
        (await wearActiveTimes())[wearId] ??
        (bind == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                bind.createdAt,
                isUtc: true,
              ).toLocal());
    if (activeTime == null) return null;
    // The account can only be retrieved from wearId same row；user_wear_cur It’s not pointing to the time when I wore it this time. accountId Leave blank，
    // The caller gets the details from the account list。
    return (
      wearId: wearId,
      activeTime: activeTime,
      handleStatus: await latestHandleStatus(wearId),
      userId: (fromBind ? bind!.userId : cur?.userId) ?? 0,
      accountId: cur?.wearId == wearId ? cur?.accountId : null,
    );
  }

  Future<String?> latestHandleStatus(int wearId) async {
    final row =
        await (_db.select(_db.userWearStatusLog)
              ..where((t) => t.wearId.equals(wearId))
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    return row?.handleStatus;
  }

  Future<String?> latestUnbindReason(int wearId) async {
    final row =
        await (_db.select(_db.userWearStatusLog)
              ..where(
                (t) => t.wearId.equals(wearId) & t.handleStatus.equals('3'),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    return row?.unbindReson;
  }

  Future<void> _appendStatus({
    required int userId,
    required int accountId,
    required int wearId,
    required String status,
    String? reason,
    required DateTime at,
  }) async {
    // id yes sqlite rowid Alias, auto-increment and allocation, no need to fill in manually。
    await _db
        .into(_db.userWearStatusLog)
        .insert(
          UserWearStatusLogCompanion.insert(
            userId: userId,
            accountId: accountId,
            wearId: wearId,
            handleStatus: Value(status),
            handleTime: Value(at),
            unbindReson: Value(reason),
            createTime: Value(at),
            uploadFlag: const Value('0'),
          ),
        );
  }

  Future<int> _nextWearId() async {
    final rows = await _db.select(_db.userWearCur).get();
    var max = 0;
    for (final r in rows) {
      final w = r.wearId ?? 0;
      if (w > max) max = w;
    }
    return max + 1;
  }
}
