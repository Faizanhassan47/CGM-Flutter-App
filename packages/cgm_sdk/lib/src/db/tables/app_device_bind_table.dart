import 'package:drift/drift.dart';

/// Device binding extension table (local only，Non-joint core table). Pack `user_wear_cur` Binding fields other than，
/// according to transmitter_sn + sensor_sn Associated with current wear. Time column unification UTC epoch millisecond。
@DataClassName('AppDeviceBindRow')
class AppDeviceBind extends Table {
  @override
  String get tableName => 'app_device_bind';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId => integer().named('user_id')();

  /// Backstage wear record Id（bind The interface returns; the interface is not ready / Leave blank when offline, fill in after writing back）
  IntColumn get wearId => integer().named('wear_id').nullable()();

  /// Transmitter serial number (associated user_wear_cur）
  TextColumn get transmitterSn => text().named('transmitter_sn').nullable()();

  /// Sensor serial number (associated with user_wear_cur）
  TextColumn get sensorSn => text().named('sensor_sn').nullable()();

  /// Bluetooth address（BLE Reuse；CGM There is also a copy）
  TextColumn get bluetoothAddr => text().named('bluetooth_addr').nullable()();

  /// Device type：half=half toss / full=Throw all
  TextColumn get deviceType => text().named('device_type').nullable()();

  /// Instance form（scanQrCode original value instanceForm）
  TextColumn get instanceForm => text().named('instance_form').nullable()();

  /// Factory expiration date (for verification of overdue date)，scanQrCode expireDate Original value string）
  TextColumn get expireDate => text().named('expire_date').nullable()();

  /// Firmware version (identification code fetched in the background / BLE 0xE7 read）
  TextColumn get firmwareVersion =>
      text().named('firmware_version').nullable()();

  /// Engineering calibration parameters issued by the backend（0xE6 A-E），Leave blank for no hardware period。
  TextColumn get softParams => text().named('soft_params').nullable()();

  /// Equipment factory parameters（0xE6/E8 BLE Read), leave blank if no hardware period。
  TextColumn get firmwareParams => text().named('firmware_params').nullable()();

  RealColumn get bindLatitude => real().named('bind_latitude').nullable()();

  RealColumn get bindLongitude => real().named('bind_longitude').nullable()();

  /// Gaode citycode
  TextColumn get cityCode => text().named('city_code').nullable()();

  /// Gaode adcode
  TextColumn get districtCode => text().named('district_code').nullable()();

  /// 0=To be passed / 1=Sent
  TextColumn get uploadStatus => text().named('upload_status').nullable()();

  /// warming=Warming up / done=End of warm-up
  TextColumn get deviceStatus => text().named('device_status').nullable()();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();
}
