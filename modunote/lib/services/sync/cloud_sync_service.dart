import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/database_providers.dart';

part 'cloud_sync_service.g.dart';

/// Full cloud backup + restore for notes, tags, and categories (Phase 13).
///
/// Replaces the notes-only, write-only sync. With Google sign-in giving a STABLE
/// uid, this makes data durable: [backupToCloud] pushes everything to Firestore
/// on app-background, and [restoreFromCloud] pulls it back on sign-in — so a
/// reinstall or new device restores notes, tags, and the full category
/// hierarchy (categories carry `parentId` + `sortOrder`).
///
/// Firestore layout (all under the signed-in uid):
///   /users/{uid}/notes/{noteId}
///   /users/{uid}/tags/{tagId}
///   /users/{uid}/categories/{categoryId}
///
/// Restore is atomic (single Drift transaction) and never clobbers newer local
/// edits: tags/categories are inserted only when absent locally (tags de-duped
/// by NAME to respect the UNIQUE(name) constraint), and a note is overwritten
/// only when the cloud copy is newer (by `updatedAt`) or missing locally.
@Riverpod(keepAlive: true)
CloudSyncService cloudSyncService(Ref ref) =>
    CloudSyncService(ref.watch(appDatabaseProvider));

class CloudSyncService {
  CloudSyncService(this._db);

  final AppDatabase _db;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _col(String name) {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(name);
  }

  // ── Backup (local → cloud) ──────────────────────────────────────────────

  /// Pushes every local note/tag/category to Firestore. Best-effort: logs and
  /// returns on any error. No-op when signed out.
  ///
  /// Commits in chunks of ≤450 ops — a single Firestore WriteBatch is capped at
  /// 500, and an over-limit commit would otherwise throw and back up nothing.
  Future<void> backupToCloud() async {
    final notesCol = _col('notes');
    final tagsCol = _col('tags');
    final catsCol = _col('categories');
    if (notesCol == null || tagsCol == null || catsCol == null) return;
    try {
      final ops =
          <(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>[];
      for (final n in await _db.select(_db.notesTable).get()) {
        ops.add((notesCol.doc(n.id), _noteToMap(n)));
      }
      for (final t in await _db.select(_db.tagsTable).get()) {
        ops.add((tagsCol.doc(t.id), _tagToMap(t)));
      }
      for (final c in await _db.select(_db.categoriesTable).get()) {
        ops.add((catsCol.doc(c.id), _categoryToMap(c)));
      }
      const chunkSize = 450;
      for (var i = 0; i < ops.length; i += chunkSize) {
        final batch = FirebaseFirestore.instance.batch();
        for (final (ref, data) in ops.skip(i).take(chunkSize)) {
          batch.set(ref, data);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('CloudSyncService.backupToCloud: $e');
    }
  }

  // ── Restore (cloud → local) ─────────────────────────────────────────────

  /// Pulls cloud data into local Drift, atomically. Categories → tags → notes →
  /// join rows, so foreign keys resolve. Returns the number of notes written.
  /// Throws on a hard failure (and rolls back) so the caller can surface it —
  /// the app still works locally.
  Future<int> restoreFromCloud() async {
    final notesCol = _col('notes');
    final tagsCol = _col('tags');
    final catsCol = _col('categories');
    if (notesCol == null || tagsCol == null || catsCol == null) return 0;

    // Do the network reads first so the DB transaction below never waits on I/O.
    final catDocs = (await catsCol.get()).docs;
    final tagDocs = (await tagsCol.get()).docs;
    final noteDocs = (await notesCol.get()).docs;

    return _db.transaction(() async {
      // ── Categories: insert those missing locally (by id). ──
      final knownCatIds =
          (await _db.select(_db.categoriesTable).get()).map((c) => c.id).toSet();
      for (final doc in catDocs) {
        final data = doc.data();
        final id = (data['id'] as String?) ?? doc.id;
        if (knownCatIds.contains(id)) continue;
        await _db
            .into(_db.categoriesTable)
            .insertOnConflictUpdate(_mapToCategoryCompanion(data, id));
        knownCatIds.add(id);
      }

      // ── Tags: de-dupe by NAME (tags.name is UNIQUE), not just id. Build a
      //    cloud-id → effective-local-id remap for the note joins below. ──
      final localTags = await _db.select(_db.tagsTable).get();
      final localTagIds = {for (final t in localTags) t.id};
      final localIdByName = {for (final t in localTags) t.name: t.id};
      final tagRemap = <String, String>{};
      for (final doc in tagDocs) {
        final data = doc.data();
        final id = (data['id'] as String?) ?? doc.id;
        final name = (data['name'] as String?) ?? '';
        if (localTagIds.contains(id)) {
          tagRemap[id] = id; // same tag already present locally
          continue;
        }
        final existingByName = localIdByName[name];
        if (existingByName != null) {
          tagRemap[id] = existingByName; // name collision → reuse local tag
          continue;
        }
        await _db
            .into(_db.tagsTable)
            .insertOnConflictUpdate(_mapToTagCompanion(data, id));
        localTagIds.add(id);
        localIdByName[name] = id;
        tagRemap[id] = id;
      }

      // ── Notes: overwrite only when the cloud copy is newer or missing. ──
      final localNoteUpdatedAt = {
        for (final n in await _db.select(_db.notesTable).get())
          n.id: n.updatedAt,
      };
      var written = 0;
      for (final doc in noteDocs) {
        final data = doc.data();
        final id = (data['id'] as String?) ?? doc.id;
        final cloudUpdated = _toDate(data['updatedAt']);
        final localUpdated = localNoteUpdatedAt[id];
        if (localUpdated != null && !cloudUpdated.isAfter(localUpdated)) continue;

        // Only reference a category that actually exists (avoid an orphan FK).
        final rawCatId = data['categoryId'] as String?;
        final categoryId = (rawCatId != null && knownCatIds.contains(rawCatId))
            ? rawCatId
            : null;

        // Remap the note's tag ids to their effective local ids, dropping any
        // whose tag couldn't be restored, and de-dupe.
        final effectiveTagIds = <String>{
          for (final t
              in (data['tagIds'] as List?)?.whereType<String>() ??
                  const <String>[])
            if (tagRemap[t] != null) tagRemap[t]!,
        }.toList();

        await _db.into(_db.notesTable).insertOnConflictUpdate(
              _mapToNoteCompanion(
                  data, id, cloudUpdated, categoryId, effectiveTagIds),
            );
        written++;

        // Rebuild join rows from scratch (prune stale, add current) so the join
        // table and the denormalised `tagIds` column stay in agreement.
        await (_db.delete(_db.noteTagsTable)..where((t) => t.noteId.equals(id)))
            .go();
        for (final tagId in effectiveTagIds) {
          await _db.into(_db.noteTagsTable).insertOnConflictUpdate(
                NoteTagsTableCompanion.insert(noteId: id, tagId: tagId),
              );
        }
      }
      return written;
    });
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _noteToMap(NoteRow n) => {
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'categoryId': n.categoryId,
        'tagIds': n.tagIds,
        'isPinned': n.isPinned,
        'isArchived': n.isArchived,
        'createdAt': Timestamp.fromDate(n.createdAt),
        'updatedAt': Timestamp.fromDate(n.updatedAt),
        'syncStatus': 'synced',
      };

  Map<String, dynamic> _tagToMap(TagRow t) => {
        'id': t.id,
        'name': t.name,
        'createdAt': Timestamp.fromDate(t.createdAt),
      };

  Map<String, dynamic> _categoryToMap(CategoryRow c) => {
        'id': c.id,
        'name': c.name,
        'parentId': c.parentId,
        'sortOrder': c.sortOrder,
        'createdAt': Timestamp.fromDate(c.createdAt),
      };

  NotesTableCompanion _mapToNoteCompanion(
    Map<String, dynamic> m,
    String id,
    DateTime updatedAt,
    String? categoryId,
    List<String> tagIds,
  ) =>
      NotesTableCompanion.insert(
        id: id,
        title: (m['title'] as String?) ?? '',
        content: m['content'] is Map
            ? Map<String, dynamic>.from(m['content'] as Map)
            : const <String, dynamic>{},
        categoryId: drift.Value(categoryId),
        tagIds: drift.Value(tagIds),
        isPinned: drift.Value((m['isPinned'] as bool?) ?? false),
        isArchived: drift.Value((m['isArchived'] as bool?) ?? false),
        createdAt: _toDate(m['createdAt']),
        updatedAt: updatedAt,
        syncStatus: const drift.Value('synced'),
      );

  TagsTableCompanion _mapToTagCompanion(Map<String, dynamic> m, String id) =>
      TagsTableCompanion.insert(
        id: id,
        name: (m['name'] as String?) ?? '',
        createdAt: _toDate(m['createdAt']),
      );

  CategoriesTableCompanion _mapToCategoryCompanion(
    Map<String, dynamic> m,
    String id,
  ) =>
      CategoriesTableCompanion.insert(
        id: id,
        name: (m['name'] as String?) ?? '',
        parentId: drift.Value(m['parentId'] as String?),
        sortOrder: drift.Value((m['sortOrder'] as int?) ?? 0),
        createdAt: _toDate(m['createdAt']),
      );

  DateTime _toDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    // Missing/corrupt → epoch, so a note with no valid `updatedAt` can NEVER
    // win the "cloud newer" merge and clobber a real local edit.
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
