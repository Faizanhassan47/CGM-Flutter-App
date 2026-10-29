import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart';

/// Top-level background message handler for FCM.
/// Must be an entry-point function outside of any class.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Handling background message: ${message.messageId}');
}

/// Centralized service handling Firebase Cloud Messaging (FCM) & local alerts.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String urgentChannelId = 'cgm_urgent_channel';
  static const String urgentChannelName = 'CGM Urgent Alerts';
  static const String urgentChannelDesc =
      'High priority urgent glucose alerts and notifications';
  // Versioned so Android applies the corrected importance/sound settings even
  // when the previous channel was already created on the device.
  static const String wellnessChannelId = 'wellness_reminders_channel_v2';
  static const int wellnessIdStart = 200000;

  bool _initialized = false;
  bool _listenersBound = false;
  String? _fcmToken;
  ApiService? _api;
  bool _pushEnabled = true;

  String? get fcmToken => _fcmToken;

  /// Initializes Firebase Cloud Messaging, local notification channels, and listeners.
  Future<void> initialize({
    ApiService? apiService,
    bool pushEnabled = true,
  }) async {
    _pushEnabled = pushEnabled;
    if (apiService != null) _api = apiService;

    if (!_initialized) {
      try {
        await _initLocalNotifications();
        _initialized = true;
      } catch (e) {
        debugPrint('[Notifications] Local init error: $e');
      }
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        final settings = await _fcm.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: true,
          provisional: false,
          sound: true,
        );
        debugPrint(
          '[FCM] User granted permission: ${settings.authorizationStatus}',
        );
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        _bindListeners();
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          debugPrint(
            '[FCM] App launched from terminated state via: ${initialMessage.data}',
          );
        }
      } catch (e) {
        debugPrint('[FCM] Initialization error: $e');
      }
    }

    await syncPushToken(apiService: _api, enabled: _pushEnabled);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notification] User tapped: ${details.payload}');
      },
    );
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          urgentChannelId,
          urgentChannelName,
          description: urgentChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
  }

  void _bindListeners() {
    if (_listenersBound) return;
    _listenersBound = true;
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('[FCM] Token refreshed: $newToken');
      unawaited(syncPushToken(apiService: _api, enabled: _pushEnabled));
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App opened from message: ${message.data}');
    });
  }

  /// Registers or updates the FCM token after login even if init already ran.
  Future<void> syncPushToken({
    ApiService? apiService,
    bool enabled = true,
  }) async {
    _pushEnabled = enabled;
    if (apiService != null) _api = apiService;
    if (_api == null) return;
    try {
      _fcmToken ??= await _fcm.getToken();
      debugPrint('[FCM] Device Token: $_fcmToken');
      if (_fcmToken == null) return;
      await _api!.registerPushNotificationToken(
        token: _fcmToken!,
        platform: Platform.isAndroid ? 'Android' : 'iOS',
        enabled: enabled,
      );
    } catch (e) {
      debugPrint('[FCM] Token sync error: $e');
    }
  }

  /// Displays foreground notification heads-up banner via local notifications.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      urgentChannelId,
      urgentChannelName,
      channelDescription: urgentChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'CGM Alert',
      body: notification.body ?? '',
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  /// Display a local urgent glucose notification programmatically.
  Future<void> showLocalAlert({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final androidDetails = AndroidNotificationDetails(
      urgentChannelId,
      urgentChannelName,
      channelDescription: urgentChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final id =
        notificationId ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Schedules only wellness IDs. Critical CGM notifications use a separate
  /// channel and are never canceled here.
  Future<void> scheduleWellness({
    required Map<String, dynamic> settings,
    required List<dynamic> schedules,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        wellnessChannelId,
        'Wellness reminders',
        description: 'Optional meal and hydration reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    for (var id = wellnessIdStart; id < wellnessIdStart + 200; id++) {
      await _localNotifications.cancel(id: id);
    }
    tz.initializeTimeZones();
    final requestedZone = settings['timeZoneId']?.toString().trim();
    if (requestedZone != null && requestedZone.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(requestedZone));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        wellnessChannelId,
        'Wellness reminders',
        channelDescription: 'Optional meal and hydration reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
    var id = wellnessIdStart;
    final now = tz.TZDateTime.now(tz.local);
    bool quiet(int hour) {
      final quietEnabled =
          settings['quietHoursEnabled'] == true ||
          settings['quietHoursEnabled'] == 1 ||
          settings['quietHoursEnabled'] == 'true';
      if (!quietEnabled) return false;
      final start =
          int.tryParse(
            '${settings['quietStart'] ?? '22:00'}'.split(':').first,
          ) ??
          22;
      final end =
          int.tryParse('${settings['quietEnd'] ?? '07:00'}'.split(':').first) ??
          7;
      return start > end
          ? hour >= start || hour < end
          : hour >= start && hour < end;
    }

    final isMealEnabled =
        settings['mealEnabled'] == true ||
        settings['mealEnabled'] == 1 ||
        settings['mealEnabled'] == 'true';
    final isWaterEnabled =
        settings['waterEnabled'] == true ||
        settings['waterEnabled'] == 1 ||
        settings['waterEnabled'] == 'true';

    for (var day = 0; day < 7 && id < wellnessIdStart + 200; day++) {
      for (final raw in schedules) {
        final schedule = raw is Map ? raw : <String, dynamic>{};
        if (schedule['enabled'] == false ||
            schedule['enabled'] == 0 ||
            schedule['enabled'] == 'false')
          continue;
        final parts = '${schedule['reminderTime'] ?? ''}'.split(':');
        if (parts.length != 2) continue;
        final when = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        );
        if (!when.isAfter(now) || quiet(when.hour) || !isMealEnabled) {
          continue;
        }
        await _localNotifications.zonedSchedule(
          id: id++,
          title:
              'Time for ${schedule['customName'] ?? schedule['mealType'] ?? 'your meal'}',
          body: 'It\'s time for your scheduled meal. You can log it in Circle.',
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'wellness:meal',
        );
      }
      if (isWaterEnabled) {
        // The API allows intervals from 5 to 720 minutes. Keep the same
        // bounds here so short intervals can be tested and saved settings are
        // not silently changed by the device scheduler.
        final interval =
            (int.tryParse('${settings['waterIntervalMinutes'] ?? 120}') ?? 120)
                .clamp(5, 720);
        for (
          var minute = 9 * 60;
          minute <= 21 * 60 && id < wellnessIdStart + 200;
          minute += interval
        ) {
          final when = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day + day,
            minute ~/ 60,
            minute % 60,
          );
          if (!when.isAfter(now) || quiet(when.hour)) continue;
          await _localNotifications.zonedSchedule(
            id: id++,
            title: 'Hydration reminder',
            body: 'Optional reminder to log water if you choose.',
            scheduledDate: when,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'wellness:water',
          );
        }
      }
    }
  }

  /// Helper to inspect registered pending scheduled notifications for debugging.
  Future<void> debugPendingNotifications() async {
    final pending = await _localNotifications.pendingNotificationRequests();
    debugPrint('[Notifications] Pending count: ${pending.length}');
    for (final notification in pending) {
      debugPrint(
        '[Notifications] ID=${notification.id}, Title=${notification.title}, Body=${notification.body}',
      );
    }
  }
}
