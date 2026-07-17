import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/quill_extensions.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/datasources/file/audio_file_storage.dart';
import '../../../data/models/audio_record.dart';
import '../../../data/models/note.dart';
import '../../../data/models/tag.dart';
import '../../../services/audio/audio_recording_service.dart';
import '../../../services/remote/remote_note_service_provider.dart';
import '../../../services/speech/speech_to_text_service.dart';
import '../../viewmodels/audio_editor_view_model.dart';
import '../../viewmodels/category_tree_view_model.dart';
import '../../viewmodels/note_editor_view_model.dart';
import '../../viewmodels/rag_settings_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_editor_toolbar.dart';
import '../../widgets/mn_category_picker_sheet.dart';
import '../../widgets/mn_tag_row.dart';
import 'widgets/ai_tools_sheet.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/note_options_sheet.dart';
import 'widgets/recording_overlay.dart';
import 'widgets/tag_input_sheet.dart';
import 'widgets/tag_suggest_banner.dart';
import 'widgets/voice_panel.dart';

/// Rich-text note editor.
/// Owns the QuillController lifecycle and 800 ms auto-save debounce.
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.4
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  /// Null = new note. Non-null = editing existing note.
  final String? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  // ─── Text / editor controllers ────────────────────────────────────────────
  QuillController? _quillController;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  // ─── Auto-save subscriptions / timers ─────────────────────────────────────
  StreamSubscription<dynamic>? _contentSubscription;
  Timer? _debounce;
  bool _isDirty = false;

  // ─── Note tracking ────────────────────────────────────────────────────────
  Note? _currentNote;
  bool _controllersInitialized = false;

  // ─── Sync status ──────────────────────────────────────────────────────────
  SyncStatus _syncStatus = SyncStatus.local;

  // ─── Audio / recording ────────────────────────────────────────────────────
  final AudioRecordingService _audioService = AudioRecordingService();
  final SpeechToTextService _sttService = SpeechToTextService();
  final AudioFileStorage _audioStorage = AudioFileStorage();
  bool _audioInitialized = false;

  StreamSubscription<double>? _amplitudeSubscription;
  String? _currentRecordingPath;
  double _currentAmplitude = 0.0;
  String _liveTranscript = '';

  Timer? _recordTimer;
  bool _isRecording = false;
  int _recordSeconds = 0;

  // ─── AI tag suggestions (Stage 1) ─────────────────────────────────────────
  List<String> _tagSuggestions = const [];
  bool _tagSuggestFetched = false;
  bool _tagSuggestDismissed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _recordTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _contentSubscription?.cancel();
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _quillController?.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    if (_audioInitialized) {
      _audioService.dispose();
    }
    _sttService.dispose();
    super.dispose();
  }

  // ─── Initialization ───────────────────────────────────────────────────────

  // Called from build() via noteAsync.whenData(). Guarded by _controllersInitialized.
  void _initControllers(Note? note) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _currentNote = note;
    _syncStatus = note?.syncStatus ?? SyncStatus.local;

    Document doc;
    if (note != null && note.content['ops'] is List) {
      // Explicitly cast each op to Map<String, dynamic> so flutter_quill's
      // fromJson receives the correct type regardless of what jsonDecode
      // produced (List<dynamic> with Map<String, Object> elements can cause
      // a silent type mismatch that drops list/checkbox block attributes).
      final ops = (note.content['ops'] as List)
          .map((op) => Map<String, dynamic>.from(op as Map))
          .toList();
      try {
        doc = Document.fromJson(ops);
      } catch (e, st) {
        debugPrint('NoteEditor: failed to deserialize content: $e\n$st');
        doc = Document();
      }
      _titleController.text = note.title;
    } else {
      doc = Document();
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen to content changes only (not selection changes) for auto-save.
    _contentSubscription =
        _quillController!.document.changes.listen((_) => _scheduleAutoSave());
    _titleController.addListener(_onTitleChanged);

    _maybeAutoSuggestTags(note);
  }

  // ─── Auto-save ────────────────────────────────────────────────────────────

  void _onTitleChanged() => _scheduleAutoSave();

  void _scheduleAutoSave() {
    if (!mounted || _quillController == null) return;
    if (!_isDirty) setState(() => _isDirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    if (!mounted || _quillController == null) return;

    final title = _titleController.text;
    final content = {
      'ops': _quillController!.document.toDelta().toJson(),
    };
    final now = DateTime.now();

    final Note note;
    if (_currentNote == null) {
      note = Note(
        id: UuidGenerator.generate(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      note = _currentNote!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
      );
    }

    _currentNote = note;

    try {
      await ref
          .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
          .save(note);
    } catch (_) {
      return;
    }

    // save() catches AppException internally and sets AsyncError without
    // rethrowing — check state explicitly so failures keep _isDirty = true.
    final vmState =
        ref.read(noteEditorViewModelProvider(noteId: widget.noteId));
    if (vmState.hasError) {
      debugPrint('NoteEditorScreen: auto-save failed: ${vmState.error}');
      return;
    }

    if (mounted) setState(() => _isDirty = false);
    _maybeAutoSuggestTags(_currentNote);
  }

  // ─── Tag handling ─────────────────────────────────────────────────────────

  Future<void> _onAddTagTap() async {
    if (_quillController == null) return;

    // Enforce 20-tag limit before opening the sheet.
    if ((_currentNote?.tagIds.length ?? 0) >= AppConstants.maxTagsPerNote) {
      _showSnackBar('Maximum ${AppConstants.maxTagsPerNote} tags per note');
      return;
    }

    // Ensure the note is persisted before tagging.
    if (_currentNote == null) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    if (!mounted || _currentNote == null) return;

    final tag = await showModalBottomSheet<Tag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TagInputSheet(
        noteTagIds: _currentNote!.tagIds,
      ),
    );

    if (tag != null && mounted) {
      try {
        await ref
            .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
            .addTag(tag.id);
        _syncCurrentNote();
      } catch (_) {}
    }
  }

  Future<void> _onRemoveTag(String tagId) async {
    try {
      await ref
          .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
          .removeTag(tagId);
      _syncCurrentNote();
    } catch (_) {}
  }

  void _syncCurrentNote() {
    if (!mounted) return;
    final vmNote = ref
        .read(noteEditorViewModelProvider(noteId: widget.noteId))
        .valueOrNull;
    if (vmNote != null) setState(() => _currentNote = vmNote);
  }

  // ─── AI assist (Stage 1) ──────────────────────────────────────────────────

  /// Resolves human-readable tag names from tag ids via the tag list VM.
  List<String> _resolveTagNames(List<String> tagIds) {
    if (tagIds.isEmpty) return const [];
    final all = ref.read(tagListViewModelProvider).valueOrNull ?? <Tag>[];
    final byId = {for (final t in all) t.id: t.name};
    return [for (final id in tagIds) if (byId[id] != null) byId[id]!];
  }

  /// Fetches AI tag suggestions once for a note that has enough content but no
  /// tags yet. Cost-bounded: fires at most once per editor session, and never
  /// after the banner is dismissed.
  void _maybeAutoSuggestTags(Note? note) {
    if (note == null || _tagSuggestFetched || _tagSuggestDismissed) return;
    if (note.tagIds.isNotEmpty) return;
    if (plainTextFromDelta(note.content).length < 15) return;
    _tagSuggestFetched = true;
    _fetchTagSuggestions(note);
  }

  Future<void> _fetchTagSuggestions(Note note) async {
    try {
      final tags = await ref.read(remoteNoteServiceProvider).suggestTags(
            noteId: note.id,
            title: note.title,
            content: plainTextFromDelta(note.content),
            existingTags: _resolveTagNames(note.tagIds),
          );
      if (mounted && tags.isNotEmpty) {
        setState(() => _tagSuggestions = tags);
      }
    } catch (_) {
      // Silent — tag suggestions are a non-critical enhancement.
    }
  }

  Future<void> _acceptSuggestedTag(String name) async {
    if (_currentNote == null) return;
    if (_currentNote!.tagIds.length >= AppConstants.maxTagsPerNote) {
      _showSnackBar('Maximum ${AppConstants.maxTagsPerNote} tags per note');
      return;
    }
    final normalised = name.normalised;
    if (normalised.isEmpty) return;
    setState(() =>
        _tagSuggestions = _tagSuggestions.where((t) => t != name).toList());
    try {
      final notifier = ref.read(tagListViewModelProvider.notifier);
      final tag =
          await notifier.findByName(normalised) ?? await notifier.insert(normalised);
      if (_currentNote!.tagIds.contains(tag.id)) return;
      await ref
          .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
          .addTag(tag.id);
      _syncCurrentNote();
    } catch (_) {}
  }

  Future<void> _onAiAssist() async {
    if (_currentNote == null || _quillController == null) return;
    if (plainTextFromDelta(_currentNote!.content).isEmpty) {
      _showSnackBar('Write something first');
      return;
    }
    // Persist latest edits before sending content to the backend.
    if (_isDirty) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    if (!mounted || _currentNote == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiToolsSheet(
        note: _currentNote!,
        tagNames: _resolveTagNames(_currentNote!.tagIds),
        onInsert: _aiInsertAtCursor,
        onReplace: _aiReplaceDocument,
        onInsertSummary: _aiInsertSummaryBlockquote,
      ),
    );
  }

  void _aiInsertAtCursor(String text) {
    if (_quillController == null) return;
    final docLen = _quillController!.document.length;
    var idx = _quillController!.selection.baseOffset;
    if (idx < 0 || idx > docLen - 1) idx = docLen - 1;
    final insertText = '\n${text.trim()}\n';
    _quillController!.document.insert(idx, insertText);
    _quillController!.updateSelection(
      TextSelection.collapsed(offset: idx + insertText.length),
      ChangeSource.local,
    );
    _scheduleAutoSave();
  }

  void _aiReplaceDocument(String text) {
    if (_quillController == null) return;
    final len = _quillController!.document.length;
    final body = text.trim();
    _quillController!.replaceText(
      0,
      len > 0 ? len - 1 : 0,
      body,
      TextSelection.collapsed(offset: body.length),
    );
    _scheduleAutoSave();
  }

  void _aiInsertSummaryBlockquote(String summary) {
    if (_quillController == null) return;
    final text = '${summary.trim()}\n';
    _quillController!.document.insert(0, text);
    _quillController!.formatText(0, text.length, Attribute.blockQuote);
    _quillController!.updateSelection(
      TextSelection.collapsed(offset: text.length),
      ChangeSource.local,
    );
    _scheduleAutoSave();
  }

  /// Opens the AI assist sheet seeded with a voice [transcript] (the "Paraphrase"
  /// action in the voice panel). Results insert/replace/copy into the note.
  Future<void> _onParaphraseTranscript(String transcript) async {
    if (_currentNote == null || transcript.trim().isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiToolsSheet(
        note: _currentNote!,
        tagNames: _resolveTagNames(_currentNote!.tagIds),
        contentOverride: transcript,
        onInsert: _aiInsertAtCursor,
        onReplace: _aiReplaceDocument,
        onInsertSummary: _aiInsertSummaryBlockquote,
      ),
    );
  }

  // ─── Category picker ──────────────────────────────────────────────────────

  Future<void> _onCategoryTap() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MNCategoryPickerSheet(
        currentCategoryId: _currentNote?.categoryId,
      ),
    );

    // null = dismissed, "" = unassign, non-empty = category id
    if (result == null || !mounted) return;

    final newCategoryId = result.isEmpty ? null : result;
    if (newCategoryId == _currentNote?.categoryId) return;

    if (_currentNote == null) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    if (!mounted || _currentNote == null) return;

    await ref
        .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
        .setCategory(newCategoryId);
    _syncCurrentNote();
  }

  // ─── Recording ────────────────────────────────────────────────────────────

  Future<void> _onMicTap() async {
    if (kIsWeb) {
      _showSnackBar('Audio recording is not available in the web preview.');
      return;
    }
    if (_quillController == null) return;

    // Ensure the note is persisted before attaching an audio record.
    if (_currentNote == null) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    if (!mounted || _currentNote == null) return;

    // Lazy-init audio services on first use.
    if (!_audioInitialized) {
      try {
        await _audioService.init();
        _audioInitialized = true;
      } on Exception catch (e) {
        _showSnackBar(
            e is PermissionException ? e.message : 'Could not open audio services');
        return;
      }
    }

    // Request microphone permission via speech_to_text (covers flutter_sound too).
    final sttAvailable = await _sttService.initialize();
    if (!sttAvailable) {
      if (mounted) {
        _showSnackBar('Microphone permission denied');
      }
      return;
    }

    // Generate a file path for this recording.
    late String filePath;
    try {
      filePath = await _audioStorage.generateFilePath();
    } on Exception catch (e) {
      if (mounted) _showSnackBar('Could not prepare recording file: $e');
      return;
    }

    _currentRecordingPath = filePath;
    _sttService.resetText();

    // Start flutter_sound recording.
    try {
      await _audioService.startRecording(filePath);
    } on PermissionException catch (e) {
      if (mounted) _showSnackBar(e.message);
      _currentRecordingPath = null;
      return;
    } on Exception catch (e) {
      if (mounted) _showSnackBar('Recording failed to start: $e');
      _currentRecordingPath = null;
      return;
    }

    // Start live speech-to-text simultaneously.
    await _sttService.startListening(
      onResult: (text) {
        if (mounted) setState(() => _liveTranscript = text);
      },
    );

    // Subscribe to amplitude for waveform animation.
    _amplitudeSubscription = _audioService.amplitudeStream.listen((amp) {
      if (mounted) setState(() => _currentAmplitude = amp);
    });

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _liveTranscript = '';
      _currentAmplitude = 0.0;
    });

    _recordTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    int durationMs = 0;
    try {
      durationMs = await _audioService.stopRecording();
    } catch (_) {}

    await _sttService.stopListening();
    // On-device live STT result first.
    var transcript = _sttService.accumulatedText.trim();

    setState(() {
      _isRecording = false;
      _currentAmplitude = 0.0;
    });

    final recordingPath = _currentRecordingPath;
    _currentRecordingPath = null;

    if (recordingPath != null && _currentNote != null) {
      final noteId = _currentNote!.id;
      int fileSize = 0;
      try {
        fileSize = await _audioStorage.getFileSize(recordingPath);
      } catch (_) {}

      // Save the clip IMMEDIATELY with whatever on-device STT produced, so it
      // always appears in the voice panel. Transcription must never block (or
      // lose) the recording — the Whisper fallback runs afterwards with a
      // timeout and patches the transcript in.
      final vm =
          ref.read(audioEditorViewModelProvider(noteId: noteId).notifier);
      AudioRecord? saved;
      try {
        saved = await vm.saveRecording(
          filePath: recordingPath,
          durationMs: durationMs,
          fileSizeBytes: fileSize,
          transcript: transcript.isEmpty ? null : transcript,
        );
      } catch (e) {
        if (mounted) _showSnackBar('Could not save the recording: $e');
      }

      // Fallback: if on-device STT produced nothing (e.g. the recorder and the
      // recognizer contended for the mic), upload the audio to the backend →
      // Groq Whisper. Bounded by a timeout so an unreachable backend can't hang
      // the editor; the clip is already saved either way.
      if (saved != null && transcript.isEmpty && !kIsWeb) {
        try {
          final whisper = (await ref
                  .read(remoteNoteServiceProvider)
                  .transcribe(filePath: recordingPath)
                  .timeout(const Duration(seconds: 20)))
              .trim();
          if (whisper.isNotEmpty) {
            await vm.updateTranscription(saved.id, whisper);
          }
        } catch (_) {
          // Transcription is best-effort enrichment; the clip is kept anyway.
        }
      }
      // The transcript stays with the audio record and is shown in the voice
      // panel — no longer auto-inserted into the note body. Insert-into-note is
      // a panel action (Step D).
    }

    if (mounted) setState(() => _liveTranscript = '');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Note options (⋮ menu) ────────────────────────────────────────────────

  Future<void> _onMoreTap() async {
    if (_currentNote == null) return;
    final note = _currentNote!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteOptionsSheet(
        note: note,
        onAiAssist: () {
          Navigator.of(context).pop();
          _onAiAssist();
        },
        onPin: () async {
          Navigator.of(context).pop();
          try {
            await ref
                .read(noteEditorViewModelProvider(noteId: widget.noteId)
                    .notifier)
                .togglePin(note.id);
            _syncCurrentNote();
          } catch (_) {}
        },
        onArchive: () async {
          Navigator.of(context).pop();
          try {
            await ref
                .read(noteEditorViewModelProvider(noteId: widget.noteId)
                    .notifier)
                .archive(note.id);
          } catch (_) {}
          if (mounted) context.pop();
        },
        onDelete: () {
          Navigator.of(context).pop();
          _showDeleteConfirm();
        },
      ),
    );
  }

  void _showDeleteConfirm() {
    if (_currentNote == null) return;
    final noteId = _currentNote!.id;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(remoteNoteServiceProvider);
              try {
                await ref
                    .read(noteEditorViewModelProvider(noteId: widget.noteId)
                        .notifier)
                    .delete(noteId);
              } catch (_) {}
              // Remove from the RAG index too (fire-and-forget, non-fatal).
              unawaited(service.deindexNote(noteId: noteId).catchError((_) {}));
              // Clean up any tags orphaned by deleting this note.
              unawaited(ref.read(tagListViewModelProvider.notifier).pruneOrphans());
              if (mounted) context.pop();
            },
            child: Text(
              'Delete',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _onBack() async {
    if (_isDirty && _quillController != null) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    // Sync to Firebase after local save is complete.
    if (mounted && _currentNote != null) {
      setState(() => _syncStatus = SyncStatus.pending);
      final newStatus = await ref
          .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
          .syncNote(_currentNote!.id);
      if (mounted) setState(() => _syncStatus = newStatus);
    }
    // RAG index/deindex (Stage 2) — fire-and-forget, never blocks close.
    if (_currentNote != null) _scheduleRagSync(_currentNote!);
    // Auto-clean tags no longer attached to any note (+ prune them from scope).
    unawaited(ref.read(tagListViewModelProvider.notifier).pruneOrphans());
    if (mounted) context.pop();
  }

  /// Indexes or deindexes the note for RAG QnA on close (Stage 2). A note
  /// carrying any RAG trigger tag is indexed; otherwise it is deindexed (covers
  /// tag removal and notes that were never indexable — the backend DELETE is
  /// idempotent). Fire-and-forget: RAG must never block or delay save/close
  /// (D12.4); on any failure local Drift remains authoritative.
  void _scheduleRagSync(Note note) {
    final tagNames = _resolveTagNames(note.tagIds);
    final triggerTags = ref.read(ragIndexTagsProvider);
    final isIndexable = tagNames.any(triggerTags.contains);
    final service = ref.read(remoteNoteServiceProvider);
    final content = plainTextFromDelta(note.content);
    unawaited(() async {
      try {
        if (isIndexable) {
          await service.indexNote(
            noteId: note.id,
            title: note.title,
            content: content,
            tags: tagNames,
          );
        } else {
          await service.deindexNote(noteId: note.id);
        }
      } catch (_) {
        // Non-fatal — local Drift is the source of truth. Surface only INDEX
        // failures (a note the user wants in AI search); deindex/cleanup
        // failures stay silent so closing plain notes never toasts. Dedupe per
        // note (30s) so the same note never spams the toast.
        if (isIndexable) {
          final label = note.title.trim().isEmpty
              ? 'this note'
              : '"${note.title.trim()}"';
          showErrorToast(
            "Couldn't sync $label to AI search.",
            dedupeKey: 'rag-sync-${note.id}',
            cooldown: const Duration(seconds: 30),
          );
        }
      }
    }());
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final noteAsync =
        ref.watch(noteEditorViewModelProvider(noteId: widget.noteId));
    final allTags =
        ref.watch(tagListViewModelProvider).valueOrNull ?? <Tag>[];

    // One-shot controller initialization from ViewModel data.
    noteAsync.whenData(_initControllers);

    // Resolve category name (full wiring in Phase 8).
    String? categoryName;
    if (_currentNote?.categoryId != null) {
      final cats =
          ref.watch(categoryTreeViewModelProvider).valueOrNull ?? [];
      categoryName = cats
          .where((c) => c.id == _currentNote!.categoryId)
          .map((c) => c.name)
          .firstOrNull;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: _quillController == null
            ? _buildUnready(noteAsync, isDark)
            : _buildEditor(allTags, categoryName, isDark),
      ),
    );
  }

  Widget _buildUnready(AsyncValue<Note?> noteAsync, bool isDark) {
    if (noteAsync is AsyncError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load note'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(
                  noteEditorViewModelProvider(noteId: widget.noteId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return _buildSkeletonEditor(isDark);
  }

  /// Shimmering placeholder shown while an existing note loads.
  Widget _buildSkeletonEditor(bool isDark) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placeholder note title here',
              style: AppTypography.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    width: 64,
                    height: 28,
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < 9; i++) ...[
              Text(
                'Placeholder body line of the note content for the skeleton.',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(
      List<Tag> allTags, String? categoryName, bool isDark) {
    final keyboardUp = MediaQuery.of(context).viewInsets.bottom > 0;
    return Stack(
      children: [
        Column(
          children: [
            EditorAppBar(
              isDirty: _isDirty,
              syncStatus: _syncStatus,
              isDark: isDark,
              titleController: _titleController,
              onBack: _onBack,
              onMoreTap: _currentNote != null ? _onMoreTap : null,
            ),
            // Tags + category at the top, directly under the title.
            if (_tagSuggestions.isNotEmpty && !_tagSuggestDismissed)
              TagSuggestBanner(
                suggestions: _tagSuggestions,
                isDark: isDark,
                onAccept: _acceptSuggestedTag,
                onDismiss: () => setState(() => _tagSuggestDismissed = true),
              ),
            MNTagRow(
              tagIds: _currentNote?.tagIds ?? const [],
              allTags: allTags,
              categoryName: categoryName,
              onRemoveTag: _onRemoveTag,
              onAddTagTap: _onAddTagTap,
              onCategoryTap: _onCategoryTap,
              maxTagsReached:
                  (_currentNote?.tagIds.length ?? 0) >=
                  AppConstants.maxTagsPerNote,
            ),
            Expanded(
              child: QuillEditor(
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                controller: _quillController!,
                configurations: QuillEditorConfigurations(
                  scrollable: true,
                  expands: false,
                  autoFocus: widget.noteId == null,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  placeholder: 'Start writing…',
                ),
              ),
            ),
            // Bottom area swaps: the formatting toolbar while the keyboard is up
            // (editing text), the voice panel when it is down.
            if (keyboardUp)
              MNEditorToolbar(controller: _quillController!)
            else if (!kIsWeb && _currentNote != null)
              VoicePanel(
                noteId: _currentNote!.id,
                audioService: _audioService,
                audioStorage: _audioStorage,
                isDark: isDark,
                isRecording: _isRecording,
                onRecordTap: _onMicTap,
                onParaphrase: _onParaphraseTranscript,
                onInsertTranscript: _aiInsertAtCursor,
              ),
          ],
        ),
        if (_isRecording)
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: RecordingOverlay(
              seconds: _recordSeconds,
              onStop: _stopRecording,
              isDark: isDark,
              amplitude: _currentAmplitude,
              liveTranscript: _liveTranscript,
            ),
          ),
      ],
    );
  }
}
