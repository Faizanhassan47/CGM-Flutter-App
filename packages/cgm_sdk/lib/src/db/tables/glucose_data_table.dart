import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `userlocal_glucose_data` — User local-Blood glucose data (linked meter, core main link）。
///
/// measure_time Lianxinbiao"partition key"，SQLite No native partition, use index instead (built in app_database）。
/// five_min_glucose yes decimal(65,30)，Walk [MedicalDecimalConverter] live TEXT Guaranteed accuracy。
@DataClassName('UserlocalGlucoseDataRow')
class UserlocalGlucoseData extends Table {
  @override
  String get tableName => 'userlocal_glucose_data';

  IntColumn get id => integer().named('id')();

  IntColumn get userId => integer().named('user_id')();

  IntColumn get accountId => integer().named('account_id')();

  IntColumn get wearId => integer().named('wear_id')();

  IntColumn get measureTime =>
      integer().named('measure_time').map(const DateTimeEpochConverter())();

  IntColumn get recordSeq => integer().named('record_seq').nullable()();

  /// Lianxin double，fall real
  RealColumn get glucoseValue1 => real().named('glucose_value1').nullable()();

  RealColumn get glucoseValue2 => real().named('glucose_value2').nullable()();

  TextColumn get fiveMinFlag => text().named('five_min_flag').nullable()();

  /// Lianxin decimal(65,30)，TEXT Fixed-point storage, no loss of medical accuracy
  TextColumn get fiveMinGlucose => text()
      .named('five_min_glucose')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get warmupFlag => text().named('warmup_flag').nullable()();

  TextColumn get abnormalFlag => text().named('abnormal_flag').nullable()();

  TextColumn get modifiedFlag => text().named('modified_flag').nullable()();

  /// data validity char(1)：1=efficient(blood sugar 2.2~27.8) / 0=too low(<2.2) / 2=too high(>27.8)。
  /// 2.2~27.8 is the effective monitoring range of the machine (non-diabetic threshold), only the status='1'。
  TextColumn get status => text().named('status').nullable()();

  TextColumn get uploadFlag => text().named('upload_flag').nullable()();

  /// 1=success，0=fail
  TextColumn get uploadResult => text().named('upload_result').nullable()();

  TextColumn get uploadFailReson =>
      text().named('upload_fail_reson').nullable()();

  /// Lianxin did not specify the meaning
  TextColumn get isCloudData => text().named('is_cloud_data').nullable()();

  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  /// Lianxin PK name biz_glucose_data_pkey，The primary key is id。
  @override
  Set<Column> get primaryKey => {id};
}
