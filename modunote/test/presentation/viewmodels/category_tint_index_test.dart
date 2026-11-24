import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/models/category.dart';
import 'package:modunote/presentation/viewmodels/category_tree_view_model.dart';

Category _c(String id, {String? parent, int order = 0, int day = 1}) =>
    Category(
      id: id,
      name: id,
      parentId: parent,
      sortOrder: order,
      createdAt: DateTime(2026, 1, day),
    );

void main() {
  group('buildCategoryTintIndex', () {
    test('roots take tints in sortOrder, children inherit their root', () {
      final map = buildCategoryTintIndex([
        _c('video', order: 1),
        _c('inbox', order: 0),
        _c('yt', parent: 'video'),
        _c('travel', parent: 'yt'),
      ]);
      expect(map['inbox'], 0);
      expect(map['video'], 1);
      expect(map['yt'], 1);
      expect(map['travel'], 1);
    });

    test('ties on sortOrder fall back to createdAt', () {
      final map = buildCategoryTintIndex([
        _c('b', day: 2),
        _c('a', day: 1),
      ]);
      expect(map['a'], 0);
      expect(map['b'], 1);
    });

    test('empty list gives an empty map', () {
      expect(buildCategoryTintIndex(const []), isEmpty);
    });
  });

  group('buildCategoryNoteCounts', () {
    test('a note counts for its folder and every ancestor', () {
      final counts = buildCategoryNoteCounts(
        [_c('video'), _c('yt', parent: 'video'), _c('ig', parent: 'video')],
        ['yt', 'yt', 'ig', 'video', null],
      );
      expect(counts['yt'], 2);
      expect(counts['ig'], 1);
      expect(counts['video'], 4);
    });

    test('ignores unknown folder ids and survives a parent cycle', () {
      final counts = buildCategoryNoteCounts(
        [_c('a', parent: 'b'), _c('b', parent: 'a')],
        ['gone', 'a'],
      );
      expect(counts.containsKey('gone'), isFalse);
      expect(counts['a'], greaterThan(0));
    });
  });
}
