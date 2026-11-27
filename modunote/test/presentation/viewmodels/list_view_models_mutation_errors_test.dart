import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/category.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/data/repositories/interfaces/i_category_repository.dart';
import 'package:modunote/presentation/viewmodels/archived_notes_view_model.dart';
import 'package:modunote/presentation/viewmodels/category_tree_view_model.dart';

import '../../util/mocks.dart';

class _MockCategoryRepository extends Mock implements ICategoryRepository {}

/// Stream-backed list view-models must keep their list on screen when a
/// mutation fails: the failed write changes nothing, so no stream emission
/// would ever replace an error state.
void main() {
  // The view-models report failures through the app-wide toast helper, which
  // looks up a global navigator key (a no-op when no app is mounted).
  TestWidgetsFlutterBinding.ensureInitialized();

  final note = Note(
    id: 'n1',
    title: 'n1',
    content: const {'ops': []},
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
  final category = Category(
    id: 'c1',
    name: 'Ideas',
    sortOrder: 0,
    createdAt: DateTime.utc(2024),
  );

  test('ArchivedNotesViewModel keeps the list when restore/delete fail',
      () async {
    final repo = MockNoteRepository();
    when(() => repo.watchArchived()).thenAnswer((_) => Stream.value([note]));
    when(() => repo.unarchive(any()))
        .thenThrow(const DatabaseException('restore failed'));
    when(() => repo.delete(any())).thenThrow(StateError('boom'));

    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(archivedNotesViewModelProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(archivedNotesViewModelProvider.future);
    final vm = container.read(archivedNotesViewModelProvider.notifier);

    await vm.restore('n1');
    await vm.delete('n1');

    final state = container.read(archivedNotesViewModelProvider);
    expect(state.hasError, isFalse);
    expect(state.valueOrNull?.map((n) => n.id), ['n1']);
  });

  group('CategoryTreeViewModel', () {
    late _MockCategoryRepository repo;
    late ProviderContainer container;

    setUp(() async {
      repo = _MockCategoryRepository();
      when(() => repo.watchAll()).thenAnswer((_) => Stream.value([category]));
      container = ProviderContainer(
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(categoryTreeViewModelProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(categoryTreeViewModelProvider.future);
    });

    test('a failed move or delete keeps the category list', () async {
      when(() => repo.move(any(), any()))
          .thenThrow(const ValidationException('too deep'));
      when(() => repo.delete(any())).thenThrow(StateError('boom'));
      final vm = container.read(categoryTreeViewModelProvider.notifier);

      await vm.move('c1', 'c2');
      await vm.delete('c1');

      final state = container.read(categoryTreeViewModelProvider);
      expect(state.hasError, isFalse);
      expect(state.valueOrNull?.map((c) => c.id), ['c1']);
    });

    test('a failed insert still rethrows but keeps the list', () async {
      when(() => repo.insert(
            name: any(named: 'name'),
            parentId: any(named: 'parentId'),
            sortOrder: any(named: 'sortOrder'),
          )).thenThrow(const ValidationException('Maximum depth'));
      final vm = container.read(categoryTreeViewModelProvider.notifier);

      await expectLater(
        vm.insert(name: 'x', parentId: 'c1'),
        throwsA(isA<ValidationException>()),
      );

      final state = container.read(categoryTreeViewModelProvider);
      expect(state.hasError, isFalse);
      expect(state.valueOrNull?.map((c) => c.id), ['c1']);
    });
  });
}
