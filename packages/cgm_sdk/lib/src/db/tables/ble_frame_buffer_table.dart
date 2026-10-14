import 'package:drift/drift.dart';

import 'package:cgm_sdk/src/db/converters/converters.dart';

/// local only · Our supplementary form (non-joint core form)）。
///
/// BLE The original frame is first dropped into the library and then fed serially to the algorithm: the algorithm is not thread-safe and has a historical window, and must be based on time.
/// Process one by one in order，App Unprocessed frames when killed or disconnected will continue running from here after restarting.。[status] Walk
/// RAW → DONE / RETRY，single consumer press [measureTime]（Watch at the same time [recordSeq]）Take in ascending order。
@DataClassName('BleFrameBufferRow')
class BleFrameBuffer extends Table {
  @override
  String get tableName => 'ble_frame_buffer';

  /// A natural guide to the order of joining the team（measure_time Same and none record_seq Sort by it）
  IntColumn get id => integer().named('id').autoIncrement()();

  /// Change sensor（wear_id change) algorithm to uninit/init Reset history window
  IntColumn get wearId => integer().named('wear_id').nullable()();

  /// one piece 14 Payload of byte record, frame header removed/The verified data segment
  BlobColumn get rawFrame => blob().named('raw_frame')();

  /// Sort it in ascending order when consuming
  IntColumn get measureTime =>
      integer().named('measure_time').map(const DateTimeEpochConverter())();

  /// measure_time The secondary sort key when the same, if the device is not given, it will be empty.
  IntColumn get recordSeq => integer().named('record_seq').nullable()();

  /// algorithm dataProc of srcData Add ginseng
  RealColumn get rawCurrent => real().named('raw_current').nullable()();

  /// algorithm dataProc of temperature Add ginseng
  RealColumn get temperature => real().named('temperature').nullable()();

  /// Original voltage, dropped to raw_data.voltage_value Use (without entering the algorithm）
  RealColumn get voltage => real().named('voltage').nullable()();

  /// RAW=Pending / DONE=Already placed in inventory / RETRY=Processing failed and needs to be retried
  TextColumn get status =>
      text().named('status').withDefault(const Constant('RAW'))();

  /// No automatic discarding, medical data does not lose frames
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  TextColumn get lastError => text().named('last_error').nullable()();

  IntColumn get createdAt =>
      integer().named('created_at').map(const DateTimeEpochConverter())();
}
