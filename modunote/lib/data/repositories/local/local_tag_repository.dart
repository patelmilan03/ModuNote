import '../../../core/errors/app_exception.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../models/tag.dart';
import '../../repositories/interfaces/i_tag_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/local/daos/tags_dao.dart';

/// Local Drift implementation of [ITagRepository].
///
/// Tag names are always stored lowercase-normalised (via
/// [StringExtensions.normalised]) before any write operation so that
/// "Travel", "travel", and "TRAVEL" are treated as the same tag at the DB
/// level. The SQLite UNIQUE constraint on [TagsTable.name] provides a
/// secondary safety net for concurrent writes.
class LocalTagRepository implements ITagRepository {
  final TagsDao _tagsDao;

  const LocalTagRepository(this._tagsDao);

  // ── Watch streams ──────────────────────────────────────────────────────────

  @override
  Stream<List<Tag>> watchAll() {
    return _tagsDao
        .watchAll()
        .map((rows) => rows.map(_rowToTag).toList());
  }

  // ── Single-shot reads ──────────────────────────────────────────────────────

  @override
  Future<List<Tag>> searchByPrefix(String prefix) async {
    try {
      final normalised = prefix.normalised;
      final rows = await _tagsDao.searchByPrefix(normalised);
      return rows.map(_rowToTag).toList();
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to search tags by prefix: "$prefix"',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Tag?> findByName(String name) async {
    try {
      final row = await _tagsDao.findByName(name.normalised);
      return row == null ? null : _rowToTag(row);
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to find tag by name: "$name"',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Tag?> findById(String id) async {
    try {
      final row = await _tagsDao.findById(id);
      return row == null ? null : _rowToTag(row);
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to find tag by id: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Tag>> findByNote(String noteId) async {
    try {
      final rows = await _tagsDao.findByNote(noteId);
      return rows.map(_rowToTag).toList();
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to find tags for note: $noteId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<Tag> insert(String name) async {
    final normalised = name.normalised;
    if (normalised.isEmpty) {
      throw const ValidationException('Tag name cannot be blank');
    }

    try {
      final now = DateTime.now().toUtc();
      final tag = Tag(
        id: UuidGenerator.generate(),
        name: normalised,
        createdAt: now,
      );
      await _tagsDao.insertTag(
        TagRowCompanion.insert(
          id: tag.id,
          name: tag.name,
          createdAt: tag.createdAt,
        ),
      );
      return tag;
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to insert tag: "$name"',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _tagsDao.deleteTag(id);
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to delete tag: $id',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> addTagToNote(String noteId, String tagId) async {
    try {
      await _tagsDao.addTagToNote(noteId, tagId);
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to add tag $tagId to note $noteId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> removeTagFromNote(String noteId, String tagId) async {
    try {
      await _tagsDao.removeTagFromNote(noteId, tagId);
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to remove tag $tagId from note $noteId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    try {
      await _tagsDao.setTagsForNote(noteId, tagIds);
    } on Exception catch (e, st) {
      throw DatabaseException(
        'Failed to set tags for note: $noteId',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  // ── Mapping ────────────────────────────────────────────────────────────────

  Tag _rowToTag(TagRow row) => Tag(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
      );
}
