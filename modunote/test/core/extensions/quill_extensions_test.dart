import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/core/extensions/quill_extensions.dart';

void main() {
  group('plainTextFromDelta', () {
    test('concatenates string inserts and trims', () {
      expect(
        plainTextFromDelta(const {
          'ops': [
            {'insert': 'Hello '},
            {'insert': 'world\n'},
          ],
        }),
        'Hello world',
      );
    });

    test('skips non-string (embed) inserts', () {
      expect(
        plainTextFromDelta(const {
          'ops': [
            {'insert': 'text '},
            {
              'insert': {'image': 'data:...'},
            },
            {'insert': 'after\n'},
          ],
        }),
        'text after',
      );
    });

    test('returns empty string when ops is missing or not a list', () {
      expect(plainTextFromDelta(const {}), '');
      expect(plainTextFromDelta(const {'ops': 'nope'}), '');
    });
  });
}
