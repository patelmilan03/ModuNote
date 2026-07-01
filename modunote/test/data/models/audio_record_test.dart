import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/data/models/audio_record.dart';

void main() {
  AudioRecord buildRecord() => AudioRecord(
        id: 'a1',
        noteId: 'n1',
        filePath: '/audio/a1.aac',
        durationMs: 4200,
        fileSizeBytes: 16800,
        transcribedText: 'hello world',
        createdAt: DateTime.utc(2024, 1, 1),
      );

  group('AudioRecord', () {
    test('value equality', () {
      expect(buildRecord(), equals(buildRecord()));
      expect(buildRecord().hashCode, equals(buildRecord().hashCode));
    });

    test('differs when transcribedText differs', () {
      expect(
        buildRecord(),
        isNot(equals(buildRecord().copyWith(transcribedText: 'changed'))),
      );
    });

    test('codec defaults to aac and transcribedText may be null', () {
      final r = AudioRecord(
        id: 'a2',
        noteId: 'n1',
        filePath: '/audio/a2.aac',
        durationMs: 1000,
        fileSizeBytes: 4000,
        createdAt: DateTime.utc(2024),
      );
      expect(r.codec, 'aac');
      expect(r.transcribedText, isNull);
    });

    test('copyWith overrides only the given fields', () {
      final updated = buildRecord().copyWith(durationMs: 9999);
      expect(updated.durationMs, 9999);
      expect(updated.id, 'a1');
      expect(updated.transcribedText, 'hello world');
    });
  });
}
