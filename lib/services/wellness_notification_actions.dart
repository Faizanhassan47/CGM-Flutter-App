import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_config.dart';
import 'api_service.dart';
import 'wellness_offline_store.dart';

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
  if (type == 'breakfast' || type == 'lunch' || type == 'dinner' || type == 'snack') {
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

  if (action == 'meal_later') {
    tzdata.initializeTimeZones();
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: wellnessSnoozeMinutes));
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

  try {
    await AppConfig.load();
    final api = ApiService();
    final signedIn = await api.restoreSession();
    if (!signedIn) {
      await confirm('Sign in to Circle to save this entry.');
      return;
    }
    final when = DateTime.now().toUtc().toIso8601String();
    if (amount != null) {
      final event = {
        'amountMl': amount,
        'occurredAtUtc': when,
        'clientEventId': 'ntf-$id-water-$amount',
      };
      try {
        await api.createWater(event);
        await confirm('$amount ml added to today\'s hydration log.');
      } catch (_) {
        await WellnessOfflineStore.add({'kind': 'water', 'data': event});
        await confirm('$amount ml saved offline. Will sync when connected.');
      }
    } else {
      final event = {
        'mealType': mealTypeFromPayload(response.payload),
        'foodDescription': mealText,
        'occurredAtUtc': when,
        'clientEventId': 'ntf-$id-meal-${mealText.hashCode}',
      };
      try {
        await api.createMeal(event);
        await confirm('Meal saved.');
      } catch (_) {
        await WellnessOfflineStore.add({'kind': 'meal', 'data': event});
        await confirm('Meal saved offline. Will sync when connected.');
      }
    }
  } catch (_) {
    await confirm('Unable to save. Open Circle to retry.');
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
        AndroidNotificationAction('water_250', '+250 ml', cancelNotification: false),
        AndroidNotificationAction('water_500', '+500 ml', cancelNotification: false),
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
          inputs: [AndroidNotificationActionInput(label: 'What did you eat?')],
        ),
        AndroidNotificationAction('meal_later', 'Remind later', cancelNotification: true),
      ],
    ),
  );
}
