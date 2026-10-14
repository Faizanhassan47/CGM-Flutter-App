import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// `userlocal_collection_daycnt` — Data collection daily statistics (Lianxin table）。
///
/// Recountable raw materials（summary It is the data that can be directly displayed）。
/// `day` Lianxin built date，Press all epoch Millisecond storage。
@DataClassName('UserlocalCollectionDaycntRow')
class UserlocalCollectionDaycnt extends Table {
  @override
  String get tableName => 'userlocal_collection_daycnt';

  IntColumn get id => integer().named('id')();

  IntColumn get wearId => integer().named('wear_id').nullable()();

  IntColumn get userId => integer().named('user_id').nullable()();

  IntColumn get accountId => integer().named('account_id').nullable()();

  IntColumn get day =>
      integer().named('day').map(const DateTimeEpochConverter()).nullable()();

  TextColumn get isComplate => text().named('is_complate').nullable()();

  IntColumn get collectCnt => integer().named('collect_cnt').nullable()();

  /// Total amount of valid data（status='1'）
  IntColumn get effCnt => integer().named('eff_cnt').nullable()();

  /// Collect the total blood glucose concentration on the day
  RealColumn get glucoseTotalVal =>
      real().named('glucose_total_val').nullable()();

  /// hi/low/ext/tir = high/Low/extremum/Amount of blood glucose data that meets the standard
  IntColumn get hiCnt => integer().named('hi_cnt').nullable()();

  IntColumn get lowCnt => integer().named('low_cnt').nullable()();

  IntColumn get extHiCnt => integer().named('ext_hi_cnt').nullable()();

  IntColumn get extLoCnt => integer().named('ext_lo_cnt').nullable()();

  IntColumn get tirCnt => integer().named('tir_cnt').nullable()();

  IntColumn get createTime => integer()
      .named('create_time')
      .map(const DateTimeEpochConverter())
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
