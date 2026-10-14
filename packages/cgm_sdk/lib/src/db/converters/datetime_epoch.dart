import 'package:drift/drift.dart';

/// The LianXin time column does not have a time zone and crosses time zones./Daylight saving time will cause the curve to be misaligned and unified. UTC epoch millisecond
/// （INTEGER），The display layer is then converted to local。`date` The column is accepted in milliseconds, and the loss in hours, minutes and seconds comes from Lianxin Modeling。
class DateTimeEpochConverter extends TypeConverter<DateTime, int> {
  const DateTimeEpochConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}
