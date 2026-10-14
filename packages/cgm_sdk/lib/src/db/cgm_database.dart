import 'package:drift/drift.dart';

import 'converters/converters.dart';
import 'database_key_store.dart';
import 'encrypted_db_opener.dart';
import 'tables/app_device_bind_table.dart';
import 'tables/app_meta_table.dart';
import 'tables/ble_frame_buffer_table.dart';
import 'tables/collection_daycnt_table.dart';
import 'tables/glucose_data_table.dart';
import 'tables/glucose_modified_log_table.dart';
import 'tables/glucose_raw_data_table.dart';
import 'tables/wear_cur_table.dart';
import 'tables/wear_error_log_table.dart';
import 'tables/wear_status_log_table.dart';

part 'cgm_database.g.dart';

/// SDK Own encryption library `cgm_sdk.db`：Device raw data / blood sugar results / Wearing record / framebuffer / KV。
/// with host App The library is two files, sharing the same [DatabaseKeyStore]。
///
/// The Lianxin business table is mapped as it is without changing the table structure./index; local supplementary index only CREATE INDEX。
@DriftDatabase(
  tables: [
    AppMeta,
    BleFrameBuffer,
    AppDeviceBind,
    UserWearCur,
    UserWearStatusLog,
    UserlocalGlucoseData,
    UserlocalGlucoseRawData,
    UserlocalGlucoseModifiedLog,
    UserlocalWearErrorLog,
    UserlocalCollectionDaycnt,
  ],
)
class CgmDatabase extends _$CgmDatabase {
  CgmDatabase(super.executor);

  static const fileName = 'cgm_sdk.db';

  /// Production entrance: from secure storage Get the key, encrypt and open the library file in the application’s private directory。
  factory CgmDatabase.encrypted({DatabaseKeyStore? keyStore}) {
    final store = keyStore ?? DatabaseKeyStore();
    return CgmDatabase(
      openEncryptedLazy(
        fileName: fileName,
        keyStore: store,
        sisterFileName: 'cgm.db',
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  /// Clear all local data (host logout / Adjust when changing accounts）。
  Future<void> clearAll() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createIndexes();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = OFF;');
        await _backfillFiveMinFlags();
      },
    );
  }

  /// Local supplementary index: only CREATE INDEX，Do not change the structure of the joint core table。
  Future<void> _createIndexes() async {
    const statements = <String>[
      'CREATE INDEX IF NOT EXISTS biz_glucose_modified_log_measure_time_idx '
          'ON userlocal_glucose_modified_log (measure_time DESC);',
      'CREATE INDEX IF NOT EXISTS idx_local_glucose_data_user_wear_time '
          'ON userlocal_glucose_data (user_id, wear_id, measure_time);',
      'CREATE INDEX IF NOT EXISTS idx_local_glucose_data_measure_time '
          'ON userlocal_glucose_data (measure_time);',
      'CREATE INDEX IF NOT EXISTS idx_local_glucose_data_upload_flag '
          'ON userlocal_glucose_data (upload_flag);',
      'CREATE INDEX IF NOT EXISTS idx_collection_daycnt_user_day '
          'ON userlocal_collection_daycnt (user_id, day);',
      'CREATE INDEX IF NOT EXISTS idx_wear_error_log_wear_time '
          'ON userlocal_wear_error_log (wear_id, error_time);',
      'CREATE INDEX IF NOT EXISTS idx_wear_status_log_wear_id '
          'ON user_wear_status_log (wear_id);',
      'CREATE INDEX IF NOT EXISTS idx_ble_frame_buffer_status_order '
          'ON ble_frame_buffer (status, measure_time, record_seq, id);',
    ];
    for (final sql in statements) {
      await customStatement(sql);
    }
  }

  /// The rows filled in the cloud may be missing. five_min，Without the curve, we cannot get that day. according to pipeline Same caliber backfill：
  /// Integer index%5==4 set flag=1、value window(maximum+smallest)/2；The old version library does not have this column yet. Let’s explore its existence first.。
  Future<void> _backfillFiveMinFlags() async {
    final hasFiveMin = await customSelect(
      "SELECT 1 FROM pragma_table_info('userlocal_glucose_data') "
      "WHERE name = 'five_min_flag'",
    ).get();
    if (hasFiveMin.isEmpty) return;
    await customStatement('''
      UPDATE userlocal_glucose_data SET
        five_min_flag = '1',
        five_min_glucose = CAST(ROUND((
          SELECT (MAX(g.glucose_value1) + MIN(g.glucose_value1)) / 2.0
          FROM userlocal_glucose_data g
          WHERE g.wear_id = userlocal_glucose_data.wear_id
            AND g.measure_time > userlocal_glucose_data.measure_time - 300000
            AND g.measure_time <= userlocal_glucose_data.measure_time
            AND g.glucose_value1 IS NOT NULL
        ), 2) AS TEXT)
      WHERE is_cloud_data = '1'
        AND (five_min_flag IS NULL OR five_min_flag = '')
        AND glucose_value1 IS NOT NULL
        AND (measure_time / 60000) % 5 = 4;
    ''');
    await customStatement('''
      UPDATE userlocal_glucose_data SET five_min_flag = '0'
      WHERE is_cloud_data = '1'
        AND (five_min_flag IS NULL OR five_min_flag = '');
    ''');
  }
}
