import '../../models/tag.dart';

/// Contract for tag persistence operations.
abstract interface class ITagRepository {
  /// Streams all tags ordered alphabetically.
  Stream<List<Tag>> watchAll();

  /// Finds tags whose name starts with [prefix] (case-insensitive).
  /// Used for autocomplete in the note editor tag row.
  Future<List<Tag>> searchByPrefix(String prefix);

  /// Returns the tag with the given [name] (normalised), or null.
  Future<Tag?> findByName(String name);

  /// Returns all tags assigned to [noteId].
  Future<List<Tag>> findByNote(String noteId);

  /// Persists a new tag.
  Future<Tag> insert(Tag tag);

  /// Assigns [tagId] to [noteId] (inserts into join table).
  Future<void> addToNote({required String noteId, required String tagId});

  /// Removes [tagId] from [noteId].
  Future<void> removeFromNote({required String noteId, required String tagId});

  /// Replaces all tags on [noteId] with [tagIds].
  Future<void> setTagsForNote({required String noteId, required List<String> tagIds});

  /// Hard-deletes a tag and removes all its note associations.
  Future<void> delete(String id);
}
