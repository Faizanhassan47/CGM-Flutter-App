/// Lianxin field type mapping summary。
///
/// - `decimal(65,30)`（blood sugar）→ TEXT，[MedicalDecimalConverter]，No loss of accuracy
/// - `datetime` / `date` → INTEGER（UTC epoch millisecond），[DateTimeEpochConverter]
/// - `char(1)` Flag bit → direct `text()`，Original deposit slip characters
/// - `longtext` / `varchar(n)` → direct `text()`，SQLite TEXT No upper limit on length
/// - `bigint`（Contains clerical errors `biging`）→ `int64`；`int` → `int`；`double`/`float` → `real`
library;

export 'package:cgm_sdk/src/db/converters/datetime_epoch.dart';
export 'package:cgm_sdk/src/db/converters/medical_decimal.dart';
