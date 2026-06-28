import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/extensions/quill_extensions.dart';
import '../../data/datasources/local/database_providers.dart';
import '../../data/models/tag.dart';
import '../../services/remote/remote_note_service_provider.dart';
import 'rag_settings_view_model.dart';
import 'tag_list_view_model.dart';

part 'rag_reindex_view_model.g.dart';

/// Bulk re-indexer for RAG (Phase 12 Stage 2). Pushes every existing note that
/// carries a current scope tag to the backend, so the user doesn't have to
/// reopen each note one by one after changing the scope or fixing connectivity.
///
/// State = whether a re-index is currently running (drives the Settings button
/// spinner). The caller shows the result toast from the returned counts.
@riverpod
class RagReindex extends _$RagReindex {
  @override
  bool build() => false;

  /// Indexes every active note whose tags intersect the current scope set.
  /// Notes with no scope tag are skipped. Per-note failures are tolerated and
  /// counted. Returns `(ok, fail)` — `(0, 0)` means nothing matched.
  Future<({int ok, int fail})> reindexAll() async {
    if (state) return (ok: 0, fail: 0);
    state = true;
    var ok = 0;
    var fail = 0;
    try {
      final notes = await ref.read(noteRepositoryProvider).watchAll().first;
      final allTags = ref.read(tagListViewModelProvider).valueOrNull ?? <Tag>[];
      final nameById = {for (final t in allTags) t.id: t.name};
      final triggerTags = ref.read(ragIndexTagsProvider);
      final service = ref.read(remoteNoteServiceProvider);

      for (final note in notes) {
        final names = [
          for (final id in note.tagIds)
            if (nameById[id] != null) nameById[id]!,
        ];
        if (!names.any(triggerTags.contains)) continue;
        try {
          await service.indexNote(
            noteId: note.id,
            title: note.title,
            content: plainTextFromDelta(note.content),
            tags: names,
          );
          ok++;
        } catch (_) {
          fail++;
        }
      }
    } finally {
      state = false;
    }
    return (ok: ok, fail: fail);
  }
}
