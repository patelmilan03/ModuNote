import 'dart:async';

import 'package:flutter_sound/flutter_sound.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

/// Wraps [FlutterSoundRecorder] and [FlutterSoundPlayer].
///
/// Lifecycle: call [init] once before use; call [dispose] in the owner's
/// dispose() method. [init] is idempotent — safe to call multiple times.
class AudioRecordingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final StreamController<double> _amplitudeCtrl =
      StreamController<double>.broadcast();

  bool _initialized = false;
  Stopwatch? _stopwatch;

  // ─── Amplitude stream ─────────────────────────────────────────────────────

  /// Normalised amplitude in 0.0–1.0, emitted every 100 ms during recording.
  Stream<double> get amplitudeStream => _amplitudeCtrl.stream;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  /// Opens the recorder and player. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _recorder.openRecorder();
      await _player.openPlayer();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );
      _initialized = true;
    } on Exception catch (e) {
      throw FileStorageException('Failed to open audio services', cause: e);
    }
  }

  /// Closes recorder and player. Safe to call even if not yet initialised.
  Future<void> dispose() async {
    if (!_initialized) return;
    _amplitudeCtrl.close();
    await _recorder.closeRecorder();
    await _player.closePlayer();
    _initialized = false;
  }

  // ─── Recording ────────────────────────────────────────────────────────────

  /// Starts recording to [filePath] using the AAC spec from [AppConstants].
  /// Throws [PermissionException] if microphone access is denied by the OS.
  Future<void> startRecording(String filePath) async {
    _assertInitialized();
    try {
      _stopwatch = Stopwatch()..start();
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        bitRate: AppConstants.audioBitRate,
        numChannels: AppConstants.audioNumChannels,
        sampleRate: AppConstants.audioSampleRate,
      );
      // Forward amplitude to stream.
      _recorder.onProgress!.listen((event) {
        if (_amplitudeCtrl.hasListener) {
          final db = event.decibels ?? -60.0;
          final normalized = ((db + 60.0) / 60.0).clamp(0.0, 1.0);
          _amplitudeCtrl.add(normalized);
        }
      });
    } on RecorderStopedException catch (e) {
      throw PermissionException(
          'Microphone permission denied — cannot start recording',
          cause: e);
    } on Exception catch (e) {
      // flutter_sound throws a generic Exception with a message containing
      // "Permission" when the OS denies the microphone.
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') || msg.contains('denied')) {
        throw PermissionException('Microphone permission denied', cause: e);
      }
      throw FileStorageException('Failed to start recording', cause: e);
    }
  }

  /// Stops the current recording and returns elapsed duration in milliseconds.
  Future<int> stopRecording() async {
    _assertInitialized();
    try {
      await _recorder.stopRecorder();
      final ms = _stopwatch?.elapsedMilliseconds ?? 0;
      _stopwatch?.stop();
      _stopwatch = null;
      return ms;
    } on Exception catch (e) {
      throw FileStorageException('Failed to stop recording', cause: e);
    }
  }

  bool get isRecording => _recorder.isRecording;

  // ─── Playback ─────────────────────────────────────────────────────────────

  /// Starts playing the audio file at [filePath].
  /// [onDone] is called when playback completes naturally.
  Future<void> startPlayback(String filePath, {void Function()? onDone}) async {
    _assertInitialized();
    try {
      await _player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
        whenFinished: onDone,
      );
    } on Exception catch (e) {
      throw FileStorageException('Failed to start playback', cause: e);
    }
  }

  /// Stops the current playback.
  Future<void> stopPlayback() async {
    _assertInitialized();
    try {
      await _player.stopPlayer();
    } on Exception catch (e) {
      throw FileStorageException('Failed to stop playback', cause: e);
    }
  }

  bool get isPlaying => _player.isPlaying;

  /// Stream of playback position updates (for progress indicators).
  Stream<PlaybackDisposition>? get playbackStream => _player.onProgress;

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _assertInitialized() {
    if (!_initialized) {
      throw FileStorageException(
          'AudioRecordingService.init() must be called before use');
    }
  }
}
