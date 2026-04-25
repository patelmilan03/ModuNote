import '../../models/tag.dart';

/// Contract for tag persistence operations.
abstract interface class ITagRepository {
  /// Streams all tags ordered alphabetically.
  Stream<List<Tag>> watchAll();

  /// Finds tags whose name starts with [prefix] (case-insensitive).
  Future<List<Tag>> searchByPrefix(String prefix);

  /// Returns the tag with the given [name] (normalised), or null.
  Future<Tag?> findByName(String name);

  /// Returns the tag with the given [id], or null.
  Future<Tag?> findById(String id);

  /// Returns all tags assigned to [noteId].
  Future<List<Tag>> findByNote(String noteId);

  /// Creates and persists a new tag from [name]. Returns the created tag.
  Future<Tag> insert(String name);

  /// Assigns [tagId] to [noteId] (inserts into join table).
  Future<void> addTagToNote(String noteId, String tagId);

  /// Removes [tagId] from [noteId].
  Future<void> removeTagFromNote(String noteId, String tagId);

  /// Atomically replaces all tags on [noteId] with [tagIds].
  Future<void> setTagsForNote(String noteId, List<String> tagIds);

  /// Hard-deletes a tag and removes all its note associations.
  Future<void> delete(String id);
}
