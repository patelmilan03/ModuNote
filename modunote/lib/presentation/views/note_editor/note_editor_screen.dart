import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/models/note.dart';
import '../../../data/models/tag.dart';
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
  // ─── Controllers ─────────────────────────────────────────────────────────
  QuillController? _quillController;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  // ─── Subscriptions / timers ───────────────────────────────────────────────
  StreamSubscription<dynamic>? _contentSubscription;
  Timer? _debounce;
  Timer? _recordTimer;

  // ─── UI state ─────────────────────────────────────────────────────────────
  bool _isDirty = false;
  bool _isRecording = false;
  int _recordSeconds = 0;

  // ─── Note tracking ────────────────────────────────────────────────────────
  Note? _currentNote;
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _recordTimer?.cancel();
    _contentSubscription?.cancel();
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _quillController?.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
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
    _debounce =
        Timer(const Duration(milliseconds: 800), _performAutoSave);
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

  void _onMicTap() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    _recordTimer = null;
    setState(() => _isRecording = false);
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
  Widget build(BuildContext context, ) {
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
            ),
          ),
      ],
    );
  }
}

// ─── Private widgets ──────────────────────────────────────────────────────────

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
  });

  final int seconds;
  final VoidCallback onStop;
  final bool isDark;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recording',
                style: AppTypography.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: recordRed,
                ),
              ),
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
          const SizedBox(width: 12),
          Expanded(child: _WaveformBars(recordRed: recordRed)),
        ],
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({required this.recordRed});

  final Color recordRed;

  static const List<double> _heights = [
    8, 16, 12, 24, 16, 20, 8, 14, 18, 10, 22, 16
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < _heights.length; i++) ...[
          Container(
            width: 3,
            height: _heights[i],
            decoration: BoxDecoration(
              color: recordRed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (i < _heights.length - 1) const SizedBox(width: 2),
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
