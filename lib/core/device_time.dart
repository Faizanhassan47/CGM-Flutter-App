import 'package:intl/intl.dart';

/// Backend stores instants in UTC. Frontend always shows the device region clock.
class DeviceTime {
  DeviceTime._();

  /// Parse an API / DB timestamp as UTC, then convert to the phone's local zone.
  ///
  /// MySQL DATETIME and many Nest serializers omit `Z`. Those naive strings are
  /// UTC wall-clock values and must not be treated as already-local.
  static DateTime? parseApi(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return raw.isUtc ? raw.toLocal() : raw.toLocal();
    }
    var text = '$raw'.trim();
    if (text.isEmpty || text == 'null') return null;
    text = text.replaceFirst(' ', 'T');
    final hasZone = text.endsWith('Z') ||
        text.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);
    if (!hasZone) text = '${text}Z';
    return DateTime.tryParse(text)?.toLocal();
  }

  /// Local "now" on the device (region timezone from system settings).
  static DateTime now() => DateTime.now();

  static String time(DateTime? at) {
    if (at == null) return '';
    return DateFormat.jm().format(at.toLocal());
  }

  static String timeLower(DateTime? at) {
    if (at == null) return '';
    return DateFormat.jm().format(at.toLocal()).toLowerCase();
  }

  static String date(DateTime? at) {
    if (at == null) return '';
    return DateFormat.yMMMd().format(at.toLocal());
  }

  static String dateTime(DateTime? at) {
    if (at == null) return '';
    return DateFormat.yMMMd().add_jm().format(at.toLocal());
  }

  static String chartLabel(DateTime? at) {
    if (at == null) return '';
    return DateFormat('h:mm a').format(at.toLocal());
  }
}
