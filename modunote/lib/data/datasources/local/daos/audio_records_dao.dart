import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/audio_records_table.dart';

part 'audio_records_dao.g.dart';

@DriftAccessor(tables: [AudioRecordsTable])
class AudioRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$AudioRecordsDaoMixin {
  AudioRecordsDao(super.db);

  // ── Watch queries ──────────────────────────────────────────────────────────

  Stream<List<AudioRecordRow>> watchByNote(String noteId) {
    return (select(audioRecordsTable)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  // ── Single-shot queries ────────────────────────────────────────────────────

  Future<AudioRecordRow?> findById(String id) {
    return (select(audioRecordsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<AudioRecordRow>> findByNote(String noteId) {
    return (select(audioRecordsTable)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> totalFileSizeBytes() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(file_size_bytes), 0) AS total FROM audio_records',
    ).getSingle();
    return result.data['total'] as int? ?? 0;
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> insertAudioRecord(AudioRecordsTableCompanion c) async {
    await into(audioRecordsTable).insert(c);
  }

  Future<void> updateTranscription(String id, String text) async {
    await (update(audioRecordsTable)..where((t) => t.id.equals(id))).write(
      AudioRecordsTableCompanion(transcribedText: Value(text)),
    );
  }

  Future<int> deleteAudioRecord(String id) {
    return (delete(audioRecordsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAllForNote(String noteId) {
    return (delete(audioRecordsTable)..where((t) => t.noteId.equals(noteId)))
        .go();
  }
}
