import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/presentation/viewmodels/rag_settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  // Lets the keepAlive provider's async _load() settle before assertions.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  group('RagIndexTags', () {
    test('defaults to the constant trigger set when nothing is persisted',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();

      expect(
        container.read(ragIndexTagsProvider),
        {'study', 'notes', 'research'},
      );
    });

    test('hydrates from SharedPreferences when a saved set exists', () async {
      SharedPreferences.setMockInitialValues({
        'rag_index_tags': ['modunote', 'project'],
      });
      final container = makeContainer();
      // Trigger build (and its async _load).
      container.read(ragIndexTagsProvider);
      await settle();

      expect(container.read(ragIndexTagsProvider), {'modunote', 'project'});
    });

    test('addTag normalises, dedupes, and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      container.read(ragIndexTagsProvider);
      await settle();

      final notifier = container.read(ragIndexTagsProvider.notifier);
      await notifier.addTag('  Project Ideas  '); // → normalised
      await notifier.addTag('project ideas'); // duplicate, no-op

      final state = container.read(ragIndexTagsProvider);
      expect(state.contains('project ideas'), isTrue);
      expect(state.where((t) => t == 'project ideas'), hasLength(1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('rag_index_tags'), contains('project ideas'));
    });

    test('addTag ignores a blank name', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      container.read(ragIndexTagsProvider);
      await settle();

      final before = container.read(ragIndexTagsProvider);
      await container.read(ragIndexTagsProvider.notifier).addTag('   ');
      expect(container.read(ragIndexTagsProvider), before);
    });

    test('removeTag drops the tag and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      container.read(ragIndexTagsProvider);
      await settle();

      await container.read(ragIndexTagsProvider.notifier).removeTag('study');

      expect(container.read(ragIndexTagsProvider).contains('study'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('rag_index_tags'),
        isNot(contains('study')),
      );
    });
  });
}
