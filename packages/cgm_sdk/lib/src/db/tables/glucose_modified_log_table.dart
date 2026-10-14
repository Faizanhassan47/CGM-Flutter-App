import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `userlocal_glucose_modified_log` — User local-blood glucose data-Modified record (Lianxin table）。
///
/// Blood glucose level contingency core completed decimal(65,30)，TEXT Fixed-point storage without losing accuracy；create_time Lianxin built
/// date No datetime，Still pressing epoch millisecond caliber accepted。measure_time of DESC The index is provided by Lianxin。
@DataClassName('UserlocalGlucoseModifiedLogRow')
class UserlocalGlucoseModifiedLog extends Table {
  @override
  String get tableName => 'userlocal_glucose_modified_log';

  IntColumn get id => integer().named('id')();

  IntColumn get userId => integer().named('user_id')();

  /// Lianxin’s annotation is suspected to be misplaced (original text"app wear Id"）
  IntColumn get accountId => integer().named('account_id').nullable()();

  IntColumn get wearId => integer().named('wear_id').nullable()();

  IntColumn get recordSeq => integer().named('record_seq').nullable()();

  /// Lianxin decimal(65,30)，TEXT Fixed deposit
  TextColumn get glucoseValue1 => text()
      .named('glucose_value1')
      .map(const MedicalDecimalConverter())
      .nullable()();

  /// Lianxin decimal(65,30)，TEXT Fixed deposit
  TextColumn get glucoseValue2 => text()
      .named('glucose_value2')
      .map(const MedicalDecimalConverter())
      .nullable()();

  IntColumn get measureTime =>
      integer().named('measure_time').map(const DateTimeEpochConverter())();

  TextColumn get fiveMinFlag => text().named('five_min_flag').nullable()();

  /// Lianxin decimal(65,30)，TEXT Fixed deposit
  TextColumn get fiveMinGlucose => text()
      .named('five_min_glucose')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get warmupFlag => text().named('warmup_flag').nullable()();

  TextColumn get abnormalFlag => text().named('abnormal_flag').nullable()();

  TextColumn get uploadFlag => text().named('upload_flag').nullable()();

  /// 1=success，0=fail
  TextColumn get uploadResult => text().named('upload_result').nullable()();

  TextColumn get uploadFailReson =>
      text().named('upload_fail_reson').nullable()();

  /// Lianxin built date No datetime
  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
