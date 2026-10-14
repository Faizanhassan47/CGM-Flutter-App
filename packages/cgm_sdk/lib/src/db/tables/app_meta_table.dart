import 'package:drift/drift.dart';

/// local only · Our supplementary form (non-joint core form)）。
///
/// runtime metadata KV：Encrypted health markers, synchronization cursors of each business table, and miscellaneous configurations are not uploaded.。
/// one key one line，value Stores strings, and complex values ​​are serialized by the caller.。
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  @override
  String get tableName => 'app_meta';

  TextColumn get key => text().named('key')();

  TextColumn get value => text().named('value').nullable()();

  /// UTC epoch millisecond
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {key};
}
