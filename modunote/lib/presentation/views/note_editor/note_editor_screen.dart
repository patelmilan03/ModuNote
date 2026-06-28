import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../viewmodels/audio_pref_view_model.dart';
import '../../viewmodels/category_tree_view_model.dart';
import '../../viewmodels/note_editor_view_model.dart';
import '../../viewmodels/rag_settings_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_editor_toolbar.dart';
import '../../widgets/mn_category_picker_sheet.dart';
import '../../widgets/mn_tag_row.dart';

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
      builder: (_) => _TagInputSheet(
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
      builder: (_) => _AiToolsSheet(
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
      builder: (_) => _AiToolsSheet(
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
      int fileSize = 0;
      try {
        fileSize = await _audioStorage.getFileSize(recordingPath);
      } catch (_) {}

      // Fallback: if on-device STT produced nothing (e.g. the recorder and the
      // recognizer contended for the mic), upload the audio to the backend →
      // Groq Whisper.
      if (transcript.isEmpty && !kIsWeb) {
        try {
          transcript = (await ref
                  .read(remoteNoteServiceProvider)
                  .transcribe(filePath: recordingPath))
              .trim();
        } catch (_) {}
      }

      try {
        await ref
            .read(
                audioEditorViewModelProvider(noteId: _currentNote!.id).notifier)
            .saveRecording(
              filePath: recordingPath,
              durationMs: durationMs,
              fileSizeBytes: fileSize,
              transcript: transcript.isEmpty ? null : transcript,
            );
      } catch (_) {}
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
      builder: (_) => _NoteOptionsSheet(
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
            _EditorAppBar(
              isDirty: _isDirty,
              syncStatus: _syncStatus,
              isDark: isDark,
              titleController: _titleController,
              onBack: _onBack,
              onMoreTap: _currentNote != null ? _onMoreTap : null,
            ),
            // Tags + category at the top, directly under the title.
            if (_tagSuggestions.isNotEmpty && !_tagSuggestDismissed)
              _TagSuggestBanner(
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
              _VoicePanel(
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
            child: _RecordingOverlay(
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

// ─── _VoicePanel ──────────────────────────────────────────────────────────────

/// Bottom voice panel: play/pause + seek bar + current:total timers + record
/// button + one-at-a-time carousel over the note's recordings. Expanding shows
/// the transcript with Paraphrase (opens the AI sheet) and Insert-into-note.
/// Live recording feedback is still the separate [_RecordingOverlay].
class _VoicePanel extends ConsumerStatefulWidget {
  const _VoicePanel({
    required this.noteId,
    required this.audioService,
    required this.audioStorage,
    required this.isDark,
    required this.isRecording,
    required this.onRecordTap,
    required this.onParaphrase,
    required this.onInsertTranscript,
  });

  final String noteId;
  final AudioRecordingService audioService;
  final AudioFileStorage audioStorage;
  final bool isDark;
  final bool isRecording;
  final VoidCallback onRecordTap;
  final void Function(String transcript) onParaphrase;
  final void Function(String transcript) onInsertTranscript;

  @override
  ConsumerState<_VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends ConsumerState<_VoicePanel> {
  int _index = 0;
  String? _playingId;
  bool _paused = false;
  int _posMs = 0;
  int _durMs = 0;
  bool _expanded = false;
  StreamSubscription<dynamic>? _playSub;

  @override
  void initState() {
    super.initState();
    widget.audioService.init().ignore();
  }

  @override
  void dispose() {
    _playSub?.cancel();
    if (_playingId != null) widget.audioService.stopPlayback();
    super.dispose();
  }

  String _fmt(int ms) {
    final s = (ms < 0 ? 0 : ms) ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _stopAndReset() {
    _playSub?.cancel();
    _playSub = null;
    if (_playingId != null) widget.audioService.stopPlayback();
    if (mounted) {
      setState(() {
        _playingId = null;
        _paused = false;
        _posMs = 0;
        _durMs = 0;
      });
    } else {
      _playingId = null;
    }
  }

  Future<void> _togglePlay(AudioRecord record) async {
    if (_playingId == record.id) {
      if (_paused) {
        await widget.audioService.resumePlayback();
        if (mounted) setState(() => _paused = false);
      } else {
        await widget.audioService.pausePlayback();
        if (mounted) setState(() => _paused = true);
      }
      return;
    }
    _stopAndReset();
    if (mounted) {
      setState(() {
        _playingId = record.id;
        _paused = false;
        _posMs = 0;
        _durMs = record.durationMs;
      });
    }
    await widget.audioService
        .startPlayback(record.filePath, onDone: _stopAndReset);
    _playSub = widget.audioService.playbackStream?.listen((d) {
      if (!mounted) return;
      setState(() {
        _posMs = d.position.inMilliseconds;
        if (d.duration.inMilliseconds > 0) _durMs = d.duration.inMilliseconds;
      });
    });
  }

  Future<void> _seek(double ms) async {
    await widget.audioService.seekTo(Duration(milliseconds: ms.round()));
    if (mounted) setState(() => _posMs = ms.round());
  }

  Future<void> _delete(AudioRecord record) async {
    if (_playingId == record.id) _stopAndReset();
    await ref
        .read(audioEditorViewModelProvider(noteId: widget.noteId).notifier)
        .deleteRecord(record.id);
    try {
      await widget.audioStorage.deleteFile(record.filePath);
    } catch (_) {}
  }

  Future<void> _confirmDelete(AudioRecord record) async {
    if (!ref.read(audioDeleteConfirmProvider)) {
      await _delete(record);
      return;
    }
    var dontAsk = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Delete voice note?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'This permanently removes the recording and its transcript.'),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: dontAsk,
                onChanged: (v) => setLocal(() => dontAsk = v ?? false),
                title: const Text("Don't ask again"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    if (dontAsk) {
      await ref.read(audioDeleteConfirmProvider.notifier).setAsk(false);
    }
    await _delete(record);
  }

  @override
  Widget build(BuildContext context) {
    final clips =
        ref.watch(audioEditorViewModelProvider(noteId: widget.noteId)).valueOrNull ??
            const <AudioRecord>[];
    if (_index >= clips.length) _index = clips.isEmpty ? 0 : clips.length - 1;
    final current = clips.isEmpty ? null : clips[_index];

    final cs = Theme.of(context).colorScheme;
    final cardBg = widget.isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineColor =
        widget.isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        widget.isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final variantColor = widget.isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final mutedColor = widget.isDark
        ? AppColors.darkOnSurfaceMuted
        : AppColors.lightOnSurfaceMuted;

    // Variant A — the panel reads as a rounded pill when collapsed and animates
    // growing into a rounded card when expanded (height via AnimatedSize, corner
    // radius + padding via AnimatedContainer). Bottom-anchored, grows upward.
    final expanded = _expanded && current != null;
    const motion = Duration(milliseconds: 340);
    const curve = Curves.easeInOutCubic;

    return AnimatedContainer(
      duration: motion,
      curve: curve,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: EdgeInsets.fromLTRB(12, expanded ? 10 : 6, 12, expanded ? 12 : 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(expanded ? 22 : 28),
        border: Border.all(color: outlineColor, width: 0.5),
      ),
      child: AnimatedSize(
        duration: motion,
        curve: curve,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _topRow(clips, current, cs, onSurface, variantColor, mutedColor),
            if (expanded)
              _transcriptSection(
                  current, cs, onSurface, variantColor, mutedColor),
          ],
        ),
      ),
    );
  }

  Widget _topRow(List<AudioRecord> clips, AudioRecord? current, ColorScheme cs,
      Color onSurface, Color variantColor, Color mutedColor) {
    return Row(
      children: [
        // Record button (disabled while the recording overlay is active).
        GestureDetector(
          onTap: widget.isRecording ? null : widget.onRecordTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isRecording
                  ? cs.error.withValues(alpha: 0.15)
                  : AppColors.accent,
            ),
            child: Icon(
              widget.isRecording ? Icons.mic : Icons.mic_none,
              size: 19,
              color: widget.isRecording ? cs.error : AppColors.accentOn,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: current == null
              ? Text(
                  widget.isRecording ? 'Recording…' : 'Tap to record a voice note',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                  ),
                )
              : _playbackControls(current, variantColor, mutedColor),
        ),
        if (clips.length > 1) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _index > 0
                ? () {
                    _stopAndReset();
                    setState(() => _index--);
                  }
                : null,
            child: Icon(Icons.chevron_left,
                size: 22, color: _index > 0 ? variantColor : mutedColor),
          ),
          Text('${_index + 1}/${clips.length}',
              style: AppTypography.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: mutedColor)),
          GestureDetector(
            onTap: _index < clips.length - 1
                ? () {
                    _stopAndReset();
                    setState(() => _index++);
                  }
                : null,
            child: Icon(Icons.chevron_right,
                size: 22,
                color: _index < clips.length - 1 ? variantColor : mutedColor),
          ),
        ],
        if (current != null)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(_expanded ? Icons.expand_more : Icons.expand_less,
                  size: 22, color: variantColor),
            ),
          ),
      ],
    );
  }

  Widget _playbackControls(
      AudioRecord current, Color variantColor, Color mutedColor) {
    final isThis = _playingId == current.id;
    final durMs = isThis && _durMs > 0 ? _durMs : current.durationMs;
    final maxD = durMs <= 0 ? 1.0 : durMs.toDouble();
    final posMs = isThis ? _posMs.clamp(0, durMs) : 0;
    final val = posMs.toDouble().clamp(0.0, maxD);
    final timerStyle = AppTypography.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: mutedColor);

    return Row(
      children: [
        GestureDetector(
          onTap: () => _togglePlay(current),
          child: Icon(
            isThis && !_paused
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            size: 30,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 6),
        Text(_fmt(posMs), style: timerStyle),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: variantColor.withValues(alpha: 0.25),
              thumbColor: AppColors.accent,
            ),
            child: Slider(
              value: val,
              max: maxD,
              onChanged:
                  isThis ? (v) => setState(() => _posMs = v.round()) : null,
              onChangeEnd: isThis ? _seek : null,
            ),
          ),
        ),
        Text(_fmt(durMs), style: timerStyle),
      ],
    );
  }

  Widget _transcriptSection(AudioRecord current, ColorScheme cs, Color onSurface,
      Color variantColor, Color mutedColor) {
    final transcript = current.transcribedText?.trim() ?? '';
    final hasTranscript = transcript.isNotEmpty;
    final surfaceContainer = widget.isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                hasTranscript
                    ? transcript
                    : 'No transcript for this recording.',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: hasTranscript ? onSurface : mutedColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasTranscript) ...[
                _chip('Paraphrase', Icons.auto_awesome, AppColors.accent,
                    () => widget.onParaphrase(transcript)),
                const SizedBox(width: 8),
                _chip('Insert', Icons.south, variantColor,
                    () => widget.onInsertTranscript(transcript)),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _confirmDelete(current),
                child: Icon(Icons.delete_outline, size: 22, color: cs.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTypography.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Private editor widgets ───────────────────────────────────────────────────

class _EditorAppBar extends StatelessWidget {
  const _EditorAppBar({
    required this.isDirty,
    required this.syncStatus,
    required this.isDark,
    required this.titleController,
    required this.onBack,
    this.onMoreTap,
  });

  final bool isDirty;
  final SyncStatus syncStatus;
  final bool isDark;
  final TextEditingController titleController;
  final VoidCallback onBack;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            color: onSurface,
            onTap: onBack,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: titleController,
              style: AppTypography.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: onSurface,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Title…',
                hintStyle: AppTypography.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark
                      ? AppColors.darkOnSurfaceMuted
                      : AppColors.lightOnSurfaceMuted,
                ),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 6),
          _SaveBadge(isDirty: isDirty, syncStatus: syncStatus, isDark: isDark),
          const SizedBox(width: 6),
          _CircleIconButton(
            icon: Icons.more_vert,
            color: onMoreTap != null ? onSurface : onSurface.withValues(alpha: 0.35),
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _SaveBadge extends StatelessWidget {
  const _SaveBadge({
    required this.isDirty,
    required this.syncStatus,
    required this.isDark,
  });

  final bool isDirty;
  final SyncStatus syncStatus;
  final bool isDark;

  static const Color _localGrey = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    final Color dotColor;
    final String label;

    if (isDirty) {
      dotColor = mutedColor;
      label = 'Saving…';
    } else {
      switch (syncStatus) {
        case SyncStatus.pending:
          dotColor = AppColors.accent;
          label = 'Syncing…';
        case SyncStatus.synced:
          dotColor = AppColors.savedGreen;
          label = 'Synced';
        default:
          dotColor = _localGrey;
          label = 'Local';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay({
    required this.seconds,
    required this.onStop,
    required this.isDark,
    required this.amplitude,
    required this.liveTranscript,
  });

  final int seconds;
  final VoidCallback onStop;
  final bool isDark;
  final double amplitude;
  final String liveTranscript;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final recordRed =
        isDark ? AppColors.darkRecordRed : AppColors.lightRecordRed;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final timerText =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: recordRed, width: 1),
        boxShadow: [
          BoxShadow(
            color: recordRed.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          _PulsingStopButton(onTap: onStop, recordRed: recordRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Recording',
                      style: AppTypography.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: recordRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timerText,
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
                if (liveTranscript.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    liveTranscript,
                    style: AppTypography.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: mutedColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _WaveformBars(recordRed: recordRed, amplitude: amplitude),
        ],
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({
    required this.recordRed,
    required this.amplitude,
  });

  final Color recordRed;
  final double amplitude;

  // Per-bar scale coefficients — gives each bar a distinct relative height.
  static const List<double> _coefficients = [
    0.33, 0.67, 0.50, 1.00, 0.67, 0.83,
    0.33, 0.58, 0.75, 0.42, 0.92, 0.67,
  ];

  static const double _minH = 4.0;
  static const double _maxH = 24.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < _coefficients.length; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 3,
            height: _minH + amplitude * (_maxH - _minH) * _coefficients[i],
            decoration: BoxDecoration(
              color: recordRed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (i < _coefficients.length - 1) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

// ─── _NoteOptionsSheet ───────────────────────────────────────────────────────

/// Bottom sheet shown from the ⋮ button in [_EditorAppBar].
/// Offers Pin/Unpin, Archive/Restore, and Delete.
class _NoteOptionsSheet extends StatelessWidget {
  const _NoteOptionsSheet({
    required this.note,
    required this.onAiAssist,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onAiAssist;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final variantColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: outlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: AppTypography.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          _OptionsRow(
            icon: Icons.auto_awesome,
            label: 'AI assist',
            color: AppColors.accent,
            onTap: onAiAssist,
          ),
          _OptionsRow(
            icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: note.isPinned ? 'Unpin' : 'Pin to top',
            color: variantColor,
            onTap: onPin,
          ),
          _OptionsRow(
            icon: Icons.archive_outlined,
            label: 'Archive',
            color: variantColor,
            onTap: onArchive,
          ),
          _OptionsRow(
            icon: Icons.delete_outline,
            label: 'Delete note',
            color: errorColor,
            onTap: onDelete,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _TagSuggestBanner + _AiToolsSheet (Stage 1 AI) ──────────────────────────

/// Dismissible banner of AI-suggested tags shown above the tag row.
/// Tapping a chip adds the tag; the × dismisses the banner.
class _TagSuggestBanner extends StatelessWidget {
  const _TagSuggestBanner({
    required this.suggestions,
    required this.isDark,
    required this.onAccept,
    required this.onDismiss,
  });

  final List<String> suggestions;
  final bool isDark;
  final void Function(String name) onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested tags',
                  style: AppTypography.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: variantColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in suggestions)
                      GestureDetector(
                        onTap: () => onAccept(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.40),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 13, color: AppColors.accent),
                              const SizedBox(width: 3),
                              Text(
                                name,
                                style: AppTypography.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 16, color: variantColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAction {
  const _AiAction(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const List<_AiAction> _kAiActions = [
  _AiAction('improve', 'Improve', Icons.auto_fix_high),
  _AiAction('humanize', 'Humanize', Icons.record_voice_over_outlined),
  _AiAction('paraphrase', 'Paraphrase', Icons.short_text),
  _AiAction('script', 'Format as script', Icons.movie_outlined),
  _AiAction('critique', 'Critique', Icons.rate_review_outlined),
  _AiAction('summary', 'Summarise', Icons.notes_outlined),
];

/// Bottom sheet of Groq-powered writing actions. Calls the backend and lets the
/// user Insert / Replace / Copy the result. Spec: PHASE_12_PLAN.md Stage 1.
class _AiToolsSheet extends ConsumerStatefulWidget {
  const _AiToolsSheet({
    required this.note,
    required this.tagNames,
    required this.onInsert,
    required this.onReplace,
    required this.onInsertSummary,
    this.contentOverride,
  });

  final Note note;
  final List<String> tagNames;

  /// When set, the AI acts on this text instead of the note body (e.g. a voice
  /// transcript being paraphrased).
  final String? contentOverride;
  final void Function(String text) onInsert;
  final void Function(String text) onReplace;
  final void Function(String summary) onInsertSummary;

  @override
  ConsumerState<_AiToolsSheet> createState() => _AiToolsSheetState();
}

class _AiToolsSheetState extends ConsumerState<_AiToolsSheet> {
  _AiAction? _action;
  bool _loading = false;
  String? _result;
  bool _failed = false;

  Future<void> _run(_AiAction action) async {
    setState(() {
      _action = action;
      _loading = true;
      _result = null;
      _failed = false;
    });
    final svc = ref.read(remoteNoteServiceProvider);
    final content =
        widget.contentOverride ?? plainTextFromDelta(widget.note.content);
    try {
      final out = action.id == 'summary'
          ? await svc.summariseNote(
              noteId: widget.note.id,
              title: widget.note.title,
              content: content,
            )
          : await svc.assist(
              noteId: widget.note.id,
              action: action.id,
              title: widget.note.title,
              content: content,
              tags: widget.tagNames,
            );
      if (mounted) {
        setState(() {
          _result = out;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _reset() => setState(() {
        _action = null;
        _result = null;
        _failed = false;
      });

  void _copy(String text) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();
    messenger.showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    _action == null ? 'AI assist' : _action!.label,
                    style: AppTypography.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
            _buildBody(isDark, onSurface, variantColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color onSurface, Color variantColor) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(height: 14),
              Text(
                'Thinking…',
                style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: variantColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_failed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI request failed — try again.',
              style: AppTypography.inter(
                  fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
            ),
            const SizedBox(height: 12),
            _AiSheetButton(
              label: 'Back',
              icon: Icons.arrow_back,
              filled: false,
              isDark: isDark,
              onTap: _reset,
            ),
          ],
        ),
      );
    }

    if (_result != null) {
      final isSummary = _action?.id == 'summary';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SelectableText(
                _result!,
                style: AppTypography.inter(
                    fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isSummary)
                  _AiSheetButton(
                    label: 'Insert as quote',
                    icon: Icons.format_quote,
                    filled: true,
                    isDark: isDark,
                    onTap: () {
                      widget.onInsertSummary(_result!);
                      Navigator.of(context).pop();
                    },
                  )
                else ...[
                  _AiSheetButton(
                    label: 'Insert',
                    icon: Icons.south,
                    filled: true,
                    isDark: isDark,
                    onTap: () {
                      widget.onInsert(_result!);
                      Navigator.of(context).pop();
                    },
                  ),
                  _AiSheetButton(
                    label: 'Replace',
                    icon: Icons.swap_horiz,
                    filled: false,
                    isDark: isDark,
                    onTap: () {
                      widget.onReplace(_result!);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
                _AiSheetButton(
                  label: 'Copy',
                  icon: Icons.copy_outlined,
                  filled: false,
                  isDark: isDark,
                  onTap: () => _copy(_result!),
                ),
                _AiSheetButton(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  filled: false,
                  isDark: isDark,
                  onTap: _reset,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Action list
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in _kAiActions)
          _OptionsRow(
            icon: action.icon,
            label: action.label,
            color: onSurface,
            onTap: () => _run(action),
          ),
      ],
    );
  }
}

class _AiSheetButton extends StatelessWidget {
  const _AiSheetButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final fg = filled ? AppColors.accentOn : variantColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(
                  color: variantColor.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _TagInputSheet ───────────────────────────────────────────────────────────

/// Bottom sheet with a live-autocomplete text field for adding a tag.
/// Pops with the [Tag] to add, or null if cancelled.
/// Finds existing tags via [TagListViewModel.searchByPrefix] and
/// [TagListViewModel.findByName]; creates new tags via [TagListViewModel.insert].
class _TagInputSheet extends ConsumerStatefulWidget {
  const _TagInputSheet({required this.noteTagIds});

  /// IDs of tags already on the note — filtered out of suggestions.
  final List<String> noteTagIds;

  @override
  ConsumerState<_TagInputSheet> createState() => _TagInputSheetState();
}

class _TagInputSheetState extends ConsumerState<_TagInputSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Tag> _suggestions = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final results = await ref
          .read(tagListViewModelProvider.notifier)
          .searchByPrefix(value);
      // Filter tags already on the note.
      final filtered =
          results.where((t) => !widget.noteTagIds.contains(t.id)).toList();
      if (mounted) setState(() => _suggestions = filtered);
    });
  }

  Future<void> _submit() async {
    final name = _ctrl.text.normalised;
    if (name.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final existing =
          await ref.read(tagListViewModelProvider.notifier).findByName(name);
      if (!mounted) return;
      if (existing != null) {
        if (widget.noteTagIds.contains(existing.id)) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Tag already added')));
          setState(() => _isSubmitting = false);
          return;
        }
        Navigator.of(context).pop(existing);
      } else {
        final newTag =
            await ref.read(tagListViewModelProvider.notifier).insert(name);
        if (mounted) Navigator.of(context).pop(newTag);
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _selectSuggestion(Tag tag) {
    Navigator.of(context).pop(tag);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    // Determine if the current input text has an exact match in suggestions.
    final normInput = _ctrl.text.normalised;
    final hasExactMatch =
        _suggestions.any((t) => t.name == normInput);
    final showCreate = normInput.isNotEmpty && !hasExactMatch;

    // All existing tags not already on this note — shown when field is empty.
    final allTags = (ref.watch(tagListViewModelProvider).valueOrNull ?? <Tag>[])
        .where((t) => !widget.noteTagIds.contains(t.id))
        .toList();
    final isSearching = normInput.isNotEmpty;
    final displayList = isSearching ? _suggestions : allTags;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Add tag',
                style: AppTypography.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: onSurface,
                ),
              ),
            ),
            // Input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 18, color: mutedColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.none,
                        style: AppTypography.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: 'e.g. photography',
                          hintStyle: AppTypography.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: mutedColor,
                          ),
                        ),
                        onChanged: _onChanged,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    if (_isSubmitting)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: mutedColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tag list (all when empty, prefix-filtered when typing) + create option
            if (displayList.isNotEmpty || showCreate)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  children: [
                    if (!isSearching && displayList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                        child: Text(
                          'All tags',
                          style: AppTypography.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    for (final tag in displayList)
                      _SuggestionTile(
                        tag: tag,
                        chipBg: chipBg,
                        chipText: chipText,
                        onSurface: onSurface,
                        variantColor: variantColor,
                        onTap: () => _selectSuggestion(tag),
                      ),
                    if (showCreate)
                      _CreateTile(
                        name: normInput,
                        outlineStrong: outlineStrong,
                        onSurface: onSurface,
                        variantColor: variantColor,
                        onTap: _submit,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.tag,
    required this.chipBg,
    required this.chipText,
    required this.onSurface,
    required this.variantColor,
    required this.onTap,
  });

  final Tag tag;
  final Color chipBg;
  final Color chipText;
  final Color onSurface;
  final Color variantColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '#${tag.name}',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chipText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Use existing tag',
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: variantColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({
    required this.name,
    required this.outlineStrong,
    required this.onSurface,
    required this.variantColor,
    required this.onTap,
  });

  final String name;
  final Color outlineStrong;
  final Color onSurface;
  final Color variantColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineStrong, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: variantColor),
            const SizedBox(width: 8),
            Text(
              'Create "#$name"',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingStopButton extends StatefulWidget {
  const _PulsingStopButton({required this.onTap, required this.recordRed});

  final VoidCallback onTap;
  final Color recordRed;

  @override
  State<_PulsingStopButton> createState() => _PulsingStopButtonState();
}

class _PulsingStopButtonState extends State<_PulsingStopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.recordRed,
            boxShadow: [
              BoxShadow(
                color: widget.recordRed.withValues(alpha: 0.20),
                blurRadius: 0,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
