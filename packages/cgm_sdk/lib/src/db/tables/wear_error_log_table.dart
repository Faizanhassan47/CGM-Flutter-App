import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `userlocal_wear_error_log` — User local-Equipment abnormality record (Lianxin table）。
@DataClassName('UserlocalWearErrorLogRow')
class UserlocalWearErrorLog extends Table {
  @override
  String get tableName => 'userlocal_wear_error_log';

  IntColumn get id => integer().named('id')();

  IntColumn get userId => integer().named('user_id').nullable()();

  IntColumn get accountId => integer().named('account_id').nullable()();

  /// Lianxin’s annotation is suspected to be misplaced (original text"transmitter id"）
  IntColumn get wearId => integer().named('wear_id').nullable()();

  TextColumn get errorContent => text().named('error_content').nullable()();

  IntColumn get errorTime => integer()
      .named('error_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  IntColumn get userPhoneId => integer().named('user_phone_id').nullable()();

  TextColumn get uploadFlag => text().named('upload_flag').nullable()();

  /// 1=success，0=fail
  TextColumn get uploadResult => text().named('upload_result').nullable()();

  TextColumn get uploadFailReson =>
      text().named('upload_fail_reson').nullable()();

  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  /// Lianxin PK name device_error_log_pkey，The primary key is id。
  @override
  Set<Column> get primaryKey => {id};
}
