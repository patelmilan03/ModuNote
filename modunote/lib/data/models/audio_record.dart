import 'package:equatable/equatable.dart';

/// Domain model for a voice recording attached to a note.
/// Audio stored as AAC files. Transcription populated after STT.
class AudioRecord extends Equatable {
  const AudioRecord({
    required this.id,
    required this.noteId,
    required this.filePath,
    required this.durationMs,
    required this.fileSizeBytes,
    this.codec = 'aac',
    this.transcribedText,
    required this.createdAt,
  });

  final String id;
  final String noteId;

  /// Absolute path on device storage (under AppConstants.audioSubDir).
  final String filePath;

  final int durationMs;
  final int fileSizeBytes;

  /// Codec identifier. Always 'aac' for now.
  final String codec;

  /// Populated by SpeechToTextService after recording. May be null.
  final String? transcribedText;

  final DateTime createdAt;

  AudioRecord copyWith({
    String? id,
    String? noteId,
    String? filePath,
    int? durationMs,
    int? fileSizeBytes,
    String? codec,
    String? transcribedText,
    DateTime? createdAt,
  }) =>
      AudioRecord(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        filePath: filePath ?? this.filePath,
        durationMs: durationMs ?? this.durationMs,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        codec: codec ?? this.codec,
        transcribedText: transcribedText ?? this.transcribedText,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id, noteId, filePath, durationMs,
        fileSizeBytes, codec, transcribedText, createdAt,
      ];
}
