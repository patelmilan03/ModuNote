import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/datasources/file/audio_file_storage.dart';
import '../../../data/models/audio_record.dart';
import '../../../data/models/note.dart';
import '../../../data/models/tag.dart';
import '../../../services/audio/audio_recording_service.dart';
import '../../../services/speech/speech_to_text_service.dart';
import '../../viewmodels/audio_editor_view_model.dart';
import '../../viewmodels/category_tree_view_model.dart';
import '../../viewmodels/note_editor_view_model.dart';
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

    if (mounted) setState(() => _isDirty = false);
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
  }

  // ─── Recording ────────────────────────────────────────────────────────────

  Future<void> _onMicTap() async {
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
    final finalTranscript = _sttService.accumulatedText.trim();

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

      try {
        await ref
            .read(
                audioEditorViewModelProvider(noteId: _currentNote!.id).notifier)
            .saveRecording(
              filePath: recordingPath,
              durationMs: durationMs,
              fileSizeBytes: fileSize,
              transcript: finalTranscript.isEmpty ? null : finalTranscript,
            );
      } catch (_) {}

      // Insert the transcript at the Quill cursor.
      if (finalTranscript.isNotEmpty && _quillController != null && mounted) {
        _insertTranscriptAtCursor(finalTranscript);
      }
    }

    if (mounted) setState(() => _liveTranscript = '');
  }

  void _insertTranscriptAtCursor(String text) {
    final idx = _quillController!.selection.baseOffset;
    final insertText = '\n$text\n';
    _quillController!.document.insert(idx, insertText);
    _quillController!.updateSelection(
      TextSelection.collapsed(offset: idx + insertText.length),
      ChangeSource.local,
    );
    _scheduleAutoSave();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> _onBack() async {
    if (_isDirty && _quillController != null) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    if (mounted) context.pop();
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
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEditor(
      List<Tag> allTags, String? categoryName, bool isDark) {
    return Stack(
      children: [
        Column(
          children: [
            _EditorAppBar(
              isDirty: _isDirty,
              isDark: isDark,
              titleController: _titleController,
              onBack: _onBack,
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
            // Audio clips row — appears once the note has been saved.
            if (_currentNote != null)
              _AudioClipsRow(
                noteId: _currentNote!.id,
                audioService: _audioService,
                audioStorage: _audioStorage,
                isDark: isDark,
              ),
            MNTagRow(
              tagIds: _currentNote?.tagIds ?? const [],
              allTags: allTags,
              categoryName: categoryName,
              onRemoveTag: _onRemoveTag,
              onAddTagTap: _onAddTagTap,
              onCategoryTap: _onCategoryTap,
              onMicTap: _onMicTap,
              isRecording: _isRecording,
              maxTagsReached:
                  (_currentNote?.tagIds.length ?? 0) >=
                  AppConstants.maxTagsPerNote,
            ),
            MNEditorToolbar(controller: _quillController!),
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

// ─── _AudioClipsRow ───────────────────────────────────────────────────────────

/// Horizontal scrollable row of audio clip chips above the tag row.
/// Only rendered when the note has at least one audio record.
class _AudioClipsRow extends ConsumerStatefulWidget {
  const _AudioClipsRow({
    required this.noteId,
    required this.audioService,
    required this.audioStorage,
    required this.isDark,
  });

  final String noteId;
  final AudioRecordingService audioService;
  final AudioFileStorage audioStorage;
  final bool isDark;

  @override
  ConsumerState<_AudioClipsRow> createState() => _AudioClipsRowState();
}

class _AudioClipsRowState extends ConsumerState<_AudioClipsRow> {
  String? _playingId;

  @override
  void initState() {
    super.initState();
    // Eagerly initialise so playback works even when the user opens a note
    // with existing clips without tapping the mic first. init() is idempotent.
    widget.audioService.init().ignore();
  }

  @override
  void dispose() {
    if (_playingId != null) {
      widget.audioService.stopPlayback();
    }
    super.dispose();
  }

  Future<void> _togglePlayback(AudioRecord record) async {
    if (_playingId == record.id) {
      await widget.audioService.stopPlayback();
      setState(() => _playingId = null);
    } else {
      if (_playingId != null) {
        await widget.audioService.stopPlayback();
      }
      setState(() => _playingId = record.id);
      await widget.audioService.startPlayback(
        record.filePath,
        onDone: () {
          if (mounted) setState(() => _playingId = null);
        },
      );
    }
  }

  Future<void> _delete(AudioRecord record) async {
    if (_playingId == record.id) {
      await widget.audioService.stopPlayback();
      setState(() => _playingId = null);
    }
    await ref
        .read(audioEditorViewModelProvider(noteId: widget.noteId).notifier)
        .deleteRecord(record.id);
    try {
      await widget.audioStorage.deleteFile(record.filePath);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final clipsAsync =
        ref.watch(audioEditorViewModelProvider(noteId: widget.noteId));

    return clipsAsync.when(
      data: (clips) {
        if (clips.isEmpty) return const SizedBox.shrink();
        final outlineColor =
            widget.isDark ? AppColors.darkOutline : AppColors.lightOutline;
        final surfaceBg =
            widget.isDark ? AppColors.darkBg : AppColors.lightBg;
        return Container(
          decoration: BoxDecoration(
            color: surfaceBg,
            border: Border(top: BorderSide(color: outlineColor, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < clips.length; i++) ...[
                  _AudioClipChip(
                    record: clips[i],
                    isPlaying: _playingId == clips[i].id,
                    onPlayPause: () => _togglePlayback(clips[i]),
                    onDelete: () => _delete(clips[i]),
                    isDark: widget.isDark,
                  ),
                  if (i < clips.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AudioClipChip extends StatelessWidget {
  const _AudioClipChip({
    required this.record,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onDelete,
    required this.isDark,
  });

  final AudioRecord record;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onDelete;
  final bool isDark;

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final outlineColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final variantColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 8, right: 6),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outlineColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPlayPause,
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 16,
              color: variantColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(record.durationMs),
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.close, size: 10, color: variantColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Private editor widgets ───────────────────────────────────────────────────

class _EditorAppBar extends StatelessWidget {
  const _EditorAppBar({
    required this.isDirty,
    required this.isDark,
    required this.titleController,
    required this.onBack,
  });

  final bool isDirty;
  final bool isDark;
  final TextEditingController titleController;
  final VoidCallback onBack;

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
          _SaveBadge(isDirty: isDirty, isDark: isDark),
          const SizedBox(width: 6),
          _CircleIconButton(
            icon: Icons.more_vert,
            color: onSurface,
            onTap: () {},
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
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

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
  const _SaveBadge({required this.isDirty, required this.isDark});

  final bool isDirty;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final mutedColor =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final dotColor = isDirty ? mutedColor : AppColors.savedGreen;

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
            isDirty ? 'Saving…' : 'Saved',
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
    final showCreate = normInput.isNotEmpty &&
        !hasExactMatch &&
        !widget.noteTagIds.contains(normInput);

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
            // Suggestion list + create option
            if (_suggestions.isNotEmpty || showCreate)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  children: [
                    for (final tag in _suggestions)
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
