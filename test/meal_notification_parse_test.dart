import 'package:flutter_test/flutter_test.dart';
import 'package:aima_cgm/services/wellness_notification_actions.dart';

void main() {
  group('parseMealLogInput', () {
    test('parses food with trailing carbs grams', () {
      final parsed = parseMealLogInput('chicken rice 40');
      expect(parsed?.food, 'chicken rice');
      expect(parsed?.carbs, 40);
    });

    test('parses food without carbs', () {
      final parsed = parseMealLogInput('oats with banana');
      expect(parsed?.food, 'oats with banana');
      expect(parsed?.carbs, isNull);
    });

    test('rejects empty input', () {
      expect(parseMealLogInput('  '), isNull);
      expect(parseMealLogInput(null), isNull);
    });
  });
}
