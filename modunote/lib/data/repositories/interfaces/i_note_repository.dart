import '../../models/note.dart';

/// Contract for all note persistence operations.
/// Both local (Drift) and future synced (Firebase) implementations must satisfy this.
abstract interface class INoteRepository {
  /// Returns a stream of all non-archived notes, ordered by pinned first then updatedAt desc.
  Stream<List<Note>> watchAll();

  /// Returns a stream of notes filtered by [tagId].
  Stream<List<Note>> watchByTag(String tagId);

  /// Returns a stream of notes under [categoryId].
  Stream<List<Note>> watchByCategory(String categoryId);

  /// Returns a single note by [id], or null if not found.
  Future<Note?> findById(String id);

  /// Full-text search across title and content.
  Future<List<Note>> search(String query);

  /// Persists a new note. [note.id] must be a fresh UUID.
  Future<void> insert(Note note);

  /// Updates all fields of an existing note matched by [note.id].
  Future<void> update(Note note);

  /// Soft-deletes by setting [isArchived] = true.
  Future<void> archive(String id);

  /// Hard-deletes. Irreversible.
  Future<void> delete(String id);

  /// Toggles the [isPinned] flag.
  Future<void> togglePin(String id);
}
