import 'package:drift/drift.dart';

import '../../datasources/local/app_database.dart';
import '../../datasources/local/daos/audio_records_dao.dart';
import '../../models/audio_record.dart';
import '../../repositories/interfaces/i_audio_record_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Drift-backed implementation of [IAudioRecordRepository].
class LocalAudioRecordRepository implements IAudioRecordRepository {
  const LocalAudioRecordRepository(this._dao);

  final AudioRecordsDao _dao;

  @override
  Stream<List<AudioRecord>> watchByNote(String noteId) {
    return _dao.watchByNote(noteId).map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  @override
  Future<List<AudioRecord>> findByNote(String noteId) async {
    try {
      final rows = await _dao.findByNote(noteId);
      return rows.map(_fromRow).toList();
    } on Exception catch (e) {
      throw DatabaseException('Failed to fetch audio records for note', cause: e);
    }
  }

  @override
  Future<AudioRecord?> findById(String id) async {
    try {
      final row = await _dao.findById(id);
      return row == null ? null : _fromRow(row);
    } on Exception catch (e) {
      throw DatabaseException('Failed to fetch audio record', cause: e);
    }
  }

  @override
  Future<void> insert(AudioRecord record) async {
    try {
      await _dao.insertAudioRecord(
        AudioRecordsTableCompanion.insert(
          id: record.id,
          noteId: record.noteId,
          filePath: record.filePath,
          durationMs: record.durationMs,
          fileSizeBytes: record.fileSizeBytes,
          codec: Value(record.codec),
          transcribedText: Value(record.transcribedText),
          createdAt: record.createdAt,
        ),
      );
    } on Exception catch (e) {
      throw DatabaseException('Failed to insert audio record', cause: e);
    }
  }

  @override
  Future<void> updateTranscription(String id, String text) async {
    try {
      await _dao.updateTranscription(id, text);
    } on Exception catch (e) {
      throw DatabaseException('Failed to update audio transcription', cause: e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dao.deleteAudioRecord(id);
    } on Exception catch (e) {
      throw DatabaseException('Failed to delete audio record', cause: e);
    }
  }

  @override
  Future<void> deleteAllForNote(String noteId) async {
    try {
      await _dao.deleteAllForNote(noteId);
    } on Exception catch (e) {
      throw DatabaseException('Failed to delete audio records for note', cause: e);
    }
  }

  // ─── Mapping ──────────────────────────────────────────────────────────────

  AudioRecord _fromRow(AudioRecordRow row) => AudioRecord(
        id: row.id,
        noteId: row.noteId,
        filePath: row.filePath,
        durationMs: row.durationMs,
        fileSizeBytes: row.fileSizeBytes,
        codec: row.codec,
        transcribedText: row.transcribedText,
        createdAt: row.createdAt,
      );
}
