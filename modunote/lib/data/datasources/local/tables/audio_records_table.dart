import 'package:drift/drift.dart';

import '../converters/type_converters.dart';

@DataClassName('AudioRecordRow')
class AudioRecordsTable extends Table {
  @override
  String get tableName => 'audio_records';

  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get filePath => text()();
  IntColumn get durationMs => integer()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get codec => text().withDefault(const Constant('aac'))();
  TextColumn get transcribedText => text().nullable()();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
