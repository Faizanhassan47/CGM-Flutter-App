import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local hydration / meal reminder rows for the in-app Notifications screen.
class WellnessReminderLog {
  static const _key = 'wellness_reminder_alerts_v1';

  static Future<List<Map<String, dynamic>>> list({DateTime? clearedAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final rows = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final now = DateTime.now();
      return rows.where((row) {
        final at = DateTime.tryParse('${row['timestamp'] ?? ''}');
        if (at == null || at.isAfter(now)) return false;
        if (clearedAt == null) return true;
        return at.toUtc().isAfter(clearedAt);
      }).toList()
        ..sort((a, b) {
          final aAt = DateTime.tryParse('${a['timestamp'] ?? ''}') ?? DateTime(0);
          final bAt = DateTime.tryParse('${b['timestamp'] ?? ''}') ?? DateTime(0);
          return bAt.compareTo(aAt);
        });
    } catch (_) {
      return [];
    }
  }

  static Future<void> upsertMany(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await list();
    final byId = <String, Map<String, dynamic>>{
      for (final row in existing) '${row['id']}': row,
    };
    for (final row in rows) {
      final id = '${row['id'] ?? ''}';
      if (id.isEmpty) continue;
      byId[id] = row;
    }
    // Keep a bounded history for low-RAM devices.
    final merged = byId.values.toList()
      ..sort((a, b) {
        final aAt = DateTime.tryParse('${a['timestamp'] ?? ''}') ?? DateTime(0);
        final bAt = DateTime.tryParse('${b['timestamp'] ?? ''}') ?? DateTime(0);
        return bAt.compareTo(aAt);
      });
    final trimmed = merged.take(80).toList();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  static Future<void> add({
    required String id,
    required String title,
    required String message,
    required DateTime at,
    String severity = 'Warning',
  }) async {
    await upsertMany([
      {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity,
        'timestamp': at.toIso8601String(),
        'isRead': false,
        'isCritical': false,
      },
    ]);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
