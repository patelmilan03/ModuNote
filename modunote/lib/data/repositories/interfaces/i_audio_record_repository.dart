import '../../models/audio_record.dart';

/// Contract for audio record persistence.
/// ViewModels import this interface; never the Drift DAO directly.
abstract interface class IAudioRecordRepository {
  /// Emits a new list whenever audio records for [noteId] change.
  Stream<List<AudioRecord>> watchByNote(String noteId);

  /// Returns current audio records for [noteId], ordered by createdAt ASC.
  Future<List<AudioRecord>> findByNote(String noteId);

  /// Returns the record with [id], or null if not found.
  Future<AudioRecord?> findById(String id);

  /// Inserts [record] into the database.
  Future<void> insert(AudioRecord record);

  /// Updates the transcribed text for the record with [id].
  Future<void> updateTranscription(String id, String text);

  /// Deletes the record with [id].
  /// Callers are responsible for deleting the audio file from disk.
  Future<void> delete(String id);

  /// Deletes all records associated with [noteId].
  /// Callers are responsible for deleting corresponding audio files from disk.
  Future<void> deleteAllForNote(String noteId);
}
