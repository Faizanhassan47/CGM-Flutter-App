import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController(this.api);
  final ApiService api;

  bool loading = true;
  bool authenticated = false;
  bool sdkReady = false;
  String? error;
  String sdkVersion = '';
  CgmConnectionState connection = CgmConnectionState.disconnected;
  DeviceStatus? deviceStatus;
  WearInfo? wear;
  GlucoseSample? latest;
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
  static const _uploadQueueKey = 'glucose_upload_queue_v1';

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      pushNotifications = prefs.getBool('pref_push') ?? true;
      criticalAlerts = prefs.getBool('pref_critical') ?? true;
      sensorAlerts = prefs.getBool('pref_sensor_alerts') ?? true;
      reportReminders = prefs.getBool('pref_reminders') ?? true;
      selectedDeviceType = prefs.getString('pref_device_type') ?? 'Disposable';

      authenticated = await api.restoreSession();
      if (authenticated) {
        await loadUserProfile();
        await loadFamily();
        await loadAlerts();
        await loadReports();
        await loadOvernightReport();
        await loadActiveDeviceAndSensor();
        unawaited(sendPhoneHardwareLogs());
        await NotificationService.instance.initialize(
          apiService: api,
          pushEnabled: pushNotifications,
        );
        await _restoreWellnessReminders();
      } else {
        unawaited(NotificationService.instance.initialize());
      }

      await CgmSdk.init(
        config: const SdkConfig(
          logLevel: LogLevel.info,
          foregroundNotice: 'Circle glucose monitoring is active',
          minBatteryMv: 2800,
          warmupMinutes: 5,
        ),
      );
      sdkVersion =
          '${await CgmSdk.version()} / ${await CgmSdk.algorithmVersion()}';
      sdkReady = true;
      wear = await CgmSdk.currentWear();
      _binding = await api.storedBinding();
      _attachSdkStreams();
      await refreshHistory();
    } catch (e) {
      error = 'SDK initialization failed: $e';
    } finally {
      loading = false;
      notifyListeners();
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
        profileCompleted = data['profileCompleted'] == true;
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
        final devices = await api.getDevices();
        if (devices.isNotEmpty) {
          activeDevice = devices.first as Map<String, dynamic>;
        }
      }
      notifyListeners();
    } catch (_) {}
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
    });
  }

  /// Uploads user profile picture and updates profilePictureUrl.
  Future<void> uploadProfilePicture(List<int> bytes, String filename) async {
    await _run(() async {
      final res = await api.uploadProfilePicture(bytes, filename);
      if (res['profilePictureUrl'] != null) {
        profilePictureUrl = res['profilePictureUrl'].toString();
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
      await api.login(username.trim(), password);
      authenticated = true;
      notifyListeners();
      // Load user profile and auxiliary data in parallel in the background
      unawaited(
        Future.wait([
          loadUserProfile(),
          loadFamily(),
          loadAlerts(),
          loadReports(),
          sendPhoneHardwareLogs(),
          NotificationService.instance.initialize(
            apiService: api,
            pushEnabled: pushNotifications,
          ),
        ]),
      );
    });
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
      if (userMap is Map<String, dynamic>) {
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
      }
      notifyListeners();
      // Load user profile immediately to determine profile completion and user data
      await loadUserProfile();
      // Load auxiliary data in parallel in the background
      unawaited(
        Future.wait([
          loadFamily(),
          loadAlerts(),
          loadReports(),
          sendPhoneHardwareLogs(),
          NotificationService.instance.initialize(
            apiService: api,
            pushEnabled: pushNotifications,
          ),
        ]),
      );
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
      authenticated = true;
      fullName = name;
      userEmail = email;
      authProvider = 'Email';
      hasPassword = true;
      phoneNumber = phone ?? '';
      dateOfBirth = dob ?? '';
      gender = selectedGender ?? '';
      final userMap = res['user'];
      if (userMap is Map<String, dynamic>) {
        final code = userMap['referralCode']?.toString().trim();
        if (code != null && code.isNotEmpty) {
          referralCode = code;
        }
      }
      notifyListeners();
      unawaited(loadUserProfile());
      unawaited(loadFamily());
      unawaited(sendPhoneHardwareLogs());
      unawaited(
        NotificationService.instance.initialize(
          apiService: api,
          pushEnabled: pushNotifications,
        ),
      );
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
    });
  }

  Future<void> logout() async {
    await _run(() async {
      await api.logout();
      authenticated = false;
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

  Future<void> loadAlerts() async {
    try {
      final fetchedAlerts = await api.getAlerts();

      if (alerts.isNotEmpty && fetchedAlerts.isNotEmpty) {
        final existingIds = alerts
            .map((a) => (a['Id'] ?? a['id'])?.toString())
            .whereType<String>()
            .toSet();

        for (final item in fetchedAlerts) {
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
      } else if (fetchedAlerts.isNotEmpty) {
        // Pre-populate already existing alert IDs on first boot so we don't spam notifications
        for (final item in fetchedAlerts) {
          final idStr = (item['Id'] ?? item['id'])?.toString();
          if (idStr != null) {
            _notifiedAlertIds.add(idStr);
          }
        }
      }

      alerts = fetchedAlerts;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppController] Failed to load alerts: $e');
    }
  }

  Future<void> sendTestLocalNotification() async {
    await NotificationService.instance.showLocalAlert(
      title: 'CGM Test Alert',
      body: 'Your notification alerts are working properly!',
      payload: 'test:notification',
    );
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
            warmupMinutes: 5,
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
            warmupMinutes: 5,
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
        // Fallback for BLE Simulators (PC WinRT Bluetooth / software emulators):
        // Directly activate on backend so telemetry and live charts work seamlessly!
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
    });
  }

  Future<void> refreshHistory() async {
    if (!sdkReady) return;
    history = await CgmSdk.query(
      from: DateTime.now().subtract(const Duration(days: 14)),
      limit: 25000,
    );
    latest = history.isEmpty ? await CgmSdk.latest() : history.last;
    notifyListeners();
    // Flush any pending offline samples to server once connectivity is present
    if (history.isNotEmpty) {
      unawaited(_upload(history));
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _attachSdkStreams() {
    _connectionSub ??= CgmSdk.connectionState.listen((value) {
      final previous = connection;
      connection = value;
      notifyListeners();
      if (value == CgmConnectionState.connected) {
        unawaited(_flushUploadQueue());
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
      notifyListeners();
    });
    _progressSub ??= CgmSdk.progress.listen((value) {
      progressText = '${value.kind}: ${value.done}/${value.total}';
      notifyListeners();
    });
    _errorSub ??= CgmSdk.error.listen((value) {
      error = '${value.code}: ${value.message}';
      notifyListeners();
    });
    _watchSub ??=
        CgmSdk.watch(
          from: DateTime.now().subtract(const Duration(days: 15)),
        ).listen((samples) async {
          if (samples.isEmpty) return;
          history = [...history, ...samples]
            ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
          final unique = <String, GlucoseSample>{
            for (final sample in history)
              '${sample.wearId}:${sample.seq}': sample,
          };
          history = unique.values.toList()
            ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
          latest = history.last;
          notifyListeners();
          await _upload(samples);
        });
    _glucoseSub ??= CgmSdk.glucose.listen((sample) {
      latest = sample;
      if (!history.any(
        (x) => x.wearId == sample.wearId && x.seq == sample.seq,
      )) {
        history = [...history, sample]
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      }
      notifyListeners();
      unawaited(_maybeLocalGlucoseAlert(sample));
      // Live glucose samples arrive on this stream independently of the
      // historical/watch stream. Upload them immediately so a live reading
      // cannot remain visible only on the device.
      unawaited(_upload([sample]));
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
    await NotificationService.instance.showLocalAlert(
      title: title!,
      body: '${mgdl.toStringAsFixed(0)} mg/dL is outside your urgent range.',
      payload: 'glucose:$type',
    );
    unawaited(loadAlerts());
  }

  Future<void> _upload(List<GlucoseSample> samples) async {
    // Cached SDK samples may be emitted during startup even when no sensor is
    // currently connected. Do not call the monitoring API in that state.
    if (!authenticated) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: not authenticated');
      return;
    }
    if (connection != CgmConnectionState.connected) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: connection=$connection');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final currentWear = wear ?? await CgmSdk.currentWear();
    if (currentWear == null) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: no current wear');
      return;
    }
    final binding = _binding ?? await api.storedBinding();
    if (binding == null) {
      debugPrint('[GLUCOSE-UPLOAD] skipped: no backend sensor binding');
      return;
    }
    final key = 'uploaded_seq_${currentWear.wearId}';
    final lastSeq = prefs.getInt(key) ?? -1;
    final pending =
        samples
            .where((x) => x.wearId == currentWear.wearId && x.seq > lastSeq)
            .toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    debugPrint(
      '[GLUCOSE-UPLOAD] wear=${currentWear.wearId} sensor=${binding.sensorId} '
      'input=${samples.length} pending=${pending.length} lastSeq=$lastSeq',
    );
    for (var offset = 0; offset < pending.length; offset += 500) {
      // The sensor may disconnect while a multi-batch upload is in progress.
      if (connection != CgmConnectionState.connected) break;
      final batch = pending.skip(offset).take(500).toList();
      for (final sample in batch) {
        debugPrint(
          '[CGM SAMPLE] seq=${sample.seq} '
          'warmup=${sample.warmup} '
          'abnormal=${sample.abnormal} '
          'value=${sample.value}',
        );
      }
      final valid = batch
          .where((x) => x.value != null && !x.warmup && !x.abnormal)
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
      } catch (_) {
        // If device is currently offline, skip updating last uploaded seq.
        // It will automatically retry and upload immediately once internet connectivity returns!
        break;
      }
    }
  }

  Future<void> _enqueueUploadRows(
    int sensorId,
    List<GlucoseSample> samples,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        (jsonDecode(prefs.getString(_uploadQueueKey) ?? '[]') as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
    final keys = existing
        .map((row) => '${row['sensorId']}:${row['measurementTime']}')
        .toSet();
    for (final sample in samples) {
      final row = <String, dynamic>{
        'sensorId': sensorId,
        'glucoseValue': double.parse(
          (sample.value! * 18.0182).toStringAsFixed(1),
        ),
        'measurementTime': sample.measuredAt.toUtc().toIso8601String(),
        if (sample.voltage != null) 'batteryVoltageMv': sample.voltage!.round(),
        if (sample.temperature != null)
          'deviceTemperatureC': sample.temperature,
        if (sample.rawCurrent != null) 'we1CurrentNa': sample.rawCurrent,
        'sequenceNumber': sample.seq & 0xffff,
      };
      final key = '$sensorId:${row['measurementTime']}';
      if (keys.add(key)) existing.add(row);
    }
    await prefs.setString(_uploadQueueKey, jsonEncode(existing));
    debugPrint('[GLUCOSE-UPLOAD] queued=${existing.length}');
    if (existing.length >= 5) {
      await _flushUploadQueue();
    } else {
      _uploadQueueTimer ??= Timer(const Duration(minutes: 5), () {
        _uploadQueueTimer = null;
        unawaited(_flushUploadQueue());
      });
    }
  }

  Future<void> _flushUploadQueue() async {
    if (_uploadQueueFlushing ||
        !authenticated ||
        connection != CgmConnectionState.connected)
      return;
    _uploadQueueFlushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued =
          (jsonDecode(prefs.getString(_uploadQueueKey) ?? '[]') as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
      final bySensor = <int, List<Map<String, dynamic>>>{};
      for (final row in queued) {
        bySensor.putIfAbsent(row['sensorId'] as int, () => []).add(row);
      }
      for (final entry in bySensor.entries) {
        final batch = entry.value.take(500).toList();
        await api.uploadGlucose(entry.key, batch);
        queued.removeWhere((row) => batch.contains(row));
      }
      await prefs.setString(_uploadQueueKey, jsonEncode(queued));
      if (queued.isNotEmpty) {
        _uploadQueueTimer ??= Timer(const Duration(minutes: 5), () {
          _uploadQueueTimer = null;
          unawaited(_flushUploadQueue());
        });
      }
      if (queued.isEmpty) unawaited(loadAlerts());
    } catch (_) {
      debugPrint('[GLUCOSE-UPLOAD] queue flush failed; readings retained');
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
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _watchSub?.cancel();
    _progressSub?.cancel();
    _errorSub?.cancel();
    _glucoseSub?.cancel();
    super.dispose();
  }
}
