import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
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
    if (note != null && note.content['ops'] != null) {
      try {
        doc = Document.fromJson(note.content['ops'] as List);
      } catch (_) {
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
    if (_currentNote == null) {
      _debounce?.cancel();
      await _performAutoSave();
    }
    if (mounted) _showAddTagDialog();
  }

  void _showAddTagDialog() {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add tag'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(hintText: 'e.g. photography'),
          onSubmitted: (value) {
            Navigator.of(ctx).pop();
            final name = value.trim();
            if (name.isNotEmpty) _addTag(name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = textCtrl.text.trim();
              Navigator.of(ctx).pop();
              if (name.isNotEmpty) _addTag(name);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTag(String name) async {
    try {
      final tag =
          await ref.read(tagListViewModelProvider.notifier).insert(name);
      await ref
          .read(noteEditorViewModelProvider(noteId: widget.noteId).notifier)
          .addTag(tag.id);
      _syncCurrentNote();
    } catch (_) {}
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

  // ─── Category stub ────────────────────────────────────────────────────────

  void _showCategoryStub() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        child: const Center(child: Text('Category picker — Phase 8')),
      ),
    );
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
              onCategoryTap: _showCategoryStub,
              onMicTap: _onMicTap,
              isRecording: _isRecording,
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
