import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../core/device_time.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/wellness_offline_store.dart';
import '../services/wellness_reminder_log.dart';

class AppController extends ChangeNotifier {
  AppController(this.api);
  final ApiService api;

  /// Bumped only for auth / splash / profile-gate changes.
  /// CircleApp listens here so glucose ticks do not rebuild MainShell.
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);

  /// Bumped for live glucose / connection / device status.
  /// Home + History listen here so profile/report notifies do not rebuild charts.
  final ValueNotifier<int> telemetryRevision = ValueNotifier(0);

  void _bumpSession() => sessionRevision.value++;
  void _bumpTelemetry() => telemetryRevision.value++;

  bool loading = true;
  bool authenticated = false;
  bool sdkReady = false;
  String? error;
  String sdkVersion = '';
  CgmConnectionState connection = CgmConnectionState.disconnected;
  DeviceStatus? deviceStatus;
  WearInfo? wear;
  GlucoseSample? latest;
  /// Phone clock when the last live BLE glucose packet arrived.
  DateTime? lastLiveAt;
  List<GlucoseSample> history = [];
  List<ScanDevice> scanResults = [];
  String progressText = '';

  // User Profile
  String fullName = '';
  String userEmail = '';
  String phoneNumber = '';
  String dateOfBirth = '';
  String gender = '';
  String? profilePictureUrl;
  String authProvider = '';
  bool hasPassword = false;
  String preferredGlucoseUnit = 'mg/dL';
  String language = AppConfig.defaultLanguage;
  String referralCode = '';
  bool profileCompleted = false;
  bool emailVerified = false;
  /// When set, root shows the email verification screen before onboarding.
  String? pendingEmailVerification;

  /// User chose "I'll set up later" on the device onboarding gate.
  bool deviceSetupSkipped = false;
  static const _deviceSetupSkippedKey = 'pref_device_setup_skipped';

  /// True until the user has a live wear session, stored binding, or skipped setup.
  bool get needsDeviceSetup =>
      !deviceSetupSkipped &&
      wear == null &&
      _binding == null &&
      activeDevice == null;

  Future<void> skipDeviceSetup() async {
    deviceSetupSkipped = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceSetupSkippedKey, true);
    _bumpSession();
    notifyListeners();
  }

  Future<void> _restoreDeviceSetupSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    deviceSetupSkipped = prefs.getBool(_deviceSetupSkippedKey) ?? false;
  }

  Future<void> _clearDeviceSetupSkipped() async {
    deviceSetupSkipped = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceSetupSkippedKey);
  }

  bool get needsEmailVerification =>
      pendingEmailVerification != null &&
      pendingEmailVerification!.trim().isNotEmpty;

  /// Clears leftover pairing from a previous account on this phone.
  Future<void> _clearLocalDeviceState() async {
    wear = null;
    activeDevice = null;
    activeSensor = null;
    _binding = null;
    await api.clearBackendBinding();
    try {
      await CgmSdk.unbind();
    } catch (_) {}
  }

  /// After auth: clear stale local pairing, then restore this account's device.
  Future<void> _syncDeviceStateAfterAuth({required bool forceSetup}) async {
    await _clearLocalDeviceState();
    if (forceSetup) {
      await _clearDeviceSetupSkipped();
      return;
    }
    await loadActiveDeviceAndSensor();
    wear = await CgmSdk.currentWear();
    if (activeDevice != null || _binding != null || wear != null) {
      await _clearDeviceSetupSkipped();
    } else {
      await _restoreDeviceSetupSkipped();
    }
  }
  double targetLow = 90.0;
  double targetHigh = 130.0;
  double urgentLowThreshold = 55.0;
  double urgentHighThreshold = 250.0;

  // Sleep & Overnight Monitoring
  String bedTime = '22:00';
  String wakeTime = '07:00';
  double nightLowThreshold = 70.0;
  double nightHighThreshold = 160.0;
  bool nightAlertsEnabled = true;
  Map<String, dynamic>? overnightReport;

  // Selected CGM Hardware Type
  String selectedDeviceType = 'Disposable'; // 'Disposable' or 'Reusable'
  Map<String, dynamic>? activeDevice;
  Map<String, dynamic>? activeSensor;

  /// True only while backend says this sensor session is still in warmup
  /// (new hardware serial). Reconnects to a known serial stay false.
  bool get isSensorWarming {
    final end = sensorWarmupEndAt;
    return end != null && DateTime.now().isBefore(end);
  }

  /// Cached absolute warmup deadline so closing the app never pauses the clock.
  DateTime? _cachedWarmupEndsAt;
  String? _cachedWarmupSerial;

  /// Warmup end from DB (`activatedAt` / `warmupEndsAt`), not SDK reconnect time.
  /// Uses wall-clock time — remaining = endAt - DateTime.now() even after kill.
  DateTime? get sensorWarmupEndAt {
    final s = activeSensor;
    DateTime? local;
    if (s != null) {
      final raw = s['warmupEndsAt'] ?? s['activatedAt'];
      local = DateTime.tryParse('$raw')?.toLocal();
      final flagged = s['inWarmup'] == true ||
          '${s['status'] ?? ''}'.toLowerCase() == 'warmup';
      if (local != null) {
        if (!flagged && !DateTime.now().isBefore(local)) {
          local = null;
        } else if (!DateTime.now().isBefore(local)) {
          local = null;
        }
      }
    }
    local ??= _cachedWarmupEndsAt;
    if (local == null) return null;
    if (!DateTime.now().isBefore(local)) {
      _cachedWarmupEndsAt = null;
      return null;
    }
    return local;
  }

  Future<void> _persistWarmupDeadline(Map<String, dynamic>? sensor) async {
    final prefs = await SharedPreferences.getInstance();
    if (sensor == null) {
      _cachedWarmupEndsAt = null;
      _cachedWarmupSerial = null;
      await prefs.remove('sensor_warmup_ends_at');
      await prefs.remove('sensor_warmup_serial');
      unawaited(NotificationService.instance.cancelSensorReadyNotification());
      return;
    }
    final serial = '${sensor['sensorIdentifier'] ?? ''}'.trim();
    final raw = sensor['warmupEndsAt'] ?? sensor['activatedAt'];
    final end = DateTime.tryParse('$raw')?.toLocal();
    final inWarmup = sensor['inWarmup'] == true ||
        '${sensor['status'] ?? ''}'.toLowerCase() == 'warmup';
    if (end == null || !inWarmup || !DateTime.now().isBefore(end)) {
      final hadWarmup = prefs.getString('sensor_warmup_ends_at') != null;
      _cachedWarmupEndsAt = null;
      _cachedWarmupSerial = null;
      await prefs.remove('sensor_warmup_ends_at');
      await prefs.remove('sensor_warmup_serial');
      if (hadWarmup) {
        // Warmup just finished while app was open / resumed.
        await _notifySensorReadyIfNeeded(prefs);
      } else {
        unawaited(NotificationService.instance.cancelSensorReadyNotification());
      }
      return;
    }
    _cachedWarmupEndsAt = end;
    _cachedWarmupSerial = serial.isEmpty ? null : serial;
    await prefs.setString('sensor_warmup_ends_at', end.toUtc().toIso8601String());
    if (serial.isNotEmpty) {
      await prefs.setString('sensor_warmup_serial', serial);
    }
    await prefs.remove('sensor_warmup_ready_notified');
    unawaited(
      NotificationService.instance.scheduleSensorReadyNotification(end),
    );
  }

  Future<void> _notifySensorReadyIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool('sensor_warmup_ready_notified') == true) return;
    await prefs.setBool('sensor_warmup_ready_notified', true);
    await NotificationService.instance.showSensorReadyNotification();
  }

  Future<void> _restoreWarmupDeadline() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sensor_warmup_ends_at');
    final end = DateTime.tryParse(raw ?? '')?.toLocal();
    if (end == null) {
      _cachedWarmupEndsAt = null;
      _cachedWarmupSerial = null;
      return;
    }
    if (!DateTime.now().isBefore(end)) {
      _cachedWarmupEndsAt = null;
      _cachedWarmupSerial = null;
      await prefs.remove('sensor_warmup_ends_at');
      await prefs.remove('sensor_warmup_serial');
      await _notifySensorReadyIfNeeded(prefs);
      return;
    }
    _cachedWarmupEndsAt = end;
    _cachedWarmupSerial = prefs.getString('sensor_warmup_serial');
    unawaited(
      NotificationService.instance.scheduleSensorReadyNotification(end),
    );
  }

  // Preferences
  bool pushNotifications = true;
  bool criticalAlerts = true;
  bool sensorAlerts = true;
  bool reportReminders = true;

  // Family Circle
  Map<String, dynamic>? family;
  List<dynamic> familyMembers = [];

  // Reports
  Map<String, dynamic> detailedReport = {};

  // Alerts
  List<dynamic> alerts = [];
  final List<Map<String, dynamic>> _localGlucoseAlerts = [];
  DateTime? _alertsClearedAt;
  final Set<String> _notifiedAlertIds = <String>{};

  StreamSubscription<CgmConnectionState>? _connectionSub;
  StreamSubscription<DeviceStatus>? _statusSub;
  StreamSubscription<List<GlucoseSample>>? _watchSub;
  StreamSubscription<GlucoseSample>? _glucoseSub;
  StreamSubscription<ProgressEvent>? _progressSub;
  StreamSubscription<SdkErrorEvent>? _errorSub;
  BackendBinding? _binding;
  DateTime? _lastLocalAlertAt;
  String? _lastLocalAlertType;
  Timer? _uploadQueueTimer;
  bool _uploadQueueFlushing = false;
  Future<void>? _uploadEnqueueChain;
  static const _uploadQueueKey = 'glucose_upload_queue_v1';
  static const _secureStore = kSecureStorage;
  static const _liveFreshWindow = Duration(minutes: 10);

  Future<List<Map<String, dynamic>>> _readUploadQueue() async {
    // Migrate legacy plaintext SharedPreferences queue once.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_uploadQueueKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStore.write(key: _uploadQueueKey, value: legacy);
      await prefs.remove(_uploadQueueKey);
    }
    final raw = await _secureStore.read(key: _uploadQueueKey) ?? '[]';
    return (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _writeUploadQueue(List<Map<String, dynamic>> rows) async {
    await _secureStore.write(key: _uploadQueueKey, value: jsonEncode(rows));
  }

  Future<void> _clearUploadQueue() async {
    await _secureStore.delete(key: _uploadQueueKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uploadQueueKey);
  }

  Future<void> initialize() async {
    loading = true;
    _bumpSession();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      pushNotifications = prefs.getBool('pref_push') ?? true;
      criticalAlerts = prefs.getBool('pref_critical') ?? true;
      final clearedRaw = prefs.getString('alerts_cleared_at');
      _alertsClearedAt = clearedRaw == null ? null : DateTime.tryParse(clearedRaw);
      sensorAlerts = prefs.getBool('pref_sensor_alerts') ?? true;
      reportReminders = prefs.getBool('pref_reminders') ?? true;
      selectedDeviceType = prefs.getString('pref_device_type') ?? 'Disposable';
      await _restoreWarmupDeadline();

      // Critical path only — paint Home ASAP; hydrate the rest after first frame.
      authenticated = await api.restoreSession();
      if (authenticated) {
        await loadUserProfile();
        await loadActiveDeviceAndSensor();
      }

      await CgmSdk.init(
        config: const SdkConfig(
          logLevel: LogLevel.info,
          foregroundNotice: 'Circle glucose monitoring is active',
          minBatteryMv: 2800,
          warmupMinutes: AppConfig.sensorWarmupMinutes,
        ),
      );
      sdkVersion =
          '${await CgmSdk.version()} / ${await CgmSdk.algorithmVersion()}';
      sdkReady = true;
      wear = await CgmSdk.currentWear();
      _binding = await api.storedBinding();
      if (authenticated) {
        if (activeDevice != null || _binding != null || wear != null) {
          await _clearDeviceSetupSkipped();
        } else {
          await _restoreDeviceSetupSkipped();
        }
      }
      _attachSdkStreams();
      await refreshHistory();
    } catch (e) {
      error = 'SDK initialization failed: $e';
    } finally {
      loading = false;
      _bumpSession();
      notifyListeners();
      unawaited(_hydrateSecondary());
    }
  }

  /// Non-critical fetches/services after first UI paint (2GB-friendly startup).
  Future<void> _hydrateSecondary() async {
    // Let the first frame land before competing for CPU/network.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!authenticated) {
      unawaited(NotificationService.instance.initialize());
      return;
    }
    unawaited(loadFamily());
    unawaited(loadAlerts(pageSize: 25));
    unawaited(loadReports());
    unawaited(loadOvernightReport());
    unawaited(sendPhoneHardwareLogs());
    unawaited(
      NotificationService.instance.initialize(
        apiService: api,
        pushEnabled: pushNotifications,
      ),
    );
    unawaited(_restoreWellnessReminders());
    // Push any offline queue as soon as the network is reachable.
    unawaited(flushPendingUploads());
  }

  /// Public entry for app-resume / network-restore sync.
  Future<void> flushPendingUploads() async {
    if (!authenticated) return;
    if (!await _networkReachable()) return;
    await _flushUploadQueue();
  }

  Future<bool> _networkReachable() async {
    try {
      final host = Uri.tryParse(AppConfig.apiBaseUrl)?.host;
      final probe = (host != null && host.isNotEmpty) ? host : 'dns.google';
      final result = await InternetAddress.lookup(probe)
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restoreWellnessReminders() async {
    try {
      final response = await api.getWellnessReminders();
      var settings =
          (response['settings'] as Map?)?.cast<String, dynamic>() ?? {};
      final schedules = (response['schedules'] as List?) ?? const [];

      // Reminder times are entered in the user's local phone time. Keep the
      // server value synchronized with the OS timezone without requesting GPS
      // or location permissions.
      try {
        final deviceTimezone = await FlutterTimezone.getLocalTimezone();
        final timezoneId = deviceTimezone.identifier;
        if (timezoneId.isNotEmpty && settings['timeZoneId'] != timezoneId) {
          final updated = await api.updateWellnessReminders({
            'timeZoneId': timezoneId,
          });
          settings =
              (updated['settings'] as Map?)?.cast<String, dynamic>() ??
              settings;
          debugPrint('[Notifications] Timezone synchronized: $timezoneId');
        }
      } catch (error) {
        debugPrint('[Notifications] Timezone detection failed: $error');
      }

      await NotificationService.instance.scheduleWellness(
        settings: settings,
        schedules: schedules,
      );
      debugPrint(
        '[Notifications] Wellness reminders restored (${schedules.length} meal schedules).',
      );
    } catch (error) {
      debugPrint(
        '[Notifications] Failed to restore wellness reminders: $error',
      );
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final data = await api.getProfile();
      if (data.isNotEmpty) {
        fullName = data['fullName']?.toString().trim().isNotEmpty == true
            ? data['fullName']
            : fullName;
        userEmail = data['email']?.toString() ?? userEmail;
        phoneNumber = data['phoneNumber']?.toString() ?? phoneNumber;
        dateOfBirth = data['dateOfBirth']?.toString() ?? dateOfBirth;
        gender = data['gender']?.toString() ?? gender;
        profilePictureUrl =
            data['profilePictureUrl']?.toString() ?? profilePictureUrl;
        authProvider = data['authProvider']?.toString() ?? authProvider;
        hasPassword = data['hasPassword'] == true;
        preferredGlucoseUnit =
            data['preferredGlucoseUnit']?.toString() ?? preferredGlucoseUnit;
        language = data['language']?.toString() ?? language;
        referralCode = data['referralCode']?.toString() ?? referralCode;
        emailVerified = data['emailVerified'] == true || emailVerified;
        final wasComplete = profileCompleted;
        profileCompleted = data['profileCompleted'] == true;
        if (wasComplete != profileCompleted) _bumpSession();
        bedTime = data['bedTime']?.toString() ?? bedTime;
        wakeTime = data['wakeTime']?.toString() ?? wakeTime;
        if (data['targetLow'] != null) {
          targetLow = (data['targetLow'] as num).toDouble();
        }
        if (data['targetHigh'] != null) {
          targetHigh = (data['targetHigh'] as num).toDouble();
        }
        if (data['urgentLowThreshold'] != null) {
          urgentLowThreshold = (data['urgentLowThreshold'] as num).toDouble();
        }
        if (data['urgentHighThreshold'] != null) {
          urgentHighThreshold = (data['urgentHighThreshold'] as num).toDouble();
        }
        if (data['nightLowThreshold'] != null) {
          nightLowThreshold = (data['nightLowThreshold'] as num).toDouble();
        }
        if (data['nightHighThreshold'] != null) {
          nightHighThreshold = (data['nightHighThreshold'] as num).toDouble();
        }
        if (data['nightAlertsEnabled'] != null) {
          nightAlertsEnabled = data['nightAlertsEnabled'] == true;
        }
        if (data['pushNotificationsEnabled'] != null) {
          pushNotifications = data['pushNotificationsEnabled'] == true;
        }
        if (data['criticalGlucoseAlertsEnabled'] != null) {
          criticalAlerts = data['criticalGlucoseAlertsEnabled'] == true;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pref_push', pushNotifications);
        await prefs.setBool('pref_critical', criticalAlerts);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadActiveDeviceAndSensor() async {
    try {
      final sensorData = await api.getActiveSensor();
      if (sensorData != null && sensorData.isNotEmpty) {
        activeSensor = sensorData;
        await _persistWarmupDeadline(sensorData);
        final deviceId = sensorData['deviceId'];
        final sensorId = sensorData['id'];
        if (deviceId != null) {
          final devIdInt = int.tryParse('$deviceId');
          if (devIdInt != null) {
            final sensorIdInt = int.tryParse('$sensorId');
            if (sensorIdInt != null) {
              _binding = BackendBinding(
                deviceId: devIdInt,
                sensorId: sensorIdInt,
              );
              await api.cacheBinding(deviceId: devIdInt, sensorId: sensorIdInt);
            }
            activeDevice = await api.getDevice(devIdInt);
          }
        }
      } else {
        activeSensor = null;
        await _persistWarmupDeadline(null);
        final devices = await api.getDevices();
        if (devices.isNotEmpty) {
          activeDevice = devices.first as Map<String, dynamic>;
        }
      }
      notifyListeners();
      _bumpTelemetry();
    } catch (_) {}
  }

  /// Refresh warmup / sensor state after app resume (wall clock keeps running).
  Future<void> onAppResumed() async {
    await flushPendingUploads();
    await checkWarmupFinished();
    if (!authenticated) return;
    unawaited(_flushWellnessOfflineQueue());
    await loadActiveDeviceAndSensor();
    // Refresh alerts so due hydration reminders appear in Notifications.
    unawaited(loadAlerts(pageSize: 25));
    _bumpTelemetry();
  }

  Future<void> _flushWellnessOfflineQueue() async {
    try {
      final pending = await WellnessOfflineStore.pending();
      if (pending.isEmpty) return;
      final remaining = <Map<String, dynamic>>[];
      for (final event in pending) {
        try {
          if (event['kind'] == 'water') {
            await api.createWater(
              Map<String, dynamic>.from(event['data'] as Map),
            );
          } else if (event['kind'] == 'meal') {
            await api.createMeal(
              Map<String, dynamic>.from(event['data'] as Map),
            );
          }
        } catch (_) {
          remaining.add(event);
        }
      }
      if (remaining.length != pending.length) {
        await WellnessOfflineStore.replace(remaining);
      }
    } catch (e) {
      debugPrint('[Wellness] Offline flush failed: $e');
    }
  }

  /// Call when countdown hits zero or app resumes after the deadline.
  Future<void> checkWarmupFinished() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sensor_warmup_ends_at');
    final end = DateTime.tryParse(raw ?? '')?.toLocal() ?? _cachedWarmupEndsAt;
    if (end == null || DateTime.now().isBefore(end)) return;
    _cachedWarmupEndsAt = null;
    _cachedWarmupSerial = null;
    await prefs.remove('sensor_warmup_ends_at');
    await prefs.remove('sensor_warmup_serial');
    await _notifySensorReadyIfNeeded(prefs);
    _bumpTelemetry();
    if (authenticated) {
      unawaited(loadActiveDeviceAndSensor());
    }
  }

  Future<void> sendPhoneHardwareLogs() async {
    try {
      String deviceModel = 'Unknown Device';
      String osVersion = Platform.operatingSystemVersion;
      final platform = Platform.operatingSystem;

      if (Platform.isAndroid) {
        deviceModel = Platform.environment['MODEL'] ?? 'Android Device';
      } else if (Platform.isIOS) {
        deviceModel = 'Apple Device';
      } else {
        deviceModel = Platform.operatingSystem;
      }

      await api.logPhoneHardware(
        deviceModel: deviceModel,
        osVersion: osVersion,
        platform: platform,
        appVersion: '4.0.0',
      );
    } catch (_) {
      // Telemetry log error silently ignored
    }
  }

  Future<void> loadOvernightReport() async {
    try {
      final data = await api.getOvernightReport();
      overnightReport = data;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveSleepSettings({
    required String bed,
    required String wake,
    required double lowThreshold,
    required double highThreshold,
    required bool alertsEnabled,
  }) async {
    await _run(() async {
      final res = await api.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        preferredGlucoseUnit: preferredGlucoseUnit,
        bedTime: bed,
        wakeTime: wake,
        nightLowThreshold: lowThreshold,
        nightHighThreshold: highThreshold,
        nightAlertsEnabled: alertsEnabled,
      );
      bedTime = res['bedTime'] ?? bed;
      wakeTime = res['wakeTime'] ?? wake;
      if (res['nightLowThreshold'] != null) {
        nightLowThreshold = (res['nightLowThreshold'] as num).toDouble();
      }
      if (res['nightHighThreshold'] != null) {
        nightHighThreshold = (res['nightHighThreshold'] as num).toDouble();
      }
      if (res['nightAlertsEnabled'] != null) {
        nightAlertsEnabled = res['nightAlertsEnabled'] == true;
      }
      notifyListeners();
      unawaited(loadOvernightReport());
    });
  }

  Future<void> saveGlucoseTargetRange({
    required double low,
    required double high,
    double? urgentLow,
    double? urgentHigh,
  }) async {
    await _run(() async {
      final res = await api.updateProfile(
        fullName: fullName,
        preferredGlucoseUnit: preferredGlucoseUnit,
        targetLow: low,
        targetHigh: high,
        urgentLowThreshold: urgentLow ?? urgentLowThreshold,
        urgentHighThreshold: urgentHigh ?? urgentHighThreshold,
      );
      if (res['targetLow'] != null) {
        targetLow = (res['targetLow'] as num).toDouble();
      } else {
        targetLow = low;
      }
      if (res['targetHigh'] != null) {
        targetHigh = (res['targetHigh'] as num).toDouble();
      } else {
        targetHigh = high;
      }
      if (res['urgentLowThreshold'] != null) {
        urgentLowThreshold = (res['urgentLowThreshold'] as num).toDouble();
      } else if (urgentLow != null) {
        urgentLowThreshold = urgentLow;
      }
      if (res['urgentHighThreshold'] != null) {
        urgentHighThreshold = (res['urgentHighThreshold'] as num).toDouble();
      } else if (urgentHigh != null) {
        urgentHighThreshold = urgentHigh;
      }
      notifyListeners();
    });
  }

  Future<void> saveProfile({
    required String name,
    String? phone,
    String? dob,
    String? selectedGender,
    String? unit,
    String? lang,
  }) async {
    await _run(() async {
      final res = await api.updateProfile(
        fullName: name,
        phoneNumber: phone,
        dateOfBirth: dob,
        gender: selectedGender,
        preferredGlucoseUnit: unit ?? preferredGlucoseUnit,
        language: lang ?? language,
      );
      fullName = res['fullName'] ?? name;
      phoneNumber = res['phoneNumber'] ?? phone ?? '';
      dateOfBirth = res['dateOfBirth']?.toString() ?? dob ?? dateOfBirth;
      gender = res['gender']?.toString() ?? selectedGender ?? gender;
      preferredGlucoseUnit =
          res['preferredGlucoseUnit'] ?? unit ?? preferredGlucoseUnit;
      language = res['language'] ?? lang ?? language;
      profileCompleted = true;
      _bumpSession();
    });
  }

  /// Uploads user profile picture and updates profilePictureUrl.
  Future<void> uploadProfilePicture(
    List<int> bytes,
    String filename, {
    String contentType = 'image/jpeg',
  }) async {
    await _run(() async {
      final res = await api.uploadProfilePicture(
        bytes,
        filename,
        contentType: contentType,
      );
      if (res['profilePictureUrl'] != null) {
        profilePictureUrl = res['profilePictureUrl'].toString();
      }
      final nested = res['profile'];
      if (nested is Map && nested['profilePictureUrl'] != null) {
        profilePictureUrl = nested['profilePictureUrl'].toString();
      }
      notifyListeners();
    });
  }

  Future<void> saveLanguage(String newLanguage) async {
    await saveProfile(name: fullName, lang: newLanguage);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', newLanguage);
  }

  Future<void> setPreferences({
    bool? push,
    bool? critical,
    bool? sensor,
    bool? reminders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (push != null) {
      pushNotifications = push;
      await prefs.setBool('pref_push', push);
    }
    if (critical != null) {
      criticalAlerts = critical;
      await prefs.setBool('pref_critical', critical);
    }
    if (sensor != null) {
      sensorAlerts = sensor;
      await prefs.setBool('pref_sensor_alerts', sensor);
    }
    if (reminders != null) {
      reportReminders = reminders;
      await prefs.setBool('pref_reminders', reminders);
    }
    notifyListeners();
    await _syncNotificationPrefs();
  }

  Future<void> _syncNotificationPrefs() async {
    if (!authenticated) return;
    try {
      if (fullName.trim().isNotEmpty) {
        await api.updateProfile(
          fullName: fullName,
          pushNotificationsEnabled: pushNotifications,
          criticalGlucoseAlertsEnabled: criticalAlerts,
        );
      }
      await NotificationService.instance.initialize(
        apiService: api,
        pushEnabled: pushNotifications,
      );
    } catch (e) {
      debugPrint('[AppController] Failed to sync notification prefs: $e');
    }
  }

  Future<void> setDeviceType(String type) async {
    selectedDeviceType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_device_type', type);
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    await _run(() async {
      try {
        final res = await api.login(username.trim(), password);
        await _completeAuthenticatedSession(res, forceDeviceSetup: false);
      } on ApiException catch (e) {
        if (e.requiresEmailVerification) {
          pendingEmailVerification =
              e.verificationEmail ?? username.trim().toLowerCase();
          emailVerified = false;
          authenticated = false;
          _bumpSession();
          notifyListeners();
          return;
        }
        rethrow;
      }
    });
  }

  Future<void> _completeAuthenticatedSession(
    Map<String, dynamic> res, {
    required bool forceDeviceSetup,
  }) async {
    authenticated = true;
    pendingEmailVerification = null;
    final userMap = res['user'];
    if (userMap is Map) {
      final name = userMap['fullName']?.toString().trim();
      final email = userMap['email']?.toString().trim();
      if (name != null && name.isNotEmpty) fullName = name;
      if (email != null && email.isNotEmpty) userEmail = email;
      authProvider = userMap['authProvider']?.toString() ?? authProvider;
      hasPassword = userMap['hasPassword'] == true;
      emailVerified = userMap['emailVerified'] == true;
      profileCompleted = userMap['profileCompleted'] == true;
      final code = userMap['referralCode']?.toString().trim();
      if (code != null && code.isNotEmpty) referralCode = code;
      preferredGlucoseUnit =
          userMap['preferredGlucoseUnit']?.toString() ?? preferredGlucoseUnit;
    } else {
      emailVerified = true;
    }
    await _syncDeviceStateAfterAuth(forceSetup: forceDeviceSetup);
    _bumpSession();
    notifyListeners();
    unawaited(loadUserProfile());
    unawaited(_hydrateSecondary());
  }

  Future<void> verifyEmailCode(String email, String code) async {
    await _run(() async {
      final res = await api.verifyEmail(email: email.trim(), code: code.trim());
      await _completeAuthenticatedSession(res, forceDeviceSetup: true);
    });
  }

  Future<void> resendEmailVerificationCode(String email) async {
    await api.resendEmailVerification(email.trim());
  }

  void beginEmailVerification(String email) {
    pendingEmailVerification = email.trim().toLowerCase();
    authenticated = false;
    emailVerified = false;
    _bumpSession();
    notifyListeners();
  }

  void cancelEmailVerification() {
    pendingEmailVerification = null;
    _bumpSession();
    notifyListeners();
  }

  Future<void> googleLogin({
    required String idToken,
    String? fullName,
    String? email,
    String? photoUrl,
  }) async {
    await _run(() async {
      final res = await api.socialLogin(
        provider: 'Google',
        idToken: idToken,
        fullName: fullName,
      );
      authenticated = true;
      if (fullName != null && fullName.isNotEmpty) {
        this.fullName = fullName;
      }
      if (email != null && email.isNotEmpty) {
        userEmail = email;
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        profilePictureUrl = photoUrl;
      }
      final userMap = res['user'];
      var isNewSocialUser = false;
      if (userMap is Map) {
        final accountName = userMap['fullName']?.toString().trim();
        final accountEmail = userMap['email']?.toString().trim();
        if (accountName != null && accountName.isNotEmpty) {
          this.fullName = accountName;
        }
        if (accountEmail != null && accountEmail.isNotEmpty) {
          userEmail = accountEmail;
        }
        final code = userMap['referralCode']?.toString().trim();
        if (code != null && code.isNotEmpty) {
          referralCode = code;
        }
        profileCompleted = userMap['profileCompleted'] == true;
        isNewSocialUser = userMap['profileCompleted'] != true;
      }
      emailVerified = true;
      pendingEmailVerification = null;
      if (userMap is Map && userMap['profileCompleted'] == true) {
        profileCompleted = true;
      }
      await _syncDeviceStateAfterAuth(forceSetup: isNewSocialUser);
      _bumpSession();
      notifyListeners();
      await loadUserProfile();
      unawaited(_hydrateSecondary());
    });
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? phone,
    String? dob,
    String? selectedGender,
  }) async {
    await _run(() async {
      final res = await api.register(
        name.trim(),
        email.trim(),
        password,
        phoneNumber: phone,
        dateOfBirth: dob,
        gender: selectedGender,
      );
      fullName = name;
      userEmail = email.trim().toLowerCase();
      authProvider = 'Email';
      hasPassword = true;
      phoneNumber = phone ?? '';
      dateOfBirth = dob ?? '';
      gender = selectedGender ?? '';
      profileCompleted = false;
      emailVerified = false;

      final requiresVerification = res['requiresEmailVerification'] == true ||
          res['accessToken'] == null ||
          '${res['accessToken']}'.isEmpty;
      if (requiresVerification) {
        pendingEmailVerification =
            (res['email']?.toString() ?? email).trim().toLowerCase();
        authenticated = false;
        _bumpSession();
        notifyListeners();
        return;
      }

      await _completeAuthenticatedSession(res, forceDeviceSetup: true);
    });
  }

  Future<void> forgotPassword(String email) async {
    await _run(() async {
      await api.forgotPassword(email.trim());
    });
  }

  Future<String?> verifyResetCode(String email, String code) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.verifyResetCode(
        email: email.trim(),
        code: code.trim(),
      );
      return res['resetToken'] as String?;
    } catch (e) {
      error = '$e';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _run(() async {
      await api.resetPassword(
        email: email.trim(),
        token: token.trim(),
        newPassword: newPassword,
      );
    });
  }

  Future<void> changePassword(
    String? currentPassword,
    String newPassword,
  ) async {
    await _run(() async {
      await api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      hasPassword = true;
    });
  }

  Future<void> deleteAccount() async {
    await _run(() async {
      await api.deleteAccount();
      authenticated = false;
      wear = null;
      history = [];
      latest = null;
      _bumpSession();
    });
  }

  Future<void> logout() async {
    await _run(() async {
      await api.logout();
      authenticated = false;
      pendingEmailVerification = null;
      emailVerified = false;
      profileCompleted = false;
      wear = null;
      history = [];
      latest = null;
      deviceStatus = null;
      activeSensor = null;
      activeDevice = null;
      _binding = null;
      alerts = [];
      alertsHasMore = false;
      alertsPage = 1;
      family = null;
      familyMembers = [];
      await _clearDeviceSetupSkipped();
      await _clearUploadQueue();
      await api.clearBackendBinding();
      try {
        await CgmSdk.unbind();
      } catch (_) {}
      _bumpSession();
      _bumpTelemetry();
    });
  }

  Future<void> loadFamily() async {
    try {
      family = await api.getFamily();
      if (family != null) {
        final code = (family!['referralCode'] ?? family!['ReferralCode'])
            ?.toString()
            .trim();
        if (code != null && code.isNotEmpty) {
          referralCode = code;
        }
      }
      familyMembers = await api.getFamilyMembers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> createFamily() async {
    await _run(() async {
      await api.createFamily();
      await loadFamily();
    });
  }

  Future<void> joinFamily(String inviteCode) async {
    await _run(() async {
      await api.joinFamily(inviteCode.trim());
      await loadFamily();
    });
  }

  Future<void> leaveFamily() async {
    await _run(() async {
      await api.leaveFamily();
      family = null;
      familyMembers = [];
      notifyListeners();
    });
  }

  Future<void> updateFamilyThresholds({
    double? lowThreshold,
    double? highThreshold,
  }) async {
    await _run(() async {
      await api.updateFamilyThresholds(
        lowThreshold: lowThreshold,
        highThreshold: highThreshold,
      );
      await loadFamily();
    });
  }

  Future<void> setFamilyMemberAlerts(
    int memberUserId,
    bool receiveAlerts,
  ) async {
    await _run(() async {
      await api.setFamilyMemberAlerts(
        memberUserId,
        receiveAlerts: receiveAlerts,
      );
      await loadFamily();
    });
  }

  Future<void> removeFamilyMember(int memberUserId) async {
    await _run(() async {
      await api.removeFamilyMember(memberUserId);
      await loadFamily();
    });
  }

  Future<Map<String, dynamic>> getFamilyMemberReport(int memberUserId) async {
    return await api.getFamilyMemberReport(memberUserId);
  }

  Future<void> deleteFamily() async {
    await _run(() async {
      await api.deleteFamily();
      family = null;
      familyMembers = [];
      notifyListeners();
    });
  }

  Future<void> loadReports({String? startDate, String? endDate}) async {
    try {
      detailedReport = await api.getDetailedReport(
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[AppController] Failed to load reports: $e');
    }
  }

  bool alertsHasMore = false;
  int alertsPage = 1;
  bool alertsLoadingMore = false;

  Future<void> loadAlerts({
    String? severity,
    String? alertType,
    int page = 1,
    int pageSize = 25,
    bool append = false,
  }) async {
    if (append) {
      if (alertsLoadingMore || !alertsHasMore) return;
      alertsLoadingMore = true;
      notifyListeners();
    }
    try {
      final pageData = await api.getAlertsPage(
        severity: severity,
        alertType: alertType,
        page: page,
        pageSize: pageSize,
      );
      final rawItems = pageData['items'];
      final fetchedAlerts = rawItems is List ? List<dynamic>.from(rawItems) : <dynamic>[];

      if (!append && alerts.isNotEmpty && fetchedAlerts.isNotEmpty) {
        final existingIds = alerts
            .map((a) => (a['Id'] ?? a['id'])?.toString())
            .whereType<String>()
            .toSet();

        for (final item in fetchedAlerts) {
          if (item is! Map) continue;
          final idStr = (item['Id'] ?? item['id'])?.toString();
          final isRead = item['isRead'] == 1 || item['isRead'] == true;
          if (idStr != null &&
              !existingIds.contains(idStr) &&
              !_notifiedAlertIds.contains(idStr) &&
              !isRead) {
            _notifiedAlertIds.add(idStr);
            final title =
                item['title'] ?? item['Title'] ?? 'Glucose Notification';
            final body =
                item['message'] ??
                item['Message'] ??
                'New glucose alert received';
            unawaited(
              NotificationService.instance.showLocalAlert(
                title: title.toString(),
                body: body.toString(),
                payload: 'alert:$idStr',
              ),
            );
          }
        }
      } else if (!append && fetchedAlerts.isNotEmpty) {
        for (final item in fetchedAlerts) {
          if (item is! Map) continue;
          final idStr = (item['Id'] ?? item['id'])?.toString();
          if (idStr != null) {
            _notifiedAlertIds.add(idStr);
          }
        }
      }

      final filtered = fetchedAlerts.where((item) {
        if (item is! Map) return false;
        final clearedAt = _alertsClearedAt;
        if (clearedAt == null) return true;
        final raw = item['timestamp'] ?? item['AlertTime'] ?? item['alertTime'];
        final when = DateTime.tryParse('$raw');
        if (when == null) return false;
        return when.toUtc().isAfter(clearedAt);
      }).toList();

      final wellnessReminders = await WellnessReminderLog.list(
        clearedAt: _alertsClearedAt,
      );

      if (append) {
        final existingIds = alerts
            .map((a) => (a['Id'] ?? a['id'])?.toString())
            .whereType<String>()
            .toSet();
        for (final item in filtered) {
          final idStr = (item['Id'] ?? item['id'])?.toString();
          if (idStr == null || existingIds.add(idStr)) {
            alerts.add(item);
          }
        }
      } else {
        final merged = <dynamic>[
          ..._localGlucoseAlerts,
          ...wellnessReminders,
          ...filtered,
        ];
        final seen = <String>{};
        alerts = [
          for (final item in merged)
            if (item is Map &&
                seen.add('${item['id'] ?? item['Id'] ?? Object().hashCode}'))
              item,
        ];
      }
      alertsPage = page;
      alertsHasMore = pageData['hasMore'] == true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppController] Failed to load alerts: $e');
    } finally {
      if (append) {
        alertsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendTestLocalNotification() async {
    await NotificationService.instance.showLocalAlert(
      title: 'CGM Test Alert',
      body: 'Your notification alerts are working properly!',
      payload: 'test:notification',
    );
  }

  Future<void> clearAlertHistory() async {
    try {
      await api.clearAlertHistory();
    } catch (e) {
      debugPrint('[AppController] Clear alert history API failed: $e');
    }
    final clearedAt = DateTime.now().toUtc();
    _alertsClearedAt = clearedAt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alerts_cleared_at', clearedAt.toIso8601String());
    alerts = [];
    _localGlucoseAlerts.clear();
    alertsHasMore = false;
    alertsPage = 1;
    await WellnessReminderLog.clear();
    notifyListeners();
  }

  Future<void> markAlertAsRead(int alertId) async {
    try {
      await api.markAlertRead(alertId);
      await loadAlerts();
    } catch (e) {
      debugPrint('[AppController] Failed to mark alert $alertId read: $e');
    }
  }

  Future<void> requestPermissions() async {
    final permissions = <Permission>[
      if (Platform.isAndroid) ...[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.notification,
      ] else if (Platform.isIOS)
        Permission.bluetooth,
      Permission.camera,
    ];
    final result = await permissions.request();
    if (result.values.any((x) => x.isPermanentlyDenied)) {
      throw const ApiException(
        'A required permission is permanently denied. Open system settings.',
      );
    }
    if (result.values.any((x) => x.isDenied)) {
      throw const ApiException(
        'Bluetooth, notification, and camera permissions are required.',
      );
    }
  }

  Future<void> scan() async {
    await _run(() async {
      await requestPermissions();
      if (!sdkReady) {
        await CgmSdk.init(
          config: const SdkConfig(
            logLevel: LogLevel.info,
            foregroundNotice: 'Circle glucose monitoring is active',
            minBatteryMv: 2800,
            warmupMinutes: AppConfig.sensorWarmupMinutes,
          ),
        );
        sdkReady = true;
      }
      scanResults = [];
      notifyListeners();
      await for (final device in CgmSdk.scan(timeoutSeconds: 10)) {
        if (!scanResults.any((x) => x.deviceId == device.deviceId)) {
          scanResults = [...scanResults, device];
          notifyListeners();
        }
      }
    });
  }

  Future<void> bindQr(String rawQr) async {
    await _run(() async {
      await requestPermissions();
      if (!sdkReady) {
        await CgmSdk.init(
          config: const SdkConfig(
            logLevel: LogLevel.info,
            foregroundNotice: 'Circle glucose monitoring is active',
            minBatteryMv: 2800,
            warmupMinutes: AppConfig.sensorWarmupMinutes,
          ),
        );
        sdkReady = true;
      }
      final qr = CgmSdk.parseQrCode(rawQr.trim());
      final calibration =
          qr.calibration ??
          const AlgoParams(tempCoef1: 2.8632, tempCoef2: -0.04);
      final transmitterSn = qr.transmitterSn ?? qr.deviceId;
      final sensorSn = qr.sensorSn ?? qr.deviceId;
      try {
        wear = await CgmSdk.bind(
          deviceId: qr.deviceId,
          form: qr.form,
          calibration: calibration,
          expireDate: qr.expireDate,
          transmitterSn: transmitterSn,
          sensorSn: sensorSn,
          beforeActivate: (check) async {
            try {
              _binding = await api.activateDevice(
                deviceSerial: transmitterSn,
                sensorSerial: sensorSn,
                form: qr.form,
                bluetoothName: check.bluetoothAddr,
                batteryMv: deviceStatus?.batteryMv,
              );
              return BeforeActivateResult.proceed(wearId: _binding!.sensorId);
            } catch (e) {
              return BeforeActivateResult.abort('$e');
            }
          },
        );
      } catch (e) {
        // Debug-only simulator fallback. Never activate a cloud sensor in
        // release without a verified BLE bind.
        if (!kDebugMode) rethrow;
        _binding = await api.activateDevice(
          deviceSerial: transmitterSn,
          sensorSerial: sensorSn,
          form: qr.form,
          bluetoothName: qr.deviceId,
          batteryMv: 3000,
        );
      }
      await loadActiveDeviceAndSensor();
      await refreshHistory();
      await _clearDeviceSetupSkipped();
      _bumpSession();
    });
  }

  Future<void> unbind() async {
    await _run(() async {
      final current = await CgmSdk.currentWear();
      if (current == null) return;
      await api.deactivateDevice();
      await CgmSdk.unbind();
      wear = null;
      latest = null;
      deviceStatus = null;
      activeSensor = null;
      activeDevice = null;
      history = [];
      await _persistWarmupDeadline(null);
      _bumpSession();
      _bumpTelemetry();
    });
  }

  Future<void> refreshHistory() async {
    if (!sdkReady) return;
    history = await CgmSdk.query(
      from: DateTime.now().subtract(const Duration(hours: 6)),
      limit: _maxUiHistory,
    );
    _trimHistory();
    final queried = history.isEmpty ? await CgmSdk.latest() : history.last;
    final liveFresh = lastLiveAt != null &&
        DateTime.now().difference(lastLiveAt!) < const Duration(minutes: 10);
    if (!liveFresh) {
      latest = queried;
    }
    // History screen reads the DB; Home must too or Live looks empty after restart.
    await hydrateRecentGlucoseFromServer();
    _bumpTelemetry();
    // Flush any pending offline samples to server once connectivity is present
    if (history.isNotEmpty) {
      unawaited(_upload(history));
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  DateTime? _lastUiNotifyAt;
  DateTime? _lastProgressNotifyAt;
  Timer? _uiNotifyTimer;
  static const _uiNotifyMinInterval = Duration(milliseconds: 1500);
  /// Short local window for live UI (~2GB RAM). Longer ranges use
  /// paginated `GET /api/Glucose/history`.
  static const _maxUiHistory = 180;

  /// Map a server history row (mg/dL) into an SDK sample (mmol/L).
  static GlucoseSample? sampleFromServerRow(Map<String, dynamic> row) {
    final atRaw = row['measurementTime'] ?? row['MeasurementTime'];
    // API/MySQL times are UTC; show on device region clock.
    final at = DeviceTime.parseApi(atRaw);
    if (at == null) return null;
    final mgRaw = row['glucoseValue'] ?? row['GlucoseValue'];
    final mg = mgRaw == null ? null : (mgRaw as num).toDouble();
    return GlucoseSample(
      wearId: (row['sensorId'] as num?)?.toInt() ??
          (row['SensorId'] as num?)?.toInt() ??
          0,
      seq: (row['sequenceNumber'] as num?)?.toInt() ??
          (row['SequenceNumber'] as num?)?.toInt() ??
          0,
      measuredAt: at,
      value: mg == null ? null : mg / 18.0182,
      warmup: false,
      abnormal: mg == null,
      source: 'server',
      temperature: (row['deviceTemperatureC'] as num?)?.toDouble() ??
          (row['DeviceTemperatureC'] as num?)?.toDouble(),
      voltage: (row['batteryVoltageMv'] as num?)?.toDouble() ??
          (row['BatteryVoltageMv'] as num?)?.toDouble(),
    );
  }

  Future<Map<String, dynamic>> fetchGlucoseHistoryPage({
    required DateTime startUtc,
    required DateTime endUtc,
    int page = 1,
    int pageSize = 100,
    int? sensorId,
    double? minMg,
    double? maxMg,
  }) {
    return api.getGlucoseHistory(
      page: page,
      pageSize: pageSize,
      sensorId: sensorId,
      startUtc: startUtc.toUtc().toIso8601String(),
      endUtc: endUtc.toUtc().toIso8601String(),
      minMg: minMg,
      maxMg: maxMg,
    );
  }

  Future<Map<String, dynamic>> fetchGlucoseSummary({
    required DateTime startUtc,
    required DateTime endUtc,
    int? sensorId,
  }) {
    return api.getGlucoseSummary(
      sensorId: sensorId,
      startUtc: startUtc.toUtc().toIso8601String(),
      endUtc: endUtc.toUtc().toIso8601String(),
    );
  }

  void _notifyUiThrottled({bool force = false}) {
    final now = DateTime.now();
    if (force) {
      _uiNotifyTimer?.cancel();
      _uiNotifyTimer = null;
      _lastUiNotifyAt = now;
      _bumpTelemetry();
      return;
    }
    if (_lastUiNotifyAt == null ||
        now.difference(_lastUiNotifyAt!) >= _uiNotifyMinInterval) {
      _uiNotifyTimer?.cancel();
      _uiNotifyTimer = null;
      _lastUiNotifyAt = now;
      _bumpTelemetry();
      return;
    }
    // Trailing edge: flush the latest state after the quiet window.
    _uiNotifyTimer ??= Timer(
      _uiNotifyMinInterval - now.difference(_lastUiNotifyAt!),
      () {
        _uiNotifyTimer = null;
        _lastUiNotifyAt = DateTime.now();
        _bumpTelemetry();
      },
    );
  }

  void _trimHistory() {
    if (history.length <= _maxUiHistory) return;
    history = history.sublist(history.length - _maxUiHistory);
  }

  /// Append samples without rebuilding/sorting the full list on every tick.
  /// Same wearId+seq replaces the existing row so corrected live values stick.
  void _appendHistory(Iterable<GlucoseSample> samples) {
    for (final sample in samples) {
      final start = history.length > 64 ? history.length - 64 : 0;
      var replaced = false;
      for (var i = start; i < history.length; i++) {
        final existing = history[i];
        if (existing.wearId == sample.wearId && existing.seq == sample.seq) {
          history[i] = sample;
          replaced = true;
          break;
        }
      }
      if (replaced) continue;
      if (history.isEmpty ||
          !sample.measuredAt.isBefore(history.last.measuredAt)) {
        history.add(sample);
      } else {
        history.add(sample);
        history.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      }
    }
    _trimHistory();
  }

  /// True live BLE frame (not Excel-fill / backfill / replay), and not stale.
  /// Uses backend warmup clock — SDK `sample.warmup` can stay true after the
  /// 2h deadline and was blocking Home Live + DB uploads.
  bool _isFreshLiveSample(GlucoseSample sample) {
    if (sample.value == null || sample.abnormal) return false;
    if (sample.warmup && isSensorWarming) return false;
    final source = sample.source.toLowerCase();
    if (source == 'backfill' || source == 'replay') return false;
    final age = DateTime.now().difference(sample.measuredAt.toLocal()).abs();
    return age <= _liveFreshWindow;
  }

  /// Pull recent server rows (same source as History) into the Home buffer.
  Future<void> hydrateRecentGlucoseFromServer({int hours = 6}) async {
    if (!authenticated) return;
    try {
      final page = await api.getGlucoseHistory(
        hours: hours,
        page: 1,
        pageSize: _maxUiHistory,
      );
      final rawItems = page['items'];
      if (rawItems is! List || rawItems.isEmpty) return;
      final mapped = <GlucoseSample>[];
      for (final row in rawItems) {
        if (row is! Map) continue;
        final sample = sampleFromServerRow(Map<String, dynamic>.from(row));
        if (sample != null && sample.value != null) mapped.add(sample);
      }
      if (mapped.isEmpty) return;
      mapped.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      _appendHistory(mapped);
      final newest = mapped.last;
      _setLatestIfNewer(newest, fromLive: false);
      _bumpTelemetry();
    } catch (e) {
      debugPrint('[GLUCOSE] Home server hydrate failed: $e');
    }
  }

  void _setLatestIfNewer(GlucoseSample? sample, {bool fromLive = false}) {
    if (sample == null || sample.value == null) return;
    if (fromLive) {
      // Excel pocket-fill also arrives on the glucose stream — do not treat as Live.
      if (!_isFreshLiveSample(sample)) return;
      latest = sample;
      lastLiveAt = DateTime.now();
      return;
    }
    final liveFresh = lastLiveAt != null &&
        DateTime.now().difference(lastLiveAt!) < _liveFreshWindow;
    if (liveFresh) return;
    if (_isFreshLiveSample(sample)) {
      latest = sample;
      return;
    }
    final current = latest;
    if (current == null || current.value == null) {
      latest = sample;
      return;
    }
    if (sample.wearId == current.wearId && sample.seq < current.seq) return;
    if (sample.seq > current.seq ||
        !sample.measuredAt.isBefore(current.measuredAt)) {
      latest = sample;
    }
  }

  /// Device-region clock for Home "Last reading at".
  DateTime? get lastReadingDisplayAt {
    final sample = latest;
    if (sample != null && _isFreshLiveSample(sample)) {
      // Prefer sensor UTC→local so it matches History / DB PakistanTime.
      return sample.measuredAt.toLocal();
    }
    return sample?.measuredAt.toLocal() ?? lastLiveAt?.toLocal();
  }

  void _attachSdkStreams() {
    _connectionSub ??= CgmSdk.connectionState.listen((value) {
      final previous = connection;
      connection = value;
      _bumpTelemetry();
      if (value == CgmConnectionState.connected) {
        unawaited(flushPendingUploads());
      }
      if (sensorAlerts &&
          previous == CgmConnectionState.connected &&
          value != CgmConnectionState.connected) {
        unawaited(
          NotificationService.instance.showLocalAlert(
            title: 'Sensor disconnected',
            body: 'Circle lost the CGM connection. Open the app to reconnect.',
            payload: 'sensor:disconnected',
          ),
        );
      }
    });
    _statusSub ??= CgmSdk.deviceStatus.listen((value) {
      deviceStatus = value;
      _notifyUiThrottled();
    });
    _progressSub ??= CgmSdk.progress.listen((value) {
      progressText = '${value.kind}: ${value.done}/${value.total}';
      final done = value.done >= value.total;
      final now = DateTime.now();
      if (done ||
          _lastProgressNotifyAt == null ||
          now.difference(_lastProgressNotifyAt!) >=
              const Duration(seconds: 1)) {
        _lastProgressNotifyAt = now;
        _notifyUiThrottled(force: done);
      }
    });
    _errorSub ??= CgmSdk.error.listen((value) {
      error = '${value.code}: ${value.message}';
      notifyListeners();
    });
    _watchSub ??=
        CgmSdk.watch(
          from: DateTime.now().subtract(const Duration(hours: 6)),
        ).listen((samples) async {
          if (samples.isEmpty) return;
          _appendHistory(samples);
          final newest = history.isEmpty ? null : history.last;
          _setLatestIfNewer(newest, fromLive: false);
          _notifyUiThrottled();
          await _upload(samples, fromLive: false);
        });
    _glucoseSub ??= CgmSdk.glucose.listen((sample) {
      _setLatestIfNewer(sample, fromLive: true);
      _appendHistory([sample]);
      _notifyUiThrottled();
      unawaited(_maybeLocalGlucoseAlert(sample));
      // Live glucose samples arrive on this stream independently of the
      // historical/watch stream. Upload them immediately so a live reading
      // cannot remain visible only on the device.
      unawaited(_upload([sample], fromLive: true));
    });
  }

  Future<void> _maybeLocalGlucoseAlert(GlucoseSample sample) async {
    if (!criticalAlerts) return;
    if (sample.value == null || sample.warmup || sample.abnormal) return;
    final mgdl = sample.value! * 18.0182;
    String? type;
    String? title;
    if (mgdl <= urgentLowThreshold) {
      type = 'UrgentLow';
      title = 'Critical urgent low glucose';
    } else if (mgdl >= urgentHighThreshold) {
      type = 'UrgentHigh';
      title = 'Critical urgent high glucose';
    } else {
      return;
    }
    final now = DateTime.now();
    if (_lastLocalAlertType == type &&
        _lastLocalAlertAt != null &&
        now.difference(_lastLocalAlertAt!) < const Duration(minutes: 10)) {
      return;
    }
    _lastLocalAlertType = type;
    _lastLocalAlertAt = now;
    final body = '${mgdl.toStringAsFixed(0)} mg/dL is outside your urgent range.';
    await NotificationService.instance.showLocalAlert(
      title: title!,
      body: body,
      payload: 'glucose:$type',
    );
    _localGlucoseAlerts.insert(0, {
      'id': 'glucose:$type:${now.millisecondsSinceEpoch}',
      'title': title,
      'message': body,
      'severity': 'critical',
      'timestamp': now.toIso8601String(),
      'isRead': false,
    });
    alerts = [..._localGlucoseAlerts, ...alerts.where((item) => '${item['id'] ?? ''}'.startsWith('glucose:') == false)];
    notifyListeners();
  }

  Future<BackendBinding?> _ensureBinding(WearInfo wear) async {
    final existing = _binding ?? await api.storedBinding();
    if (existing != null) {
      _binding = existing;
      return existing;
    }
    try {
      _binding = await api.activateDevice(
        deviceSerial: wear.transmitterSn ?? wear.deviceId,
        sensorSerial: wear.sensorSn ?? wear.deviceId,
        form: wear.form,
        bluetoothName: wear.bleId,
        batteryMv: deviceStatus?.batteryMv,
      );
      return _binding;
    } catch (e) {
      debugPrint('[GLUCOSE-UPLOAD] binding failed: $e');
      return null;
    }
  }

  /// Same conversion Home Live uses: SDK mmol/L → mg/dL.
  static double? displayMgDl(GlucoseSample sample) {
    final raw = sample.value;
    if (raw == null) return null;
    final mg = raw > 30 ? raw : raw * 18.0182;
    if (mg < 20 || mg > 600) return null;
    return double.parse(mg.toStringAsFixed(1));
  }

  Future<void> _upload(
    List<GlucoseSample> samples, {
    bool fromLive = false,
  }) async {
    if (!authenticated) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: not authenticated');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final currentWear = wear ?? await CgmSdk.currentWear();
    if (currentWear == null) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: no current wear');
      return;
    }
    final binding = await _ensureBinding(currentWear);
    if (binding == null) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: no backend sensor binding');
      return;
    }
    final key = 'uploaded_seq_${currentWear.wearId}';
    final lastSeq = prefs.getInt(key) ?? -1;
    // Fresh Home-Live frames: POST immediately (bypass lastSeq / Excel-fill cursor).
    if (fromLive) {
      final live = samples
          .where((x) => x.wearId == currentWear.wearId && _isFreshLiveSample(x))
          .toList();
      for (final sample in live) {
        final mg = displayMgDl(sample);
        if (mg == null) continue;
        final measurementTime = _exactMeasurementTimeUtc(sample);
        final receivedAt = DateTime.now().toUtc().toIso8601String();
        debugPrint(
          '[GLUCOSE-LIVE] seq=${sample.seq} mg=$mg time=$measurementTime '
          'source=${sample.source}',
        );
        try {
          await api.saveMeasurement(
            sensorId: binding.sensorId,
            glucoseValue: mg,
            measurementTime: measurementTime,
            sequenceNumber: sample.seq & 0xffff,
            we1CurrentNa: sample.rawCurrent,
            deviceTemperatureC: sample.temperature,
            batteryVoltageMv: sample.voltage?.round(),
            receivedAt: receivedAt,
            source: 'live',
          );
          // Never rewind lastSeq when Excel-fill used a higher cursor (e.g. 512)
          // and real 0xB0 resumes at a lower seq (e.g. 134).
          final seq = sample.seq & 0xffff;
          if (seq > lastSeq) await prefs.setInt(key, seq);
          continue;
        } catch (e) {
          debugPrint('[GLUCOSE-LIVE] direct save failed, queueing: $e');
          await _enqueueUploadRows(binding.sensorId, [sample]);
        }
      }
      // Non-fresh frames on the glucose stream (Excel fill) still go to the queue.
      final fill = samples
          .where(
            (x) =>
                x.wearId == currentWear.wearId &&
                x.value != null &&
                !x.abnormal &&
                (!x.warmup || !isSensorWarming) &&
                !_isFreshLiveSample(x),
          )
          .toList();
      if (fill.isNotEmpty) {
        await _enqueueUploadRows(binding.sensorId, fill);
        final highest = fill
            .map((s) => s.seq & 0xffff)
            .fold<int>(lastSeq, (a, b) => b > a ? b : a);
        if (highest > lastSeq) await prefs.setInt(key, highest);
      }
      return;
    }

    final pending =
        samples
            .where(
              (x) => x.wearId == currentWear.wearId && x.seq > lastSeq,
            )
            .toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    debugPrint(
      '[GLUCOSE-UPLOAD] wear=${currentWear.wearId} sensor=${binding.sensorId} '
      'input=${samples.length} pending=${pending.length} lastSeq=$lastSeq',
    );
    for (var offset = 0; offset < pending.length; offset += 500) {
      final batch = pending.skip(offset).take(500).toList();
      for (final sample in batch) {
        final mg = displayMgDl(sample);
        debugPrint(
          '[CGM SAMPLE] seq=${sample.seq} '
          'warmup=${sample.warmup} '
          'abnormal=${sample.abnormal} '
          'value=${sample.value} mg=$mg source=${sample.source}',
        );
      }
      final valid = batch
          .where(
            (x) =>
                x.value != null &&
                !x.abnormal &&
                // Upload once backend warmup ended even if SDK still flags warmup.
                (!x.warmup || !isSensorWarming),
          )
          .toList();
      debugPrint(
        '[GLUCOSE-UPLOAD] batch=${batch.length} valid=${valid.length} '
        'firstSeq=${batch.first.seq} lastSeq=${batch.last.seq} '
        'uploadAttempted=${valid.isNotEmpty}',
      );
      if (valid.isEmpty) {
        debugPrint(
          '[CGM SYNC] No valid readings; uploaded sequence unchanged.',
        );
        continue;
      }
      try {
        await _enqueueUploadRows(binding.sensorId, valid);
        // Never decrease lastSeq (Excel-fill high seq vs real low seq).
        final highest = valid
            .map((s) => s.seq & 0xffff)
            .fold<int>(lastSeq, (a, b) => b > a ? b : a);
        if (highest > lastSeq) await prefs.setInt(key, highest);
      } catch (_) {
        break;
      }
    }
  }

  /// Sensor clock → UTC ISO-8601 at the exact second (no fake milliseconds).
  String _exactMeasurementTimeUtc(GlucoseSample sample) {
    final utc = sample.measuredAt.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    ).toIso8601String();
  }

  Future<void> _enqueueUploadRows(
    int sensorId,
    List<GlucoseSample> samples,
  ) async {
    // Serialize queue writes — concurrent live ticks were each writing
    // queued=1 and dropping the other sequences before flush.
    final previous = _uploadEnqueueChain;
    final gate = Completer<void>();
    _uploadEnqueueChain = gate.future;
    try {
      if (previous != null) await previous;
      final existing = await _readUploadQueue();
      final bySeq = <String, int>{};
      for (var i = 0; i < existing.length; i++) {
        final row = existing[i];
        bySeq['${row['sensorId']}:${row['sequenceNumber']}'] = i;
      }
      final receivedAt = DateTime.now().toUtc().toIso8601String();
      for (final sample in samples) {
        final mg = displayMgDl(sample);
        if (mg == null) {
          if (kDebugMode) {
            debugPrint(
              '[GLUCOSE-UPLOAD] skip seq=${sample.seq} value=${sample.value}',
            );
          }
          continue;
        }
        final measurementTime = _exactMeasurementTimeUtc(sample);
        final seq = sample.seq & 0xffff;
        final seqKey = '$sensorId:$seq';
        final freshLive = _isFreshLiveSample(sample);
        final row = <String, dynamic>{
          'sensorId': sensorId,
          // Exact same mg/dL Home Live shows (rounded to 0.1).
          'glucoseValue': mg,
          'measurementTime': measurementTime,
          'receivedAt': receivedAt,
          'source': freshLive ? 'live' : sample.source,
          if (sample.voltage != null)
            'batteryVoltageMv': sample.voltage!.round(),
          if (sample.temperature != null)
            'deviceTemperatureC': sample.temperature,
          if (sample.rawCurrent != null) 'we1CurrentNa': sample.rawCurrent,
          'sequenceNumber': seq,
        };
        final existingIndex = bySeq[seqKey];
        if (existingIndex != null) {
          existing[existingIndex] = row;
        } else {
          bySeq[seqKey] = existing.length;
          existing.add(row);
        }
      }
      await _writeUploadQueue(existing);
      if (kDebugMode) {
        debugPrint('[GLUCOSE-UPLOAD] queued=${existing.length}');
      }
    } finally {
      gate.complete();
    }
    unawaited(flushPendingUploads());
  }

  Future<void> _flushUploadQueue() async {
    // Network sync must not depend on BLE — offline readings should upload
    // as soon as internet returns, even if the sensor is temporarily off.
    if (_uploadQueueFlushing || !authenticated) return;
    _uploadQueueFlushing = true;
    try {
      var queued = await _readUploadQueue();
      if (queued.isEmpty) return;

      // Drop poison rows that can never succeed (bad value / missing fields).
      final before = queued.length;
      queued = queued.where((row) {
        final mg = (row['glucoseValue'] as num?)?.toDouble();
        final time = '${row['measurementTime'] ?? ''}';
        final sensorId = row['sensorId'];
        if (sensorId is! int && int.tryParse('$sensorId') == null) return false;
        if (mg == null || mg < 20 || mg > 600) return false;
        if (time.isEmpty || DateTime.tryParse(time) == null) return false;
        // Normalize mmol leftovers from older app builds.
        if (mg < 30) {
          row['glucoseValue'] =
              double.parse((mg * 18.0182).toStringAsFixed(1));
        }
        if (sensorId is! int) {
          row['sensorId'] = int.parse('$sensorId');
        }
        return true;
      }).toList();
      if (queued.length != before) {
        await _writeUploadQueue(queued);
        if (kDebugMode) {
          debugPrint(
            '[GLUCOSE-UPLOAD] dropped ${before - queued.length} invalid queued rows',
          );
        }
      }
      if (queued.isEmpty) return;

      final bySensor = <int, List<Map<String, dynamic>>>{};
      for (final row in queued) {
        bySensor.putIfAbsent(row['sensorId'] as int, () => []).add(row);
      }
      for (final entry in bySensor.entries) {
        // Smaller batches isolate failures and avoid huge 400 payloads.
        final rows = entry.value;
        for (var offset = 0; offset < rows.length; offset += 50) {
          final batch = rows.skip(offset).take(50).toList();
          try {
            await api.uploadGlucose(entry.key, batch);
            queued.removeWhere((row) => batch.contains(row));
            await _writeUploadQueue(queued);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                '[GLUCOSE-UPLOAD] batch fail sensor=${entry.key} '
                'size=${batch.length}: $e',
              );
            }
            // Try one-by-one so one bad timestamp does not block the rest.
            for (final row in batch) {
              try {
                await api.uploadGlucose(entry.key, [row]);
                queued.remove(row);
              } catch (rowError) {
                if (kDebugMode) {
                  debugPrint(
                    '[GLUCOSE-UPLOAD] drop poison row '
                    'time=${row['measurementTime']} value=${row['glucoseValue']}: '
                    '$rowError',
                  );
                }
                // Permanent client/server rejection — drop so the queue can drain.
                queued.remove(row);
              }
            }
            await _writeUploadQueue(queued);
          }
        }
      }
      if (queued.isNotEmpty) {
        _uploadQueueTimer ??= Timer(const Duration(minutes: 5), () {
          _uploadQueueTimer = null;
          unawaited(flushPendingUploads());
        });
      }
      if (queued.isEmpty) unawaited(loadAlerts(pageSize: 25));
    } catch (e) {
      // Keep remaining queue; retry when network/app resume fires.
      _uploadQueueTimer ??= Timer(const Duration(minutes: 5), () {
        _uploadQueueTimer = null;
        unawaited(flushPendingUploads());
      });
      if (kDebugMode) {
        debugPrint('[GLUCOSE-UPLOAD] queue flush failed; readings retained: $e');
      }
    } finally {
      _uploadQueueFlushing = false;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = '$e';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _uiNotifyTimer?.cancel();
    sessionRevision.dispose();
    telemetryRevision.dispose();
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _watchSub?.cancel();
    _progressSub?.cancel();
    _errorSub?.cancel();
    _glucoseSub?.cancel();
    super.dispose();
  }
}
