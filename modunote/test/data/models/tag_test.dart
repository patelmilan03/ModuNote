import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/models/tag.dart';

void main() {
  Tag buildTag() =>
      Tag(id: 't1', name: 'ideas', createdAt: DateTime.utc(2024, 1, 1));

  group('Tag', () {
    test('value equality', () {
      expect(buildTag(), equals(buildTag()));
      expect(buildTag().hashCode, equals(buildTag().hashCode));
    });

    test('differs when name differs', () {
      expect(buildTag(), isNot(equals(buildTag().copyWith(name: 'other'))));
    });

    test('copyWith overrides only the given field', () {
      final updated = buildTag().copyWith(name: 'study');
      expect(updated.name, 'study');
      expect(updated.id, 't1');
      expect(updated.createdAt, DateTime.utc(2024, 1, 1));
    });

    test('copyWith with no args returns an equal tag', () {
      expect(buildTag().copyWith(), equals(buildTag()));
    });
  });
}
