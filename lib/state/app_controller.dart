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

  /// Bumped only for auth / splash / profile-gate changes.
  /// CircleApp listens here so glucose ticks do not rebuild MainShell.
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);

  void _bumpSession() => sessionRevision.value++;

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
  static const _uploadQueueKey = 'glucose_upload_queue_v1';
  static const _secureStore = kSecureStorage;

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
      _bumpSession();
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
      await api.login(username.trim(), password);
      authenticated = true;
      _bumpSession();
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
      _bumpSession();
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
      _bumpSession();
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
      _bumpSession();
    });
  }

  Future<void> logout() async {
    await _run(() async {
      await api.logout();
      authenticated = false;
      wear = null;
      history = [];
      latest = null;
      deviceStatus = null;
      activeSensor = null;
      activeDevice = null;
      _binding = null;
      alerts = [];
      family = null;
      familyMembers = [];
      await _clearUploadQueue();
      await api.clearBackendBinding();
      try {
        await CgmSdk.unbind();
      } catch (_) {}
      _bumpSession();
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

  Future<void> loadAlerts({String? severity, int page = 1, int pageSize = 40}) async {
    try {
      final fetchedAlerts = await api.getAlerts(
        severity: severity,
        page: page,
        pageSize: pageSize,
      );

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

      alerts = fetchedAlerts.where((item) {
        final id = '${item['id'] ?? item['Id'] ?? ''}';
        if (id.startsWith('meal:') || id.startsWith('water:')) return false;
        final clearedAt = _alertsClearedAt;
        if (clearedAt == null) return true;
        final raw = item['timestamp'] ?? item['AlertTime'] ?? item['alertTime'];
        final when = DateTime.tryParse('$raw');
        if (when == null) return false;
        return when.toUtc().isAfter(clearedAt);
      }).toList();
      alerts = [..._localGlucoseAlerts, ...alerts];
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
      _bumpSession();
    });
  }

  Future<void> refreshHistory() async {
    if (!sdkReady) return;
    history = await CgmSdk.query(
      from: DateTime.now().subtract(const Duration(hours: 36)),
      limit: _maxUiHistory,
    );
    _trimHistory();
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

  DateTime? _lastUiNotifyAt;
  DateTime? _lastProgressNotifyAt;
  Timer? _uiNotifyTimer;
  static const _uiNotifyMinInterval = Duration(milliseconds: 900);
  /// Keep only a short local window for live UI; longer ranges come from
  /// paginated `GET /api/Glucose/history`.
  static const _maxUiHistory = 500;

  /// Map a server history row (mg/dL) into an SDK sample (mmol/L).
  static GlucoseSample? sampleFromServerRow(Map<String, dynamic> row) {
    final atRaw = row['measurementTime'] ?? row['MeasurementTime'];
    final at = atRaw == null
        ? null
        : DateTime.tryParse(atRaw.toString())?.toLocal();
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
    int pageSize = 300,
    int? sensorId,
  }) {
    return api.getGlucoseHistory(
      page: page,
      pageSize: pageSize,
      sensorId: sensorId,
      startUtc: startUtc.toUtc().toIso8601String(),
      endUtc: endUtc.toUtc().toIso8601String(),
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
      notifyListeners();
      return;
    }
    if (_lastUiNotifyAt == null ||
        now.difference(_lastUiNotifyAt!) >= _uiNotifyMinInterval) {
      _uiNotifyTimer?.cancel();
      _uiNotifyTimer = null;
      _lastUiNotifyAt = now;
      notifyListeners();
      return;
    }
    // Trailing edge: flush the latest state after the quiet window.
    _uiNotifyTimer ??= Timer(
      _uiNotifyMinInterval - now.difference(_lastUiNotifyAt!),
      () {
        _uiNotifyTimer = null;
        _lastUiNotifyAt = DateTime.now();
        notifyListeners();
      },
    );
  }

  void _trimHistory() {
    if (history.length <= _maxUiHistory) return;
    history = history.sublist(history.length - _maxUiHistory);
  }

  /// Append samples without rebuilding/sorting the full list on every tick.
  void _appendHistory(Iterable<GlucoseSample> samples) {
    for (final sample in samples) {
      final start = history.length > 64 ? history.length - 64 : 0;
      var duplicate = false;
      for (var i = start; i < history.length; i++) {
        final existing = history[i];
        if (existing.wearId == sample.wearId && existing.seq == sample.seq) {
          duplicate = true;
          break;
        }
      }
      if (duplicate) continue;
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
          from: DateTime.now().subtract(const Duration(hours: 36)),
        ).listen((samples) async {
          if (samples.isEmpty) return;
          _appendHistory(samples);
          latest = history.isEmpty ? latest : history.last;
          _notifyUiThrottled();
          await _upload(samples);
        });
    _glucoseSub ??= CgmSdk.glucose.listen((sample) {
      latest = sample;
      _appendHistory([sample]);
      _notifyUiThrottled();
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
    final binding = await _ensureBinding(currentWear);
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
    final existing = await _readUploadQueue();
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
    await _writeUploadQueue(existing);
    if (kDebugMode) {
      debugPrint('[GLUCOSE-UPLOAD] queued=${existing.length}');
    }
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
      final queued = await _readUploadQueue();
      final bySensor = <int, List<Map<String, dynamic>>>{};
      for (final row in queued) {
        bySensor.putIfAbsent(row['sensorId'] as int, () => []).add(row);
      }
      for (final entry in bySensor.entries) {
        final batch = entry.value.take(500).toList();
        await api.uploadGlucose(entry.key, batch);
        queued.removeWhere((row) => batch.contains(row));
      }
      await _writeUploadQueue(queued);
      if (queued.isNotEmpty) {
        _uploadQueueTimer ??= Timer(const Duration(minutes: 5), () {
          _uploadQueueTimer = null;
          unawaited(_flushUploadQueue());
        });
      }
      if (queued.isEmpty) unawaited(loadAlerts());
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[GLUCOSE-UPLOAD] queue flush failed; readings retained');
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
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _watchSub?.cancel();
    _progressSub?.cancel();
    _errorSub?.cancel();
    _glucoseSub?.cancel();
    super.dispose();
  }
}
