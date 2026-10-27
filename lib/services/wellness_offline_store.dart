import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WellnessOfflineStore {
  static const _key = 'wellness_pending_events_v1';
  static const _storage = FlutterSecureStorage();
  static Future<List<Map<String, dynamic>>> pending() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(Map<String, dynamic> event) async {
    final all = await pending();
    all.add(event);
    await _storage.write(key: _key, value: jsonEncode(all));
  }

  static Future<void> replace(List<Map<String, dynamic>> events) async =>
      _storage.write(key: _key, value: jsonEncode(events));
}
