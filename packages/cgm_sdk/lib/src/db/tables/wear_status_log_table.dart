import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `user_wear_status_log` — Equipment wearing information status change table (Lianxin table）。
@DataClassName('UserWearStatusLogRow')
class UserWearStatusLog extends Table {
  @override
  String get tableName => 'user_wear_status_log';

  IntColumn get id => integer().named('id')();

  IntColumn get userId => integer().named('user_id')();

  IntColumn get accountId => integer().named('account_id')();

  IntColumn get wearId => integer().named('wear_id')();

  /// 1=Binding successful，2=End of warm-up，3=unbundle
  TextColumn get handleStatus => text().named('handle_status').nullable()();

  IntColumn get handleTime => integer()
      .named('handle_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  TextColumn get unbindReson => text().named('unbind_reson').nullable()();

  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  /// 1=yes，0=no
  TextColumn get uploadFlag => text().named('upload_flag').nullable()();

  /// 1=success，0=fail
  TextColumn get uploadResult => text().named('upload_result').nullable()();

  TextColumn get uploadFailReson =>
      text().named('upload_fail_reson').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
