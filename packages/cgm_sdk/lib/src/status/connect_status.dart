import 'package:flutter/foundation.dart';

/// Acquisition connection diagnosis: Unable to connect/and other configurations/When the recovery chain fails, the top bar gives a short sentence of the real reason.。
/// null=No prompt。
///
/// Who Sets Who Cleans Up: Collection runner Tube"Can’t connect to device/Calibration not ready"，Login to restore chain management
/// "Interface failed and retrying"——Each only covers/Clear your own copy to avoid erasing each other。
class ConnectStatus {
  static final ValueNotifier<String?> hint = ValueNotifier<String?>(null);
}
