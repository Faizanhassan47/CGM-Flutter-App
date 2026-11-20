import 'package:flutter_test/flutter_test.dart';
import 'package:aima_cgm/screens/alerts/alert_category.dart';

void main() {
  group('classifyAlert', () {
    test('puts glucose monitor notifications in Critical', () {
      expect(
        classifyAlert({
          'title': 'Glucose reading received',
          'severity': 'Warning',
        }),
        AlertCategory.critical,
      );
      expect(
        classifyAlert({'alertType': 'CGM_SENSOR_READING'}),
        AlertCategory.critical,
      );
    });

    test('puts meal and water reminders in Warning', () {
      expect(
        classifyAlert({
          'title': 'Meal reminder',
          'message': 'Review glucose after your meal',
          'severity': 'Critical',
        }),
        AlertCategory.warning,
      );
      expect(
        classifyAlert({'title': 'Hydration reminder'}),
        AlertCategory.warning,
      );
    });

    test('puts other notifications in Warning', () {
      expect(
        classifyAlert({'title': 'Sensor connection restored'}),
        AlertCategory.warning,
      );
    });

    test('keeps explicitly critical non-wellness alerts in Critical', () {
      expect(
        classifyAlert({'title': 'Safety alert', 'isCritical': true}),
        AlertCategory.critical,
      );
    });
  });
}
