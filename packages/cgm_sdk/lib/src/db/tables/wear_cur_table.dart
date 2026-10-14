import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `user_wear_cur` — The current situation of the user wearing the device (Lianxin Watch）。
@DataClassName('UserWearCurRow')
class UserWearCur extends Table {
  @override
  String get tableName => 'user_wear_cur';

  IntColumn get userId => integer().named('user_id')();

  /// Lianxin type incorrectly filled in `biging`（answer bigint），fall int64。
  IntColumn get accountId => integer().named('account_id').nullable()();

  IntColumn get wearId => integer().named('wear_id').nullable()();

  IntColumn get activeTime => integer()
      .named('active_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  IntColumn get transmitterId => integer().named('transmitter_id').nullable()();

  TextColumn get transmitterSn => text().named('transmitter_sn').nullable()();

  IntColumn get sensorId => integer().named('sensor_id').nullable()();

  TextColumn get sensorSn => text().named('sensor_sn').nullable()();

  IntColumn get lastWearTime => integer()
      .named('last_wear_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  IntColumn get lastDataUptime => integer()
      .named('last_data_uptime')
      .map(const DateTimeEpochConverter())
      .nullable()();

  /// Latest blood sugar value
  TextColumn get lastGlucose => text().named('last_glucose').nullable()();

  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  IntColumn get updateTime => integer()
      .named('update_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  /// Lianxin PK The name is missing and the primary key column is user_id。
  @override
  Set<Column> get primaryKey => {userId};
}
