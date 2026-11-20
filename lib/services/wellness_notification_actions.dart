import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_config.dart';
import 'api_service.dart';
import 'wellness_offline_store.dart';
import 'wellness_reminder_log.dart';

const int wellnessQuickWaterMl = 250;
const int wellnessLargeWaterMl = 500;
const int wellnessMaxWaterMl = 2000;
const int wellnessSnoozeMinutes = 30;

int? parseWaterAmount(String? raw) {
  final text = raw?.trim() ?? '';
  if (!RegExp(r'^\d+$').hasMatch(text)) return null;
  final value = int.tryParse(text);
  if (value == null || value < 1 || value > wellnessMaxWaterMl) return null;
  return value;
}

String mealTypeFromPayload(String? payload) {
  final parts = (payload ?? '').split(':');
  final type = parts.length >= 3 ? parts[2].toLowerCase() : '';
  if (type == 'breakfast' ||
      type == 'lunch' ||
      type == 'dinner' ||
      type == 'snack') {
    return type;
  }
  return 'snack';
}

@pragma('vm:entry-point')
Future<void> wellnessNotificationAction(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final action = response.actionId ?? '';
  final id = response.id ?? 0;
  final plugin = FlutterLocalNotificationsPlugin();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(settings: init);

  Future<void> confirm(String body) async {
    await plugin.show(
      id: id,
      title: 'Circle',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'wellness_reminders_channel_v2',
          'Wellness reminders',
          channelDescription: 'Optional meal and hydration reminders',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
        ),
      ),
    );
  }

  // Tapping the notification body also opens / logs presence in Alerts.
  final payload = response.payload ?? '';
  if (action.isEmpty && payload.startsWith('wellness:water')) {
    await WellnessReminderLog.add(
      id: 'water:tap:$id:${DateTime.now().millisecondsSinceEpoch}',
      title: 'Hydration reminder',
      message: 'Time to drink water. How much water did you drink?',
      at: DateTime.now(),
    );
    return;
  }
  if (action.isEmpty && payload.startsWith('wellness:meal')) {
    await WellnessReminderLog.add(
      id: 'meal:tap:$id:${DateTime.now().millisecondsSinceEpoch}',
      title: 'Meal reminder',
      message: 'Have you eaten? Log your meal in Circle.',
      at: DateTime.now(),
    );
    return;
  }

  if (action == 'meal_later') {
    tzdata.initializeTimeZones();
    final when = tz.TZDateTime.now(tz.local)
        .add(const Duration(minutes: wellnessSnoozeMinutes));
    await plugin.zonedSchedule(
      id: 201000 + (id % 500),
      title: 'Meal reminder',
      body: 'Have you eaten? Log your meal.',
      scheduledDate: when,
      notificationDetails: mealNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: response.payload ?? 'wellness:meal:snack',
    );
    await confirm('Reminder set for $wellnessSnoozeMinutes minutes from now.');
    return;
  }

  int? amount;
  String? mealText;
  if (action == 'water_250') amount = wellnessQuickWaterMl;
  if (action == 'water_500') amount = wellnessLargeWaterMl;
  if (action == 'water_custom') {
    amount = parseWaterAmount(response.input);
    if (amount == null) {
      await confirm('Enter a whole number from 1 to $wellnessMaxWaterMl ml.');
      return;
    }
  }
  if (action == 'meal_log') {
    mealText = response.input?.trim() ?? '';
    if (mealText.isEmpty || mealText.length > 4000) {
      await confirm('Enter a short description of what you ate.');
      return;
    }
  }
  if (amount == null && mealText == null) return;

  // Instant UX: confirm first, then persist (offline-first + best-effort sync).
  if (amount != null) {
    await confirm('$amount ml added to today\'s hydration log.');
    await WellnessReminderLog.add(
      id: 'water:logged:$id:${DateTime.now().millisecondsSinceEpoch}',
      title: 'Water logged',
      message: '$amount ml added from hydration reminder.',
      at: DateTime.now(),
    );
  } else {
    await confirm('Meal saved.');
    await WellnessReminderLog.add(
      id: 'meal:logged:$id:${DateTime.now().millisecondsSinceEpoch}',
      title: 'Meal logged',
      message: mealText ?? 'Meal saved from reminder.',
      at: DateTime.now(),
    );
  }

  try {
    await AppConfig.load();
    final api = ApiService();
    // Skip profile network call — that was causing 1–2 min waits on cold hosts.
    final signedIn = await api.restoreTokensOnly();
    if (!signedIn) {
      // Already confirmed to user; queue offline for later sync after sign-in.
      final when = DateTime.now().toUtc().toIso8601String();
      if (amount != null) {
        await WellnessOfflineStore.add({
          'kind': 'water',
          'data': {
            'amountMl': amount,
            'occurredAtUtc': when,
            'clientEventId':
                'ntf-$id-water-$amount-${DateTime.now().millisecondsSinceEpoch}',
          },
        });
      } else {
        await WellnessOfflineStore.add({
          'kind': 'meal',
          'data': {
            'mealType': mealTypeFromPayload(response.payload),
            'foodDescription': mealText,
            'occurredAtUtc': when,
            'clientEventId': 'ntf-$id-meal-${mealText.hashCode}',
          },
        });
      }
      return;
    }

    final when = DateTime.now().toUtc().toIso8601String();
    if (amount != null) {
      final event = {
        'amountMl': amount,
        'occurredAtUtc': when,
        'clientEventId':
            'ntf-$id-water-$amount-${DateTime.now().millisecondsSinceEpoch}',
      };
      try {
        await api
            .createWater(event)
            .timeout(const Duration(seconds: 8));
      } on TimeoutException {
        await WellnessOfflineStore.add({'kind': 'water', 'data': event});
      } catch (_) {
        await WellnessOfflineStore.add({'kind': 'water', 'data': event});
      }
    } else {
      final event = {
        'mealType': mealTypeFromPayload(response.payload),
        'foodDescription': mealText,
        'occurredAtUtc': when,
        'clientEventId': 'ntf-$id-meal-${mealText.hashCode}',
      };
      try {
        await api.createMeal(event).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        await WellnessOfflineStore.add({'kind': 'meal', 'data': event});
      } catch (_) {
        await WellnessOfflineStore.add({'kind': 'meal', 'data': event});
      }
    }
  } catch (_) {
    // User already got instant confirm; keep offline queue if possible.
  }
}

NotificationDetails waterNotificationDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      'wellness_reminders_channel_v2',
      'Wellness reminders',
      channelDescription: 'Optional meal and hydration reminders',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      actions: [
        AndroidNotificationAction(
          'water_250',
          '+250 ml',
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'water_500',
          '+500 ml',
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'water_custom',
          'Enter amount',
          cancelNotification: false,
          inputs: [AndroidNotificationActionInput(label: 'Milliliters')],
        ),
      ],
    ),
  );
}

NotificationDetails mealNotificationDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      'wellness_reminders_channel_v2',
      'Wellness reminders',
      channelDescription: 'Optional meal and hydration reminders',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.private,
      actions: [
        AndroidNotificationAction(
          'meal_log',
          'Log meal',
          cancelNotification: false,
          inputs: [
            AndroidNotificationActionInput(label: 'What did you eat?'),
          ],
        ),
        AndroidNotificationAction(
          'meal_later',
          'Remind later',
          cancelNotification: true,
        ),
      ],
    ),
  );
}
