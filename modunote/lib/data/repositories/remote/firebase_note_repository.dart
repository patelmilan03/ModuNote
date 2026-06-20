import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/note.dart';
import '../interfaces/i_note_repository.dart';

/// Remote [INoteRepository] backed by Cloud Firestore.
///
/// Collection path: /users/{uid}/notes/{noteId}
/// Reads (watchAll, watchByTag, watchByCategory, findById, search) are all
/// kept local-only — they throw [UnimplementedError]. Only write operations
/// (insert, update, archive, delete, togglePin) are implemented here; they
/// are called by [SyncedNoteRepository.syncNote] on note-close and on
/// app-background events.
class FirebaseNoteRepository implements INoteRepository {
  const FirebaseNoteRepository();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _notes {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');
  }

  // ── Reads — local only ────────────────────────────────────────────────────

  @override
  Stream<List<Note>> watchAll() =>
      throw UnimplementedError('Reads stay local — use LocalNoteRepository');

  @override
  Stream<List<Note>> watchByTag(String tagId) =>
      throw UnimplementedError('Reads stay local — use LocalNoteRepository');

  @override
  Stream<List<Note>> watchByCategory(String categoryId) =>
      throw UnimplementedError('Reads stay local — use LocalNoteRepository');

  @override
  Stream<List<Note>> watchByCategoryIds(List<String> categoryIds) =>
      throw UnimplementedError('Reads stay local — use LocalNoteRepository');

  @override
  Stream<List<Note>> watchArchived() =>
      throw UnimplementedError('Reads stay local — use LocalNoteRepository');

  @override
  Future<Note?> findById(String id) =>
      throw UnimplementedError('Reads stay local — use LocalNoteRepository');

  @override
  Future<List<Note>> search(String query) =>
      throw UnimplementedError('Search stays local — Firestore has no FTS5');

  // ── Writes — Firestore upsert ─────────────────────────────────────────────

  @override
  Future<void> insert(Note note) => _upsert(note);

  @override
  Future<void> update(Note note) => _upsert(note);

  @override
  Future<void> archive(String id) async {
    final col = _notes;
    if (col == null) return;
    try {
      await col.doc(id).update({
        'isArchived': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'syncStatus': 'synced',
      });
    } catch (e) {
      debugPrint('FirebaseNoteRepository.archive: $e');
    }
  }

  @override
  Future<void> unarchive(String id) async {
    final col = _notes;
    if (col == null) return;
    try {
      await col.doc(id).update({
        'isArchived': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'syncStatus': 'synced',
      });
    } catch (e) {
      debugPrint('FirebaseNoteRepository.unarchive: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    final col = _notes;
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (e) {
      debugPrint('FirebaseNoteRepository.delete: $e');
    }
  }

  @override
  Future<void> togglePin(String id) async {
    final col = _notes;
    if (col == null) return;
    try {
      final snap = await col.doc(id).get();
      if (!snap.exists) return;
      final current = snap.data()?['isPinned'] as bool? ?? false;
      await col.doc(id).update({
        'isPinned': !current,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'syncStatus': 'synced',
      });
    } catch (e) {
      debugPrint('FirebaseNoteRepository.togglePin: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _upsert(Note note) async {
    final col = _notes;
    if (col == null) return;
    try {
      await col.doc(note.id).set(_toMap(note));
    } catch (e) {
      debugPrint('FirebaseNoteRepository._upsert: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _toMap(Note note) => {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'categoryId': note.categoryId,
        'tagIds': note.tagIds,
        'isPinned': note.isPinned,
        'isArchived': note.isArchived,
        'createdAt': Timestamp.fromDate(note.createdAt),
        'updatedAt': Timestamp.fromDate(note.updatedAt),
        'syncStatus': 'synced',
      };
}
