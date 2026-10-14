import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/log/breadcrumb_log.dart';
import 'package:cgm_sdk/src/collection/foreground_service_controller.dart';

/// Real front-end service implementation, only Android Effective: use flutter_foreground_task Start a notification with permanent notification
/// Front desk service keep alive。iOS Walk CoreBluetooth Background mode, all methods here return directly。
///
/// Collection, algorithm, and upload are all in the master’s hands isolate，The foreground service is only responsible for nailing the process to the foreground priority。
/// `startService` Must bring callback：The process is ROM After killing it, the system only restarts the ”service”. isolate
/// I won’t follow you back, only callback That backstage isolate Can run, rely on it App pull up (see [_KeepAliveHandler]）。
class FlutterForegroundServiceController
    implements ForegroundServiceController {
  /// Resident Notice/Service is unique ID。
  static const int _serviceId = 2001;

  bool _initialized = false;

  bool get _supported => Platform.isAndroid;

  /// Notification channels and foreground task configuration only need to be installed once。
  void _ensureInit() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'cgm_collection',
        channelName: 'blood glucose monitoring',
        channelDescription:
            'Keep receiving and uploading blood glucose data in the background',
        // LOW：No sound, no vibration, no preemption, only one permanent message in the notification bar
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      // iOS Not at all start，Give me a place
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // collection/Upload timer in main isolate Run by yourself, no need for periodic callbacks
        eventAction: ForegroundTaskEventAction.nothing(),
        // Power on/After the upgrade, the service will start (plug-in’s RebootReceiver Only pull when the service was originally running），
        // Pull it up and walk in the same way [_KeepAliveHandler] Decide whether to App call back together
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> ensureRunning({
    String title = 'Blood glucose monitoring in progress',
    String text =
        'Continuously receiving and uploading blood glucose data in the background',
  }) async {
    if (!_supported) return;
    try {
      _ensureInit();
      // collection↔The two states of waiting for unbinding share this notification, and the copywriting has been corrected and the cost has been entered.。
      // onlyAlertOnce=true，Update does not ring or vibrate。
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        return;
      }
      // When the service is restarted by the system, the background isolate Relying on this flag to judge whether ”we should be collecting it in the first place”」，
      // That’s right App recall; turn on/If you don’t wear it, it will disturb people if you shoot it once.。
      await FlutterForegroundTask.saveData(key: _collectingKey, value: true);
      // Backstage isolate Can’t see the Lord isolate Static variables, the package name (breadcrumb path) must be passed together
      await FlutterForegroundTask.saveData(
        key: _packageNameKey,
        value: BreadcrumbLog.packageName,
      );
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: title,
        notificationText: text,
        callback: cgmKeepAliveCallback,
      );
      DevLog.instance.add(
        'ble',
        'The foreground service has been started (background keep-alive collection+upload）',
      );
    } catch (e) {
      // Notification permission not granted / System refuses to start FGS：It does not affect the foreground collection, only the background may be frozen.，
      // Swallow it and wait for the next collection start and stop before trying again.
      if (kDebugMode) {
        debugPrint('[Front desk service] Startup failed (not fatal)）: $e');
      }
      DevLog.instance.add(
        'ble',
        'Foreground service failed to start(Not fatal): $e',
      );
    }
  }

  @override
  Future<void> stop() async {
    if (!_supported) return;
    try {
      // First lower the flag and then stop: the business is actively stopped (unbundled)/maturity/After logging out), even if the service is pulled up by someone，
      // It shouldn’t be done anymore App recall。
      await FlutterForegroundTask.saveData(key: _collectingKey, value: false);
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        DevLog.instance.add('ble', 'Front desk service has stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Front desk service] Stop failure (not fatal)）: $e');
      }
    }
  }
}

/// 「We were supposed to be collecting ”flags, Lord” isolate write, background isolate Read (plug-in’s cross isolate storage）。
const String _collectingKey = 'cgm_collecting';

/// Host package name, main isolate write, background isolate Read: A section of the breadcrumb path。
const String _packageNameKey = 'cgm_package_name';

/// frontend service background isolate Entrance. Must be a top-level function and marked vm:entry-point，
/// otherwise release covered tree-shaking dropped and the callback was not found when the service was restarted.。
@pragma('vm:entry-point')
void cgmKeepAliveCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

/// The process is ROM Self-healing after killing: The system only restarts the ”service”, and the main isolate I won’t come back on my own, this background
/// isolate The only job is to App call back; lord isolate After getting up, take the normal startup path (reconnect、0xD3 Replenish and resume collection）。
///
/// only in [TaskStarter.system]（System restart service/(Automatically starts after power on): The user starts it by himself App That time was
/// [TaskStarter.developer]，Shouldn’t call。App I’m already at the front desk and don’t call you.。
class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Book isolate The static variables in are empty. Get the package name back first, otherwise all the breadcrumbs below will not fall to the disk.
    BreadcrumbLog.packageName =
        await FlutterForegroundTask.getData<String>(key: _packageNameKey) ?? '';
    // Breadcrumbs are dropped at every step: self-healing may be delayed by several minutes, so be able to tell the difference onStart Haven’t been transferred, haven’t passed the conditions、
    // still launchApp quilt ROM bar。
    BreadcrumbLog.write('[keepalive] onStart starter=${starter.name}');
    if (starter != TaskStarter.system) {
      BreadcrumbLog.write(
        '[keepalive] Skip: No system Start (activated by the user) App）',
      );
      return;
    }
    final collecting = await FlutterForegroundTask.getData<bool>(
      key: _collectingKey,
    );
    if (collecting != true) {
      BreadcrumbLog.write(
        '[keepalive] jump over：collecting=$collecting（It shouldn’t have been collected in the first place）',
      );
      return; // Not bound/Expired/Already actively stopped
    }
    if (await FlutterForegroundTask.isAppOnForeground) {
      BreadcrumbLog.write(
        '[keepalive] jump over：App Already in the foreground',
      );
      return;
    }
    BreadcrumbLog.write('[keepalive] → launchApp() call back the lord isolate');
    FlutterForegroundTask.launchApp();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
