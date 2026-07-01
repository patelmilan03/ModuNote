import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/models/note.dart';

void main() {
  Note buildNote() => Note(
        id: 'n1',
        title: 'Title',
        content: const {'ops': []},
        categoryId: 'c1',
        tagIds: const ['t1', 't2'],
        isPinned: true,
        isArchived: false,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
        syncStatus: SyncStatus.synced,
      );

  group('Note', () {
    test('value equality is by content, not identity', () {
      expect(buildNote(), equals(buildNote()));
      expect(buildNote().hashCode, equals(buildNote().hashCode));
    });

    test('differs when any field differs', () {
      expect(buildNote(), isNot(equals(buildNote().copyWith(title: 'Other'))));
      expect(
        buildNote(),
        isNot(equals(buildNote().copyWith(tagIds: const ['t1']))),
      );
    });

    test('copyWith overrides only the given fields', () {
      final updated = buildNote().copyWith(
        title: 'New',
        isPinned: false,
        syncStatus: SyncStatus.pending,
      );

      expect(updated.title, 'New');
      expect(updated.isPinned, false);
      expect(updated.syncStatus, SyncStatus.pending);
      // Untouched fields are preserved.
      expect(updated.id, 'n1');
      expect(updated.categoryId, 'c1');
      expect(updated.tagIds, const ['t1', 't2']);
      expect(updated.createdAt, DateTime.utc(2024, 1, 1));
    });

    test('copyWith with no args returns an equal note', () {
      expect(buildNote().copyWith(), equals(buildNote()));
    });

    test(
        'copyWith cannot clear categoryId (documents the nullable-copyWith '
        'limitation — setCategory(null) bypasses copyWith in the view-model)',
        () {
      final cleared = buildNote().copyWith(categoryId: null);
      // Passing null falls back to the existing value, so the category remains.
      expect(cleared.categoryId, 'c1');
    });

    test('defaults match the documented model contract', () {
      final n = Note(
        id: 'x',
        title: '',
        content: const {},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );
      expect(n.categoryId, isNull);
      expect(n.tagIds, isEmpty);
      expect(n.isPinned, false);
      expect(n.isArchived, false);
      expect(n.syncStatus, SyncStatus.local);
    });
  });
}
