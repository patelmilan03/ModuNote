import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/uuid_generator.dart';

/// Handles all file-system I/O for audio recordings.
/// No Drift, no Riverpod — plain class owned by callers.
class AudioFileStorage {
  /// Creates the audio subdirectory if it does not exist.
  Future<void> ensureAudioDir() async {
    try {
      final dir = await _audioDir();
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    } on Exception catch (e) {
      throw FileStorageException('Could not create audio directory', cause: e);
    }
  }

  /// Returns a new unique file path for the next recording.
  /// Format: {appDocs}/audio_notes/{uuid}.aac
  Future<String> generateFilePath() async {
    try {
      await ensureAudioDir();
      final dir = await _audioDir();
      final name = '${UuidGenerator.generate()}${AppConstants.audioExtension}';
      return p.join(dir.path, name);
    } on FileStorageException {
      rethrow;
    } on Exception catch (e) {
      throw FileStorageException('Could not generate audio file path', cause: e);
    }
  }

  /// Returns the size of [filePath] in bytes.
  /// Throws [FileStorageException] if the file does not exist.
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileStorageException('Audio file not found: $filePath');
      }
      return file.lengthSync();
    } on FileStorageException {
      rethrow;
    } on Exception catch (e) {
      throw FileStorageException('Could not read audio file size', cause: e);
    }
  }

  /// Deletes the file at [filePath]. Safe to call if file is already missing.
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Exception catch (e) {
      throw FileStorageException('Could not delete audio file', cause: e);
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<Directory> _audioDir() async {
    final appDocs = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDocs.path, AppConstants.audioSubDir));
  }
}
