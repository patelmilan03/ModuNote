import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/core/errors/app_exception.dart';
import 'package:modunote/data/datasources/file/audio_file_storage.dart';
import 'package:modunote/data/datasources/local/app_database.dart';
import 'package:modunote/data/models/audio_record.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/data/repositories/local/local_audio_record_repository.dart';
import 'package:modunote/data/repositories/local/local_note_repository.dart';

import '../../util/sqlite3_test_setup.dart';

/// Fails every delete, like a file that is locked or on a broken volume.
class _FailingAudioStorage extends AudioFileStorage {
  final attempts = <String>[];

  @override
  Future<void> deleteFile(String filePath) async {
    attempts.add(filePath);
    throw const FileStorageException('boom');
  }
}

void main() {
  late bool sqliteReady;
  setUpAll(() async => sqliteReady = await ensureSqlite3());

  late AppDatabase db;
  late LocalNoteRepository notes;
  late LocalAudioRecordRepository audio;
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('note_audio_delete_');
    if (!sqliteReady) return;
    db = AppDatabase(NativeDatabase.memory());
    notes = LocalNoteRepository(db.notesDao);
    audio = LocalAudioRecordRepository(db.audioRecordsDao);
  });
  tearDown(() async {
    if (sqliteReady) await db.close();
    dir.deleteSync(recursive: true);
  });

  Note note(String id) => Note(
        id: id,
        title: id,
        content: const {'ops': []},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

  /// Inserts an audio record for [noteId] backed by a real file on disk.
  Future<File> clip(String noteId, String name) async {
    final file = File('${dir.path}/$name.aac')..writeAsBytesSync([1, 2, 3]);
    await audio.insert(AudioRecord(
      id: name,
      noteId: noteId,
      filePath: file.path,
      durationMs: 1000,
      fileSizeBytes: 3,
      createdAt: DateTime.utc(2024),
    ));
    return file;
  }

  group('LocalNoteRepository.delete with voice recordings', () {
    test('removes the audio rows and the files on disk', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await notes.insert(note('n1'));
      final a = await clip('n1', 'a');
      final b = await clip('n1', 'b');

      await notes.delete('n1');

      expect(await notes.findById('n1'), isNull);
      expect(await audio.findByNote('n1'), isEmpty);
      expect(a.existsSync(), isFalse);
      expect(b.existsSync(), isFalse);
      expect(await db.audioRecordsDao.totalFileSizeBytes(), 0);
    });

    test("leaves other notes' recordings alone", () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await notes.insert(note('n1'));
      await notes.insert(note('n2'));
      await clip('n1', 'a');
      final keep = await clip('n2', 'keep');

      await notes.delete('n1');

      expect((await audio.findByNote('n2')).map((r) => r.id), ['keep']);
      expect(keep.existsSync(), isTrue);
    });

    test('still works when the file is already gone', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await notes.insert(note('n1'));
      final a = await clip('n1', 'a');
      a.deleteSync();

      await notes.delete('n1');

      expect(await notes.findById('n1'), isNull);
      expect(await audio.findByNote('n1'), isEmpty);
    });

    test('a note without recordings deletes as before', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await notes.insert(note('n1'));

      await notes.delete('n1');

      expect(await notes.findById('n1'), isNull);
    });

    test('deleting a missing note is a no-op', () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      await notes.delete('nope');
    });

    test('a file that cannot be deleted does not block the note delete',
        () async {
      if (!sqliteReady) return markTestSkipped('sqlite3 unavailable');
      final failing = _FailingAudioStorage();
      notes = LocalNoteRepository(db.notesDao, audioStorage: failing);
      await notes.insert(note('n1'));
      await clip('n1', 'a');
      await clip('n1', 'b');

      await notes.delete('n1'); // must not throw

      expect(await notes.findById('n1'), isNull);
      expect(await audio.findByNote('n1'), isEmpty);
      // Both files were still attempted after the first one failed.
      expect(failing.attempts, hasLength(2));
    });
  });
}
