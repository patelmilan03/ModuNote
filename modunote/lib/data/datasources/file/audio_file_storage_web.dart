import '../../../core/errors/app_exception.dart';

/// Web stub for [AudioFileStorage].
/// Audio recording/playback via the file system is not supported on web.
/// All callers guard with kIsWeb before reaching these methods.
class AudioFileStorage {
  Future<void> ensureAudioDir() async {}

  Future<String> generateFilePath() async {
    throw const FileStorageException(
      'Audio file storage is not supported on web.',
    );
  }

  Future<int> getFileSize(String filePath) async {
    throw const FileStorageException(
      'Audio file storage is not supported on web.',
    );
  }

  Future<void> deleteFile(String filePath) async {}
}
