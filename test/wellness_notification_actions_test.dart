import 'package:aima_cgm/services/wellness_notification_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a positive water amount within the limit', () {
    expect(parseWaterAmount('350'), 350);
  });

  test('rejects empty, zero, negative, and text amounts', () {
    expect(parseWaterAmount(''), isNull);
    expect(parseWaterAmount('0'), isNull);
    expect(parseWaterAmount('-20'), isNull);
    expect(parseWaterAmount('abc'), isNull);
    expect(parseWaterAmount('2501'), isNull);
  });

  test('reads the meal type stored in the reminder payload', () {
    expect(mealTypeFromPayload('wellness:meal:lunch'), 'lunch');
    expect(mealTypeFromPayload('wellness:meal'), 'snack');
  });
}
