import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/uuid_generator.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/audio_record.dart';

part 'audio_editor_view_model.g.dart';

/// Manages the list of [AudioRecord]s attached to a single note.
///
/// Usage:
///   ref.watch(audioEditorViewModelProvider(noteId: id))
///   ref.read(audioEditorViewModelProvider(noteId: id).notifier).saveRecording(...)
@riverpod
class AudioEditorViewModel extends _$AudioEditorViewModel {
  @override
  Stream<List<AudioRecord>> build({required String noteId}) {
    return ref
        .watch(audioRecordRepositoryProvider)
        .watchByNote(noteId);
  }

  /// Persists a newly completed recording and returns the saved [AudioRecord].
  Future<AudioRecord> saveRecording({
    required String filePath,
    required int durationMs,
    required int fileSizeBytes,
    String? transcript,
  }) async {
    final record = AudioRecord(
      id: UuidGenerator.generate(),
      noteId: noteId,
      filePath: filePath,
      durationMs: durationMs,
      fileSizeBytes: fileSizeBytes,
      transcribedText: transcript?.trim().isEmpty ?? true ? null : transcript,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(audioRecordRepositoryProvider).insert(record);
      return record;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Deletes the DB row for [id].
  /// The caller must delete the audio file from disk via [AudioFileStorage].
  Future<void> deleteRecord(String id) async {
    try {
      await ref.read(audioRecordRepositoryProvider).delete(id);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
