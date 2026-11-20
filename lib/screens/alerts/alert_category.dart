enum AlertCategory { critical, warning }

AlertCategory classifyAlert(Map<dynamic, dynamic> alert) {
  if (_isWellnessReminder(alert)) return AlertCategory.warning;
  if (_isGlucoseMonitorAlert(alert) || _hasCriticalSeverity(alert)) {
    return AlertCategory.critical;
  }
  return AlertCategory.warning;
}

bool _isWellnessReminder(Map<dynamic, dynamic> alert) {
  final text = _searchableText(alert);
  return text.contains('meal') ||
      text.contains('water') ||
      text.contains('hydration') ||
      text.contains('wellness:') ||
      text.contains('reminder');
}

bool _isGlucoseMonitorAlert(Map<dynamic, dynamic> alert) {
  final text = _searchableText(alert);
  return text.contains('glucose') ||
      text.contains('cgm') ||
      text.contains('hypogly') ||
      text.contains('hypergly') ||
      text.contains('urgentlow') ||
      text.contains('urgenthigh') ||
      text.contains('urgent low') ||
      text.contains('urgent high');
}

bool _hasCriticalSeverity(Map<dynamic, dynamic> alert) {
  final flag = alert['isCritical'] ?? alert['IsCritical'];
  final severity = (alert['severity'] ?? alert['Severity'] ?? '')
      .toString()
      .toLowerCase();
  return flag == true || flag == 1 || flag == '1' || severity == 'critical';
}

String _searchableText(Map<dynamic, dynamic> alert) {
  return [
    alert['id'],
    alert['Id'],
    alert['title'],
    alert['Title'],
    alert['message'],
    alert['Message'],
    alert['alertType'],
    alert['AlertType'],
    alert['type'],
    alert['Type'],
    alert['payload'],
  ].whereType<Object>().join(' ').toLowerCase();
}
