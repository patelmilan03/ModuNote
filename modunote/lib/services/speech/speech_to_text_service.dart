import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps [SpeechToText] for live dictation during a recording session.
///
/// Usage:
/// 1. Call [initialize] once per session — it requests microphone permission.
/// 2. Call [startListening] when recording begins.
/// 3. React to [onResult] callbacks for live transcript updates.
/// 4. Call [stopListening] when recording ends; read [accumulatedText].
/// 5. Call [resetText] before starting a new recording session.
class SpeechToTextService {
  final SpeechToText _stt = SpeechToText();

  String _accumulated = '';
  bool _active = false;
  void Function(String)? _onResult;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Whether STT is currently listening.
  bool get isListening => _stt.isListening;

  /// Whether the underlying STT engine is available on this device.
  bool get isAvailable => _stt.isAvailable;

  /// Full transcript accumulated across all listen intervals this session.
  String get accumulatedText => _accumulated;

  /// Initializes the STT engine and requests microphone permission.
  /// Returns [true] if the engine is available and permission was granted.
  Future<bool> initialize() async {
    final available = await _stt.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    return available;
  }

  /// Starts live listening. [onResult] receives updated text after each
  /// recognition event (partial + final results combined with [_accumulated]).
  ///
  /// Uses dictation mode with an 8-second silence timeout. The [_onStatus]
  /// handler automatically restarts listening if the engine stops while
  /// [_active] is still true (Android STT stops on prolonged silence).
  Future<void> startListening({required void Function(String) onResult}) async {
    _active = true;
    _onResult = onResult;
    await _listen();
  }

  /// Stops listening. After this returns, [accumulatedText] contains the full
  /// transcript for the session.
  Future<void> stopListening() async {
    _active = false;
    _onResult = null;
    if (_stt.isListening) {
      await _stt.stop();
    }
  }

  /// Clears the accumulated transcript. Call before starting a new session.
  void resetText() => _accumulated = '';

  /// Cancels any active listen session. Safe to call in dispose().
  Future<void> dispose() async {
    _active = false;
    _onResult = null;
    if (_stt.isListening) {
      await _stt.cancel();
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<void> _listen() async {
    await _stt.listen(
      onResult: _handleResult,
      pauseFor: const Duration(seconds: 8),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      ),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!_active) return;
    if (result.finalResult) {
      // Append confirmed words to the accumulated transcript.
      final words = result.recognizedWords.trim();
      if (words.isNotEmpty) {
        _accumulated = _accumulated.isEmpty ? words : '$_accumulated $words';
      }
      _onResult?.call(_accumulated);
    } else {
      // Partial result: show accumulated + current in-flight words.
      final inFlight = result.recognizedWords.trim();
      final preview = _accumulated.isEmpty ? inFlight : '$_accumulated $inFlight';
      _onResult?.call(preview);
    }
  }

  void _onError(SpeechRecognitionError error) {
    // Non-fatal errors (e.g. network_error on device without network STT)
    // are silently ignored — the recording continues; the transcript may
    // simply be incomplete.
  }

  void _onStatus(String status) {
    // Android STT stops automatically after a period of silence. If we're
    // still in an active recording session, restart the listener so long
    // recordings continue to be transcribed.
    if (status == 'notListening' && _active) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_active && !_stt.isListening) {
          _listen();
        }
      });
    }
  }
}
