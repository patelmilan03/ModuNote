import '../../models/note.dart';
import '../interfaces/i_note_repository.dart';

/// [INoteRepository] that routes read/write operations through [_local] for
/// all standard app interactions, while providing explicit sync methods
/// ([syncNote], [syncAllPending]) that push note state to [_remote].
///
/// Sync is triggered explicitly — on note-close and on app-background events
/// — not on every auto-save keystroke.
class SyncedNoteRepository implements INoteRepository {
  const SyncedNoteRepository({
    required INoteRepository local,
    required INoteRepository remote,
  })  : _local = local,
        _remote = remote;

  final INoteRepository _local;
  final INoteRepository _remote;

  // ── Watch streams ──────────────────────────────────────────────────────────

  @override
  Stream<List<Note>> watchAll() => _local.watchAll();

  @override
  Stream<List<Note>> watchByTag(String tagId) => _local.watchByTag(tagId);

  @override
  Stream<List<Note>> watchByCategory(String categoryId) =>
      _local.watchByCategory(categoryId);

  @override
  Stream<List<Note>> watchByCategoryIds(List<String> categoryIds) =>
      _local.watchByCategoryIds(categoryIds);

  @override
  Stream<List<Note>> watchArchived() => _local.watchArchived();

  // ── Single-shot reads ──────────────────────────────────────────────────────

  @override
  Future<Note?> findById(String id) => _local.findById(id);

  @override
  Future<List<Note>> search(String query) => _local.search(query);

  // ── Mutations — all go to local only ──────────────────────────────────────

  @override
  Future<void> insert(Note note) => _local.insert(note);

  @override
  Future<void> update(Note note) => _local.update(note);

  @override
  Future<void> archive(String id) => _local.archive(id);

  @override
  Future<void> unarchive(String id) => _local.unarchive(id);

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> togglePin(String id) => _local.togglePin(id);

  // ── Explicit sync ─────────────────────────────────────────────────────────

  /// Reads [noteId] from local storage, pushes it to Firestore, then marks
  /// the local copy as [SyncStatus.synced].
  ///
  /// Returns [SyncStatus.synced] on success, [SyncStatus.local] on any error
  /// (network failure, Firebase not configured, user not signed in).
  Future<SyncStatus> syncNote(String noteId) async {
    try {
      final note = await _local.findById(noteId);
      if (note == null) return SyncStatus.local;
      await _remote.update(note);
      await _local.update(note.copyWith(syncStatus: SyncStatus.synced));
      return SyncStatus.synced;
    } catch (_) {
      return SyncStatus.local;
    }
  }

  /// Reads all local notes that are not yet [SyncStatus.synced] and syncs
  /// each one. Called on AppLifecycleState.paused (best-effort, fire-and-forget).
  Future<void> syncAllPending() async {
    try {
      final all = await _local.watchAll().first;
      final pending =
          all.where((n) => n.syncStatus != SyncStatus.synced).toList();
      for (final note in pending) {
        await syncNote(note.id);
      }
    } catch (_) {}
  }
}
