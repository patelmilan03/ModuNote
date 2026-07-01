import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/models/category.dart';

void main() {
  Category buildCategory() => Category(
        id: 'c1',
        name: 'Work',
        parentId: 'root',
        sortOrder: 2,
        createdAt: DateTime.utc(2024, 1, 1),
      );

  group('Category', () {
    test('value equality', () {
      expect(buildCategory(), equals(buildCategory()));
      expect(buildCategory().hashCode, equals(buildCategory().hashCode));
    });

    test('differs when parentId differs', () {
      expect(
        buildCategory(),
        isNot(equals(buildCategory().copyWith(parentId: 'other'))),
      );
    });

    test('isRoot is true only when parentId is null', () {
      final root = Category(
        id: 'r',
        name: 'Root',
        createdAt: DateTime.utc(2024),
      );
      expect(root.isRoot, isTrue);
      expect(root.parentId, isNull);
      expect(root.sortOrder, 0); // documented default
      expect(buildCategory().isRoot, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      final updated = buildCategory().copyWith(name: 'Personal', sortOrder: 5);
      expect(updated.name, 'Personal');
      expect(updated.sortOrder, 5);
      expect(updated.id, 'c1');
      expect(updated.parentId, 'root');
    });
  });
}
