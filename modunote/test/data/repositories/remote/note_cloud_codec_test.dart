import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/repositories/remote/note_cloud_codec.dart';

void main() {
  // Headings, a checkbox, bold and an ordered list — everything that used to
  // be reported as "lost" after a cloud restore.
  final formatted = <String, dynamic>{
    'ops': [
      {'insert': 'Title'},
      {
        'insert': '\n',
        'attributes': {'header': 1},
      },
      {
        'insert': 'bold',
        'attributes': {'bold': true},
      },
      {'insert': ' text\n'},
      {'insert': 'todo'},
      {
        'insert': '\n',
        'attributes': {'list': 'unchecked'},
      },
      {'insert': 'done'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked'},
      },
    ],
  };

  group('encodeContent', () {
    test('writes Delta JSON string, plain text copy and schemaVersion', () {
      final fields = NoteCloudCodec.encodeContent('n1', formatted);
      expect(fields['schemaVersion'], 2);
      expect(fields['contentJson'], isA<String>());
      expect(jsonDecode(fields['contentJson']! as String), formatted);
      expect(fields['contentText'], contains('Title'));
      expect(fields['contentText'], isNot(contains('header')));
    });

    test('throws NoteTooLargeException above the size guard', () {
      final big = {
        'ops': [
          {'insert': 'x' * (NoteCloudCodec.maxContentJsonBytes + 1)},
        ],
      };
      expect(
        () => NoteCloudCodec.encodeContent('big', big),
        throwsA(isA<NoteTooLargeException>()),
      );
    });
  });

  group('decodeContent', () {
    test('round-trips v2 formatting exactly', () {
      final doc = NoteCloudCodec.encodeContent('n1', formatted);
      expect(NoteCloudCodec.decodeContent(doc), formatted);
    });

    test('reads a legacy Firestore map (and normalises nested types)', () {
      final legacy = <String, dynamic>{
        'content': <Object?, Object?>{
          'ops': <Object?>[
            <Object?, Object?>{
              'insert': '\n',
              'attributes': <Object?, Object?>{'list': 'unchecked'},
            },
          ],
        },
      };
      final out = NoteCloudCodec.decodeContent(legacy);
      final op = (out['ops'] as List).first as Map<String, dynamic>;
      expect(op['attributes'], {'list': 'unchecked'});
    });

    test('adds the missing trailing newline on an old un-terminated doc', () {
      // Shape of a real July-2026 cloud doc: one insert, no "\n", no attributes.
      final out = NoteCloudCodec.decodeContent({
        'content': {
          'ops': [
            {'insert': 'Pizza good Burger bad '},
          ],
        },
      });
      expect(out, {
        'ops': [
          {'insert': 'Pizza good Burger bad '},
          {'insert': '\n'},
        ],
      });
    });

    test('reads a legacy JSON string', () {
      final out = NoteCloudCodec.decodeContent({
        'content': jsonEncode(formatted),
      });
      expect(out, formatted);
    });

    test('wraps legacy plain text into a Delta with a trailing newline', () {
      expect(NoteCloudCodec.decodeContent({'content': 'hello'}), {
        'ops': [
          {'insert': 'hello\n'},
        ],
      });
    });

    test('falls back to contentText, then to an empty document', () {
      expect(NoteCloudCodec.decodeContent({'contentText': 'hi'}), {
        'ops': [
          {'insert': 'hi\n'},
        ],
      });
      expect(NoteCloudCodec.decodeContent(<String, dynamic>{}), {
        'ops': [
          {'insert': '\n'},
        ],
      });
    });

    test('corrupt contentJson degrades instead of throwing', () {
      final out = NoteCloudCodec.decodeContent({
        'contentJson': '{not json',
        'contentText': 'saved text',
      });
      expect(out['ops'], isNotEmpty);
    });
  });
}
