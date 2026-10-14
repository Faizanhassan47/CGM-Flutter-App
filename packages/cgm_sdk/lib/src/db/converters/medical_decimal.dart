import 'package:drift/drift.dart';

/// Medical precision fixed point value。
///
/// Lianxin blood glucose series is `decimal(65,30)`，SQLite none DECIMAL、REAL I can’t express this precision either.，
/// Therefore, the string is stored as it is without going through double；The arbitrary precision library is not referenced, and numerical operations are parsed by the upper layer itself.。
class MedicalDecimal implements Comparable<MedicalDecimal> {
  /// Normalized string literals and storage TEXT Verbatim。
  final String raw;

  const MedicalDecimal._(this.raw);

  /// Constructed from string. Remove the leading and trailing blanks and keep them as they are without rounding or rotation. double。
  factory MedicalDecimal(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      throw FormatException(
        'MedicalDecimal Empty string is not accepted',
        value,
      );
    }
    return MedicalDecimal._(v);
  }

  /// Only used in scenarios such as integers that do not lose accuracy; blood sugar values ​​are always structured as strings.。
  factory MedicalDecimal.fromInt(int value) => MedicalDecimal._('$value');

  /// parsed as double For display of tolerance error such as charts; storage/If you don’t use it for reconciliation, you will lose accuracy.。
  double toDoubleLossy() => double.parse(raw);

  @override
  String toString() => raw;

  @override
  bool operator ==(Object other) => other is MedicalDecimal && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  /// Just compare by string, enough for equality/Deduplication; numerical size sorting will be done after importing the precision library.。
  @override
  int compareTo(MedicalDecimal other) => raw.compareTo(other.raw);
}

/// `decimal(65,30)` ↔ TEXT。Original value string in and out, zero precision loss。
class MedicalDecimalConverter extends TypeConverter<MedicalDecimal, String> {
  const MedicalDecimalConverter();

  @override
  MedicalDecimal fromSql(String fromDb) => MedicalDecimal(fromDb);

  @override
  String toSql(MedicalDecimal value) => value.raw;
}
