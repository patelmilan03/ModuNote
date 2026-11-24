import 'dart:convert';

import '../../../core/extensions/quill_extensions.dart';

/// Thrown when a note's serialised Delta is too large for one Firestore
/// document (hard limit 1 MiB per document).
class NoteTooLargeException implements Exception {
  const NoteTooLargeException(this.noteId, this.bytes);

  final String noteId;
  final int bytes;

  @override
  String toString() =>
      'NoteTooLargeException: note $noteId is $bytes bytes of Delta JSON '
      '(limit ${NoteCloudCodec.maxContentJsonBytes}).';
}

/// Single place that defines how a note's rich-text body is stored in Firestore
/// and read back, so the write paths (`CloudSyncService.backupToCloud`,
/// `FirebaseNoteRepository._upsert`) and the restore path can never drift apart.
///
/// Schema v2 stores the Quill Delta as an opaque JSON **string**:
///
/// ```
/// contentJson   : String  — jsonEncode({'ops': [...]}), the source of truth
/// contentText   : String  — plain-text copy (search / AI / debugging only)
/// schemaVersion : int     — 2
/// ```
///
/// A string round-trips byte-for-byte: no Firestore map/array type coercion,
/// no field-name or nesting restrictions, and the console shows it verbatim.
///
/// Reading is lenient so notes already in the cloud keep working:
/// v2 `contentJson` → legacy `content` Map → legacy `content` JSON/plain
/// String → `contentText` → an empty document.
class NoteCloudCodec {
  const NoteCloudCodec._();

  static const int schemaVersion = 2;

  /// Firestore caps a document at 1 MiB total; leave headroom for the title,
  /// ids, tag list and timestamps. Delta JSON is ASCII-escaped by `jsonEncode`
  /// only for control chars, so UTF-8 byte length is the right measure.
  static const int maxContentJsonBytes = 900 * 1024;

  /// The three Firestore fields that carry a note's body.
  /// Throws [NoteTooLargeException] when the Delta would not fit.
  static Map<String, Object> encodeContent(
    String noteId,
    Map<String, dynamic> content,
  ) {
    final json = jsonEncode(content);
    final bytes = utf8.encode(json).length;
    if (bytes > maxContentJsonBytes) {
      throw NoteTooLargeException(noteId, bytes);
    }
    return {
      'contentJson': json,
      'contentText': plainTextFromDelta(content),
      'schemaVersion': schemaVersion,
    };
  }

  /// Rebuilds a Delta map (`{'ops': [...]}`) from a Firestore note document.
  /// Never throws: anything unreadable degrades to the best text available.
  static Map<String, dynamic> decodeContent(Map<String, dynamic> doc) {
    // 1. v2: Delta JSON string.
    final fromJson = _deltaFromJsonString(doc['contentJson']);
    if (fromJson != null) return _withTrailingNewline(fromJson);

    // 2. Legacy: `content` was written as a Firestore map.
    final legacy = doc['content'];
    if (legacy is Map) {
      final normalised = _normalise(legacy);
      if (normalised is Map<String, dynamic> && normalised['ops'] is List) {
        return _withTrailingNewline(normalised);
      }
    }

    // 3. Legacy: `content` was a string — either Delta JSON or plain text.
    if (legacy is String) {
      final parsed = _deltaFromJsonString(legacy);
      return parsed != null
          ? _withTrailingNewline(parsed)
          : _deltaFromPlainText(legacy);
    }

    // 4. Last resort: the plain-text copy.
    final text = doc['contentText'];
    if (text is String && text.isNotEmpty) return _deltaFromPlainText(text);

    return _deltaFromPlainText('');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, dynamic>? _deltaFromJsonString(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        return decoded;
      }
      // Some Delta serialisers emit the bare ops list.
      if (decoded is List) return {'ops': decoded};
    } catch (_) {
      // Not JSON — caller falls through to the next strategy.
    }
    return null;
  }

  /// A Quill document must end with a newline. Some old cloud docs hold a
  /// single un-terminated insert (e.g. `{insert: "text "}`), which the editor
  /// can reject and replace with an empty document — so add the newline here.
  static Map<String, dynamic> _withTrailingNewline(Map<String, dynamic> delta) {
    final ops = (delta['ops'] as List).toList();
    if (ops.isEmpty) return _deltaFromPlainText('');
    final last = ops.last;
    final insert = last is Map ? last['insert'] : null;
    if (insert is String && insert.endsWith('\n')) return delta;
    return {
      ...delta,
      'ops': [
        ...ops,
        {'insert': '\n'},
      ],
    };
  }

  static Map<String, dynamic> _deltaFromPlainText(String text) {
    final body = text.endsWith('\n') ? text : '$text\n';
    return {
      'ops': [
        {'insert': body},
      ],
    };
  }

  /// Deep-converts Firestore-decoded maps/lists into plain JSON-typed
  /// `Map<String, dynamic>` / `List<dynamic>` so later casts never fail.
  static Object? _normalise(Object? v) {
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): _normalise(e.value)};
    }
    if (v is List) return [for (final e in v) _normalise(e)];
    return v;
  }
}
