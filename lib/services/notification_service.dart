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
  static const String wellnessChannelId = 'wellness_reminders_channel';
  static const int wellnessIdStart = 200000;

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initializes Firebase Cloud Messaging, local notification channels, and listeners.
  Future<void> initialize({ApiService? apiService}) async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permissions
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

      // Setup local notifications for Android foreground presentation
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

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidChannel = const AndroidNotificationChannel(
          urgentChannelId,
          urgentChannelName,
          description: urgentChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(androidChannel);
        }
      }

      // Allow foreground notifications on iOS
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Retrieve FCM registration token
      _fcmToken = await _fcm.getToken();
      debugPrint('[FCM] Device Token: $_fcmToken');

      if (_fcmToken != null && apiService != null) {
        final platform = Platform.isAndroid ? 'Android' : 'iOS';
        await apiService.registerPushNotificationToken(
          token: _fcmToken!,
          platform: platform,
        );
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[FCM] Token refreshed: $newToken');
        if (apiService != null) {
          final platform = Platform.isAndroid ? 'Android' : 'iOS';
          apiService.registerPushNotificationToken(
            token: newToken,
            platform: platform,
          );
        }
      });

      // Listen for incoming messages in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Handle notification open when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] App opened from message: ${message.data}');
      });

      // Handle initial notification if app was terminated
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[FCM] App launched from terminated state via: ${initialMessage.data}',
        );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
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
  }) async {
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
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
    if (!_initialized) return;
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        wellnessChannelId,
        'Wellness reminders',
        description: 'Optional meal and hydration reminders',
        importance: Importance.defaultImportance,
      ),
    );
    for (var id = wellnessIdStart; id < wellnessIdStart + 100; id++) {
      await _localNotifications.cancel(id: id);
    }
    tz.initializeTimeZones();
    final zone = '${settings['timeZoneId'] ?? 'UTC'}';
    try {
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        wellnessChannelId,
        'Wellness reminders',
        channelDescription: 'Optional meal and hydration reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    var id = wellnessIdStart;
    final now = tz.TZDateTime.now(tz.local);
    bool quiet(int hour) {
      if (settings['quietHoursEnabled'] != true) return false;
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

    for (var day = 0; day < 7 && id < wellnessIdStart + 100; day++) {
      for (final raw in schedules) {
        final schedule = raw is Map ? raw : <String, dynamic>{};
        if (schedule['enabled'] == false) continue;
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
        if (!when.isAfter(now) ||
            quiet(when.hour) ||
            settings['mealEnabled'] != true)
          continue;
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
      if (settings['waterEnabled'] == true) {
        final interval =
            (int.tryParse('${settings['waterIntervalMinutes'] ?? 120}') ?? 120)
                .clamp(30, 720);
        for (
          var minute = 9 * 60;
          minute <= 21 * 60 && id < wellnessIdStart + 100;
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
}
