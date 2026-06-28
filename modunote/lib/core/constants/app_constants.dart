/// App-wide string keys, numeric limits, and magic numbers.
/// Prevents magic values being scattered across the codebase.
abstract class AppConstants {
  // ─── App ──────────────────────────────────────────────────────
  static const String appName = 'ModuNote';

  // ─── Database ─────────────────────────────────────────────────
  static const String dbFileName = 'modunote.db';

  // ─── Notes ────────────────────────────────────────────────────
  static const int noteTitleMaxLength   = 200;
  static const int notePreviewMaxChars  = 120;

  // ─── Tags ─────────────────────────────────────────────────────
  static const int tagNameMaxLength = 50;
  static const int maxTagsPerNote   = 20;

  // ─── Categories ───────────────────────────────────────────────
  static const int categoryNameMaxLength = 100;
  static const int maxCategoryDepth      = 5;

  // ─── Audio ────────────────────────────────────────────────────
  /// AAC codec, mono, 16 kHz → ~0.24 MB/min
  static const int audioSampleRate   = 16000;
  static const int audioBitRate      = 32000;
  static const int audioNumChannels  = 1;
  static const String audioExtension = '.aac';

  // ─── Storage ──────────────────────────────────────────────────
  static const String audioSubDir = 'audio_notes';

  // ─── Shared Preferences keys (Phase 9) ───────────────────────
  static const String prefThemeMode = 'theme_mode';

  /// Persisted set of RAG trigger tags (editable in Settings, Phase 12 Stage 2).
  static const String prefRagIndexTags = 'rag_index_tags';

  // ─── RAG / AI (Phase 12 Stage 2) ──────────────────────────────
  /// DEFAULT set of trigger tags (lowercase). A note carrying any of these is
  /// indexed on the backend for RAG QnA; losing all of them (or deletion)
  /// deindexes it. This is only the default — the live set is user-editable and
  /// persisted via `RagIndexTags` (rag_settings_view_model.dart). See D12.7.
  static const Set<String> ragIndexTags = {'study', 'notes', 'research'};
}
