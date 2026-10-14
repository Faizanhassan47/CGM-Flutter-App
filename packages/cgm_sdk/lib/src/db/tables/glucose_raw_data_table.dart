import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `userlocal_glucose_raw_data` — User local blood glucose data-Raw data (Lianxin table）。
///
/// have upload_result/upload_fail_reson but not upload_flag，Contact the core as it is, supplementary transmission by
/// sync_outbox Unified driver。voltage_value / reserve_value1~4 yes decimal(65,30)，fall TEXT。
@DataClassName('UserlocalGlucoseRawDataRow')
class UserlocalGlucoseRawData extends Table {
  @override
  String get tableName => 'userlocal_glucose_raw_data';

  IntColumn get id => integer().named('id')();

  IntColumn get userId => integer().named('user_id').nullable()();

  IntColumn get accountId => integer().named('account_id').nullable()();

  IntColumn get wearId => integer().named('wear_id').nullable()();

  IntColumn get recordSeq => integer().named('record_seq').nullable()();

  IntColumn get measureTime =>
      integer().named('measure_time').map(const DateTimeEpochConverter())();

  RealColumn get rawCurrent1 => real().named('raw_current1').nullable()();

  RealColumn get rawCurrent2 => real().named('raw_current2').nullable()();

  RealColumn get temperature1 => real().named('temperature1').nullable()();

  RealColumn get temperature2 => real().named('temperature2').nullable()();

  /// Lianxin float
  RealColumn get glucoseValue1 => real().named('glucose_value1').nullable()();

  RealColumn get glucoseValue2 => real().named('glucose_value2').nullable()();

  TextColumn get warmupFlag => text().named('warmup_flag').nullable()();

  TextColumn get abnormalFlag => text().named('abnormal_flag').nullable()();

  TextColumn get modifiedFlag => text().named('modified_flag').nullable()();

  /// Current coefficient
  RealColumn get currentCoef => real().named('current_coef').nullable()();

  /// Algorithm sensitivity
  RealColumn get algoK => real().named('algo_k').nullable()();

  /// algorithm intercept
  RealColumn get algoB => real().named('algo_b').nullable()();

  RealColumn get ibase => real().named('ibase').nullable()();

  RealColumn get cgmbase => real().named('cgmbase').nullable()();

  TextColumn get voltageValue => text()
      .named('voltage_value')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get reserveValue1 => text()
      .named('reserve_value1')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get reserveValue2 => text()
      .named('reserve_value2')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get reserveValue3 => text()
      .named('reserve_value3')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get reserveValue4 => text()
      .named('reserve_value4')
      .map(const MedicalDecimalConverter())
      .nullable()();

  TextColumn get reserveStr1 => text().named('reserve_str1').nullable()();

  TextColumn get reserveStr2 => text().named('reserve_str2').nullable()();

  /// 1=success，0=fail
  TextColumn get uploadResult => text().named('upload_result').nullable()();

  TextColumn get uploadFailReson =>
      text().named('upload_fail_reson').nullable()();

  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
