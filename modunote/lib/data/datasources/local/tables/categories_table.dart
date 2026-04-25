import 'package:drift/drift.dart';

import '../converters/type_converters.dart';

@DataClassName('CategoryRow')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  // Self-referential parentId — FK integrity enforced at the repository layer.
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
