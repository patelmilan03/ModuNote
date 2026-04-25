import 'package:drift/drift.dart';

import '../converters/type_converters.dart';

@DataClassName('TagRow')
class TagsTable extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
