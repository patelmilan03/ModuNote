import 'package:drift/drift.dart';

import '../converters/type_converters.dart';

@DataClassName('NoteRow')
class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text().map(const QuillDeltaConverter())();
  TextColumn get categoryId => text().nullable()();
  TextColumn get tagIds =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};
}
