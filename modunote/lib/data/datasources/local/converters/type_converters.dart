import 'dart:convert';

import 'package:drift/drift.dart';

/// Converts a Quill Delta [Map<String, dynamic>] to/from a JSON [String].
///
/// On corrupt data, falls back to a single newline delta so the editor
/// never crashes on a bad row.
class QuillDeltaConverter extends TypeConverter<Map<String, dynamic>, String> {
  const QuillDeltaConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      return jsonDecode(fromDb) as Map<String, dynamic>;
    } catch (_) {
      return {
        'ops': [
          {'insert': '\n'}
        ]
      };
    }
  }

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}

/// Converts [DateTime] to/from a UTC millisecond epoch [int].
class DateTimeConverter extends TypeConverter<DateTime, int> {
  const DateTimeConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

/// Converts [List<String>] to/from a JSON-encoded [String].
///
/// On corrupt data, returns an empty list so the app never crashes.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    try {
      return (jsonDecode(fromDb) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
