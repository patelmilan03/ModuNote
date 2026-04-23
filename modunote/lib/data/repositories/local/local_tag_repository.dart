import 'package:drift/drift.dart';

import '../../../core/utils/uuid_generator.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../datasources/local/app_database.dart';
import '../../models/tag.dart';
import '../interfaces/i_tag_repository.dart';

class LocalTagRepository implements ITagRepository {
  const LocalTagRepository(this._dao);

  final TagsDao _dao;

  // ─── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<Tag>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  // ─── Reads ───────────────────────────────────────────────────────────────────

  @override
  Future<List<Tag>> searchByPrefix(String prefix) async {
    final rows = await _dao.searchByPrefix(prefix);
    return rows.map(_toModel).toList();
  }

  @override
  Future<Tag?> findByName(String name) async {
    final row = await _dao.findByName(name.normalised);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<Tag>> findByNote(String noteId) async {
    final rows = await _dao.findByNote(noteId);
    return rows.map(_toModel).toList();
  }

  // ─── Writes ──────────────────────────────────────────────────────────────────

  @override
  Future<Tag> insert(Tag tag) async {
    final normalised = tag.copyWith(name: tag.name.normalised);
    await _dao.insertTag(TagsTableCompanion(
      id: Value(normalised.id),
      name: Value(normalised.name),
      createdAt: Value(normalised.createdAt),
    ));
    return normalised;
  }

  @override
  Future<void> addToNote({required String noteId, required String tagId}) =>
      _dao.addTagToNote(noteId: noteId, tagId: tagId);

  @override
  Future<void> removeFromNote({required String noteId, required String tagId}) =>
      _dao.removeTagFromNote(noteId: noteId, tagId: tagId);

  @override
  Future<void> setTagsForNote({
    required String noteId,
    required List<String> tagIds,
  }) =>
      _dao.setTagsForNote(noteId: noteId, tagIds: tagIds);

  @override
  Future<void> delete(String id) => _dao.deleteTag(id);

  // ─── Mapping ─────────────────────────────────────────────────────────────────

  Tag _toModel(TagRow row) => Tag(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
      );
}
