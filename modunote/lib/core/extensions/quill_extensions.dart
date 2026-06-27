// Helpers for Quill Delta content stored on `Note.content`.

/// Extracts plain text from a Quill Delta document map (`{'ops': [...]}`).
///
/// Used to build request bodies for the AI backend, which operates on plain
/// text rather than Delta JSON. Non-string inserts (embeds) are skipped.
String plainTextFromDelta(Map<String, dynamic> content) {
  final ops = content['ops'];
  if (ops is! List) return '';
  final buffer = StringBuffer();
  for (final op in ops) {
    if (op is Map && op['insert'] is String) {
      buffer.write(op['insert'] as String);
    }
  }
  return buffer.toString().trim();
}
