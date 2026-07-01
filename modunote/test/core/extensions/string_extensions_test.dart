import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions.normalised (tag-name normalisation)', () {
    test('lowercases and trims', () {
      expect('  Travel  '.normalised, 'travel');
      expect('STUDY'.normalised, 'study');
    });

    test('preserves internal spacing', () {
      expect('  Project Ideas '.normalised, 'project ideas');
    });
  });

  group('StringExtensions blank checks', () {
    test('isBlank / isNotBlank treat whitespace as blank', () {
      expect('   '.isBlank, isTrue);
      expect(''.isBlank, isTrue);
      expect(' x '.isBlank, isFalse);
      expect('x'.isNotBlank, isTrue);
    });
  });

  group('StringExtensions.truncate', () {
    test('appends an ellipsis only when over the limit', () {
      expect('hello'.truncate(10), 'hello');
      expect('hello world'.truncate(5), 'hello…');
    });
  });

  group('StringExtensions.capitalised', () {
    test('uppercases the first character only', () {
      expect('note'.capitalised, 'Note');
      expect(''.capitalised, '');
    });
  });

  group('NullableStringExtensions.isNullOrBlank', () {
    test('handles null and whitespace', () {
      String? value;
      expect(value.isNullOrBlank, isTrue);
      expect('  '.isNullOrBlank, isTrue);
      expect('x'.isNullOrBlank, isFalse);
    });
  });
}
