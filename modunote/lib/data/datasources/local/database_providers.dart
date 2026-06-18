import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../repositories/interfaces/i_audio_record_repository.dart';
import '../../repositories/interfaces/i_category_repository.dart';
import '../../repositories/interfaces/i_note_repository.dart';
import '../../repositories/interfaces/i_tag_repository.dart';
import '../../repositories/local/local_audio_record_repository.dart';
import '../../repositories/local/local_category_repository.dart';
import '../../repositories/local/local_note_repository.dart';
import '../../repositories/local/local_tag_repository.dart';
import '../../repositories/remote/firebase_note_repository.dart';
import '../../repositories/synced/synced_note_repository.dart';
import 'app_database.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(AppDatabase.createExecutor());
  ref.onDispose(db.close);
  return db;
}

/// Typed provider for [SyncedNoteRepository].
/// Used by [NoteEditorViewModel.syncNote] and [_AppShell] lifecycle observer
/// to call [SyncedNoteRepository.syncNote] / [SyncedNoteRepository.syncAllPending].
@Riverpod(keepAlive: true)
SyncedNoteRepository syncedNoteRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncedNoteRepository(
    local: LocalNoteRepository(db.notesDao),
    remote: const FirebaseNoteRepository(),
  );
}

/// [INoteRepository] used by all ViewModels. Delegates to [SyncedNoteRepository]
/// so the same instance handles both normal operations and explicit syncs.
@Riverpod(keepAlive: true)
INoteRepository noteRepository(Ref ref) {
  return ref.watch(syncedNoteRepositoryProvider);
}

@Riverpod(keepAlive: true)
ITagRepository tagRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalTagRepository(db.tagsDao);
}

@Riverpod(keepAlive: true)
ICategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalCategoryRepository(db.categoriesDao, db.notesDao);
}

@Riverpod(keepAlive: true)
IAudioRecordRepository audioRecordRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalAudioRecordRepository(db.audioRecordsDao);
}
