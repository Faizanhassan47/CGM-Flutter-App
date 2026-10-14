import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/domain/ble_adapter_monitor.dart';

/// [BleAdapterMonitor] Real machine implementation: package flutter_blue_plus of adapterState。
class FbpBleAdapterMonitor implements BleAdapterMonitor {
  const FbpBleAdapterMonitor();

  @override
  bool get isOnNow =>
      // only clear off It was just judged that it was not opened，unknown（The cold start channel is not ready) to avoid being accidentally stopped right after starting.
      FlutterBluePlus.adapterStateNow != BluetoothAdapterState.off;

  @override
  Stream<bool> get onChanges => FlutterBluePlus.adapterState
      // Remember the original enumeration：iOS Disconnection report on the control center poweredOff、Permission denied unauthorized，Only the original values ​​can be distinguished。
      .map((s) {
        DevLog.instance.add('ble', 'System Bluetooth status=${s.name}');
        return s;
      })
      .where(
        (s) => s == BluetoothAdapterState.on || s == BluetoothAdapterState.off,
      )
      .map((s) => s == BluetoothAdapterState.on);
}
