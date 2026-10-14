/// CGM SDK：Device communication / protocol / algorithm / local storage core。
/// Implement everything internally export for App Use it directly; the end is the first③facade `CgmSdk`（Host / For native shell）。
library;

export 'src/constants/app_constants.dart';
export 'src/log/dev_log.dart';
export 'src/status/backfill_status.dart';
export 'src/status/connect_status.dart';
export 'src/status/link_activity.dart';
export 'src/storage/secure_storage.dart';
export 'src/db/converters/converters.dart';
export 'src/ble/ble_frame_codec.dart';
export 'src/ble/ble_link_tuning.dart';
export 'src/ble/cgm_command.dart';
export 'src/ble/fbp_ble_adapter_monitor.dart';
export 'src/ble/real_cgm_ble_gate.dart';
export 'src/algorithm/algorithm_gateway.dart';
export 'src/algorithm/glucose_value.dart';
export 'src/algorithm/jni_algorithm_gateway.dart';
export 'src/algorithm/linear_algorithm_gateway.dart';
export 'src/algorithm/mock_algorithm_gateway.dart';
export 'src/pipeline/serial_executor.dart';
export 'src/collection/cgm_replay_dataset.dart';
export 'src/collection/device_clock_skew.dart';
export 'src/collection/foreground_service_controller.dart';
export 'src/domain/activation_check.dart';
export 'src/domain/ble_adapter_monitor.dart';
export 'src/domain/cgm_ble_gate.dart';
export 'src/domain/device_scan_result.dart';
export 'src/domain/wear_lifecycle_resolver.dart';
export 'src/db/database_key_store.dart';
export 'src/db/encrypted_db_opener.dart';
export 'src/db/cgm_database.dart';
export 'src/domain/bind_hooks.dart';
export 'src/log/breadcrumb_log.dart';
export 'src/collection/glucose_backfill_coordinator.dart';
export 'src/collection/glucose_collection_runner.dart';
export 'src/collection/device_timeline_audit.dart';
export 'src/collection/device_timeline_migration.dart';
export 'src/collection/glucose_timeline_repair.dart';
export 'src/collection/flutter_foreground_service_controller.dart';
export 'src/collection/live_glucose_collector.dart';
export 'src/collection/replay_glucose_collector.dart';
export 'src/collection/simulated_glucose_collector.dart';
export 'src/pipeline/glucose_pipeline_repository.dart';
export 'src/wear/wear_repository.dart';
export 'src/glucose/algo_param_store.dart';
export 'src/glucose/bgm_calibration_store.dart';
export 'src/domain/bind_activation_service.dart';

// Facade (No.③step): host App / The native shell takes this layer；App I still use the core class above directly。
export 'src/domain/sdk_tuning.dart';
export 'src/facade/cgm_sdk.dart';
export 'src/facade/errors.dart';
export 'src/facade/models.dart';
