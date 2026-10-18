import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import 'logging_http_client.dart';

/// Exception thrown for any API communication or validation errors.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Represents the active device and sensor ID binding stored locally.
class BackendBinding {
  const BackendBinding({required this.deviceId, required this.sensorId});
  final int deviceId;
  final int sensorId;
}

/// Centralized API Service for the Circle CGM Flutter application.
/// Provides complete coverage for all backend endpoints:
/// - Authentication & Account Management
/// - User Profile
/// - CGM Devices & Bluetooth Hardware
/// - CGM Sensors & Calibration
/// - Glucose Sync, History & Statistics
/// - Alerts & Threshold Rules
/// - Clinical Reports (Detailed & AGP)
/// - Family & Caregiver Circle
/// - System Dictionaries, Articles & Notifications
class ApiService {
  ApiService({http.Client? client})
    : _client = client ?? LoggingHttpClient(http.Client()) {
    debugPrint('[API] Backend base URL: ${AppConfig.apiBaseUrl}');
  }

  final http.Client _client;
  static const _storage = FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  // ---------------------------------------------------------------------------
  // Core HTTP & URL Helpers
  // ---------------------------------------------------------------------------

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(
      AppConfig.apiBaseUrl.endsWith('/')
          ? AppConfig.apiBaseUrl
          : '${AppConfig.apiBaseUrl}/',
    );
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = base.resolve(cleanPath);
    return query == null
        ? uri
        : uri.replace(queryParameters: query.map((k, v) => MapEntry(k, '$v')));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, Object body) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Object body) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool retry = true,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers.addAll({
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    });
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && retry && await _refresh()) {
      return _send(method, path, body: body, query: query, retry: false);
    }
    return _handle(response);
  }

  Future<dynamic> _publicPost(String path, Object body) async {
    final response = await _client.post(
      _uri(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<dynamic> _publicGet(String path, [Map<String, dynamic>? query]) async {
    final response = await _client.get(
      _uri(path, query),
      headers: const {'Content-Type': 'application/json'},
    );
    return _handle(response);
  }

  // ---------------------------------------------------------------------------
  // Session & Token Storage
  // ---------------------------------------------------------------------------

  Future<bool> restoreSession() async {
    try {
      _accessToken = await _storage.read(key: 'aima_access_token');
      _refreshToken = await _storage.read(key: 'aima_refresh_token');
      if (_accessToken == null) return false;
      try {
        await getProfile();
        return true;
      } on ApiException catch (e) {
        if (e.statusCode != 401 || !await _refresh()) {
          await _clearTokens();
          return false;
        }
        return true;
      }
    } catch (e) {
      debugPrint('[API] Failed to restore session from secure storage: $e');
      await _clearTokens();
      return false;
    }
  }

  Future<bool> _refresh() async {
    if (_refreshToken == null) return false;
    try {
      final data = await _publicPost('api/Auth/refresh-token', {
        'refreshToken': _refreshToken,
      });
      await _saveTokens('${data['accessToken']}', '${data['refreshToken']}');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: 'aima_access_token', value: access);
    await _storage.write(key: 'aima_refresh_token', value: refresh);
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'aima_access_token');
    await _storage.delete(key: 'aima_refresh_token');
  }

  // ===========================================================================
  // 1. AUTHENTICATION & ACCOUNT APIS
  // ===========================================================================

  /// Standard email & password login.
  Future<void> login(String email, String password) async {
    final response = await _client.post(
      _uri('api/Auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'rememberMe': true,
        'deviceInfo': 'Circle Flutter CGM',
      }),
    );
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _message(data, 'Login failed.'),
        statusCode: response.statusCode,
      );
    }
    await _saveTokens('${data['accessToken']}', '${data['refreshToken']}');
  }

  /// Social OAuth login (Google, Apple, etc.).
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String idToken,
    String? fullName,
  }) async {
    final data = await _publicPost('api/Auth/social', {
      'provider': provider,
      'idToken': idToken,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      'deviceInfo': 'Circle Flutter CGM',
    });
    await _saveTokens('${data['accessToken']}', '${data['refreshToken']}');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Register a new patient account.
  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password, {
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String preferredGlucoseUnit = 'mg/dL',
  }) async {
    final data = await _publicPost('api/Auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
      if (phoneNumber?.trim().isNotEmpty == true)
        'phoneNumber': phoneNumber!.trim(),
      if (dateOfBirth?.trim().isNotEmpty == true)
        'dateOfBirth': dateOfBirth!.trim(),
      if (gender?.trim().isNotEmpty == true) 'gender': gender!.trim(),
      'preferredGlucoseUnit': preferredGlucoseUnit,
    });
    await _saveTokens('${data['accessToken']}', '${data['refreshToken']}');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Send password reset verification code to email.
  Future<void> forgotPassword(String email) =>
      _publicPost('api/Auth/forgot-password', {'email': email}).then((_) {});

  /// Verify 6-digit password reset code.
  Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final res = await _publicPost('api/Auth/verify-reset-code', {
      'email': email,
      'code': code,
    });
    return _map(res);
  }

  /// Reset password using verification token or code.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _publicPost('api/Auth/reset-password', {
      'email': email,
      'token': token,
      'tokenOrCode': token,
      'newPassword': newPassword,
    });
  }

  /// Change password for currently authenticated user.
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await post('api/Auth/change-password', {
      if (currentPassword != null) 'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Logout current session and revoke tokens.
  Future<void> logout() async {
    try {
      await post('api/Auth/logout', const {});
    } catch (_) {}
    await _clearTokens();
  }

  /// Permanently delete the user's account.
  Future<void> deleteAccount() async {
    await delete('api/Auth/account');
    await _clearTokens();
  }

  // ===========================================================================
  // 2. USER PROFILE APIS
  // ===========================================================================

  /// Fetch user profile details.
  Future<Map<String, dynamic>> getProfile() async {
    final res = await get('api/Profile');
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  /// Update user profile.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? preferredGlucoseUnit,
    String? language,
    double? targetLow,
    double? targetHigh,
    double? urgentLowThreshold,
    double? urgentHighThreshold,
    String? bedTime,
    String? wakeTime,
    double? nightLowThreshold,
    double? nightHighThreshold,
    bool? nightAlertsEnabled,
  }) async {
    final res = await put('api/Profile', {
      'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (preferredGlucoseUnit != null)
        'preferredGlucoseUnit': preferredGlucoseUnit,
      if (language != null) 'language': language,
      if (targetLow != null) 'targetLow': targetLow,
      if (targetHigh != null) 'targetHigh': targetHigh,
      if (urgentLowThreshold != null) 'urgentLowThreshold': urgentLowThreshold,
      if (urgentHighThreshold != null)
        'urgentHighThreshold': urgentHighThreshold,
      if (bedTime != null) 'bedTime': bedTime,
      if (wakeTime != null) 'wakeTime': wakeTime,
      if (nightLowThreshold != null) 'nightLowThreshold': nightLowThreshold,
      if (nightHighThreshold != null) 'nightHighThreshold': nightHighThreshold,
      if (nightAlertsEnabled != null) 'nightAlertsEnabled': nightAlertsEnabled,
    });
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  // ===========================================================================
  // 3. CGM DEVICES APIS
  // ===========================================================================

  /// Registers a physical CGM device and returns its record.
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String deviceType,
    required String deviceModel,
    required String serialNumber,
    required String bleDeviceName,
    int? batteryVoltageMv,
    String? firmwareVersion,
  }) async {
    final res = await post('api/Devices/register', {
      'deviceName': deviceName,
      'deviceType': deviceType,
      'deviceModel': deviceModel,
      'serialNumber': serialNumber,
      'bleDeviceName': bleDeviceName,
      if (batteryVoltageMv != null) 'batteryVoltageMv': batteryVoltageMv,
      if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
    });
    return _map(res);
  }

  /// Fetches registered devices for the current user.
  Future<List<dynamic>> getDevices() async {
    final res = await get('api/Devices');
    return res is List ? res : [];
  }

  /// Fetches a specific device by ID.
  Future<Map<String, dynamic>> getDevice(int id) async {
    final res = await get('api/Devices/$id');
    return _map(res);
  }

  /// Updates status of a device (e.g. Active, Inactive, Disconnected).
  Future<void> updateDeviceStatus(int id, String status) async {
    await put('api/Devices/$id/status', {'status': status});
  }

  /// Activates a device & starts sensor session, saving IDs to secure storage.
  Future<BackendBinding> activateDevice({
    required String deviceSerial,
    required String sensorSerial,
    required String form,
    required String bluetoothName,
    int? batteryMv,
  }) async {
    final device = await registerDevice(
      deviceName: 'Circle CGM',
      deviceType: form == 'half' ? 'Reusable' : 'Disposable',
      deviceModel: form == 'half' ? 'G-B' : 'G-AA',
      serialNumber: deviceSerial,
      bleDeviceName: bluetoothName,
      batteryVoltageMv: batteryMv,
    );

    final deviceId = _int(device['id']);
    if (deviceId == null) {
      throw const ApiException('Server did not return a device ID.');
    }

    final sensor = await startSensor(
      deviceId: deviceId,
      sensorIdentifier: sensorSerial,
      warmupMinutes: 120,
    );

    final sensorId = _int(sensor['id']);
    if (sensorId == null) {
      throw const ApiException('Server did not return a sensor ID.');
    }

    await _storage.write(key: 'backend_device_id', value: '$deviceId');
    await _storage.write(key: 'backend_sensor_id', value: '$sensorId');
    return BackendBinding(deviceId: deviceId, sensorId: sensorId);
  }

  /// Reads stored backend device and sensor binding.
  Future<BackendBinding?> storedBinding() async {
    final deviceId = int.tryParse(
      await _storage.read(key: 'backend_device_id') ?? '',
    );
    final sensorId = int.tryParse(
      await _storage.read(key: 'backend_sensor_id') ?? '',
    );
    return deviceId == null || sensorId == null
        ? null
        : BackendBinding(deviceId: deviceId, sensorId: sensorId);
  }

  /// Deactivates and deletes the active device and sensor session.
  Future<void> deactivateDevice() async {
    final binding = await storedBinding();
    if (binding == null) return;
    try {
      await stopSensor();
    } catch (_) {}
    try {
      await delete('api/Devices/${binding.deviceId}');
    } catch (_) {}
    await _storage.delete(key: 'backend_device_id');
    await _storage.delete(key: 'backend_sensor_id');
  }

  // ===========================================================================
  // 4. CGM SENSORS APIS
  // ===========================================================================

  /// Start a new sensor session.
  Future<Map<String, dynamic>> startSensor({
    required int deviceId,
    required String sensorIdentifier,
    int warmupMinutes = 120,
    int lifespanDays = 14,
  }) async {
    final res = await post('api/Sensors/start', {
      'deviceId': deviceId,
      'sensorIdentifier': sensorIdentifier,
      'warmupMinutes': warmupMinutes,
      'lifespanDays': lifespanDays,
    });
    return _map(res);
  }

  /// Get active sensor for current user.
  Future<Map<String, dynamic>?> getActiveSensor() async {
    try {
      final res = await get('api/Sensors/active');
      return res is Map<String, dynamic> ? res : null;
    } catch (_) {
      return null;
    }
  }

  /// Stop sensor session.
  Future<void> stopSensor({int? sensorId}) async {
    await post('api/Sensors/stop', {
      if (sensorId != null) 'sensorId': sensorId,
    });
  }

  /// Calibrate sensor with reference blood glucose measurement.
  Future<void> calibrateSensor({
    required int sensorId,
    required double referenceGlucose,
    required String unit,
  }) async {
    await post('api/Sensors/calibrate', {
      'sensorId': sensorId,
      'referenceGlucose': referenceGlucose,
      'unit': unit,
    });
  }

  // ===========================================================================
  // 5. GLUCOSE MEASUREMENTS & SYNC APIS
  // ===========================================================================

  /// Bulk upload/sync glucose readings from SDK or offline cache.
  Future<void> uploadGlucose(
    int sensorId,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isNotEmpty) {
      await post('api/Glucose/sync-bulk', {
        'sensorId': sensorId,
        'measurements': rows,
      });
    }
  }

  /// Save single glucose measurement.
  Future<void> saveMeasurement({
    required int sensorId,
    required double value,
    required String trend,
    required String timestamp,
    String unit = 'mg/dL',
  }) async {
    await post('api/Glucose/measurement', {
      'sensorId': sensorId,
      'glucoseValue': value,
      'trend': trend,
      'unit': unit,
      'measuredAt': timestamp,
    });
  }

  /// Fetch historical glucose readings with optional filters.
  Future<List<dynamic>> getGlucoseHistory({
    int? limit,
    int? hours,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (hours != null) 'hours': hours,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final res = await get(
      'api/Glucose/history',
      query: query.isEmpty ? null : query,
    );
    return res is List ? res : [];
  }

  /// Fetch glucose statistical summary (TIR, Average, eA1c).
  Future<Map<String, dynamic>> getGlucoseSummary({int days = 7}) async {
    final res = await get('api/Glucose/summary', query: {'days': days});
    return _map(res);
  }

  /// Fetch most recent glucose sample.
  Future<Map<String, dynamic>?> getLatestGlucose() async {
    try {
      final res = await get('api/Glucose/latest');
      return res is Map<String, dynamic> ? res : null;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 6. ALERTS & THRESHOLD RULES APIS
  // ===========================================================================

  /// Fetch alerts with optional filters.
  Future<List<dynamic>> getAlerts({String? severity, bool? unreadOnly}) async {
    final query = <String, dynamic>{
      if (severity != null) 'severity': severity,
      if (unreadOnly != null) 'unreadOnly': unreadOnly.toString(),
    };
    final res = await get('api/Alerts', query: query.isEmpty ? null : query);
    return res is List ? res : [];
  }

  /// Mark specific alert as read.
  Future<void> markAlertRead(int alertId) async {
    await put('api/Alerts/$alertId/read', const {});
  }

  /// Fetch user-configured alert threshold rules.
  Future<List<dynamic>> getAlertRules() async {
    final res = await get('api/alert-rules');
    return res is List ? res : [];
  }

  /// Save or update alert threshold rules.
  Future<void> saveAlertRule({
    required String ruleType,
    required double thresholdValue,
    required bool isEnabled,
    String? severity,
  }) async {
    await post('api/alert-rules', {
      'ruleType': ruleType,
      'thresholdValue': thresholdValue,
      'isEnabled': isEnabled,
      if (severity != null) 'severity': severity,
    });
  }

  // ===========================================================================
  // 7. CLINICAL REPORTS APIS
  // ===========================================================================

  /// Fetch detailed clinical report (Time in Range, Variability, GMI).
  Future<Map<String, dynamic>> getDetailedReport({
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final res = await get(
      'api/Reports/detailed',
      query: query.isEmpty ? null : query,
    );
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  /// Fetch Ambulatory Glucose Profile (AGP) report data.
  Future<Map<String, dynamic>> getAgpReport({
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    final res = await get(
      'api/Reports/agp',
      query: query.isEmpty ? null : query,
    );
    return _map(res);
  }

  /// Fetch Overnight Sleep Glucose Analysis (TIR, Dawn Phenomenon, Nocturnal Hypos).
  Future<Map<String, dynamic>> getOvernightReport({
    int? targetUserId,
    String? date,
  }) async {
    final query = <String, dynamic>{
      if (targetUserId != null) 'targetUserId': targetUserId,
      if (date != null) 'date': date,
    };
    final res = await get(
      'api/Reports/overnight',
      query: query.isEmpty ? null : query,
    );
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  // ===========================================================================
  // 8. FAMILY & CAREGIVER CIRCLE APIS
  // ===========================================================================

  /// Fetch current family circle details.
  Future<Map<String, dynamic>?> getFamily() async {
    try {
      final res = await get('api/Family');
      return res is Map<String, dynamic> ? res : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch members in current family circle.
  Future<List<dynamic>> getFamilyMembers() async {
    try {
      final res = await get('api/Family/members');
      return res is List ? res : [];
    } catch (_) {
      return [];
    }
  }

  /// Create a new family circle.
  Future<Map<String, dynamic>> createFamily() async {
    final res = await post('api/Family/create', const {});
    return _map(res);
  }

  /// Join existing family circle with referral code.
  Future<void> joinFamily(String inviteCode) async {
    await post('api/Family/join', {'referralCode': inviteCode});
  }

  /// Leave family circle.
  Future<void> leaveFamily() async {
    await post('api/Family/leave', const {});
  }

  /// Delete/dissolve entire family circle (for owner/admin).
  Future<void> deleteFamily() async {
    await delete('api/Family');
  }

  /// Remove member from family circle.
  Future<void> removeFamilyMember(int memberId) async {
    await delete('api/Family/members/$memberId');
  }

  /// Update family member role.
  Future<void> updateFamilyMemberRole(int memberId, String role) async {
    await put('api/Family/members/$memberId/role', {'role': role});
  }

  /// Update family circle alert thresholds (Low and High glucose).
  Future<void> updateFamilyThresholds({
    double? lowThreshold,
    double? highThreshold,
  }) async {
    await put('api/Family/thresholds', {
      if (lowThreshold != null) 'lowThreshold': lowThreshold,
      if (highThreshold != null) 'highThreshold': highThreshold,
    });
  }

  /// Update alert preference for a specific family member (admin can add/remove notifications).
  Future<void> setFamilyMemberAlerts(
    int memberUserId, {
    required bool receiveAlerts,
  }) async {
    await put('api/Family/members/$memberUserId/alerts', {
      'receiveAlerts': receiveAlerts,
    });
  }

  /// Get specific family member's weekly report summary.
  Future<Map<String, dynamic>> getFamilyMemberReport(int memberUserId) async {
    final res = await get('api/Family/members/$memberUserId/report-summary');
    return _map(res);
  }

  // ===========================================================================
  // 9. DICTIONARIES, ARTICLES & SYSTEM APIS
  // ===========================================================================

  /// Check latest application version.
  Future<Map<String, dynamic>> getLatestAppVersion() async {
    final res = await _publicGet('api/AppVersion/latest');
    return _map(res);
  }

  /// Fetch educational health articles.
  Future<List<dynamic>> getArticles() async {
    final res = await _publicGet('api/Articles');
    return res is List ? res : [];
  }

  /// Fetch food dictionary items.
  Future<List<dynamic>> getFoodDictionary() async {
    final res = await _publicGet('api/Dictionaries/foods');
    return res is List ? res : [];
  }

  /// Fetch insulin types dictionary.
  Future<List<dynamic>> getInsulinDictionary() async {
    final res = await _publicGet('api/Dictionaries/insulins');
    return res is List ? res : [];
  }

  /// Fetch mood types dictionary.
  Future<List<dynamic>> getMoodDictionary() async {
    final res = await _publicGet('api/Dictionaries/moods');
    return res is List ? res : [];
  }

  /// Register push notification device token (FCM / APNs).
  Future<void> registerPushNotificationToken({
    required String token,
    required String platform,
  }) async {
    await post('api/notification-endpoints', {
      'endpointArn': token,
      'platform': platform,
    });
  }

  /// Log phone hardware specifications into PhoneHardwareLogs table.
  Future<void> logPhoneHardware({
    String? deviceModel,
    String? osVersion,
    String? bluetoothMacAddress,
    String? platform,
    String? appVersion,
  }) async {
    try {
      await post('api/DeviceHardware/log', {
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (osVersion != null) 'osVersion': osVersion,
        if (bluetoothMacAddress != null)
          'bluetoothMacAddress': bluetoothMacAddress,
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
      });
    } catch (_) {
      // Non-critical background telemetry
    }
  }

  // ===========================================================================
  // Internal Response Parsers
  // ===========================================================================

  dynamic _handle(http.Response response) {
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _message(data, 'Request failed.'),
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Server returned invalid JSON.',
        statusCode: response.statusCode,
      );
    }
  }

  static String _message(dynamic data, String fallback) => data is Map
      ? '${data['message'] ?? data['error'] ?? fallback}'
      : fallback;

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? value.map((k, v) => MapEntry('$k', v))
      : <String, dynamic>{};

  static int? _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}

/// Backward compatibility alias so existing references to [NodeApi] work seamlessly.
typedef NodeApi = ApiService;
