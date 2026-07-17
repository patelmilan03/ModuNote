import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/datasources/file/audio_file_storage.dart';
import '../../../../data/models/audio_record.dart';
import '../../../../services/audio/audio_recording_service.dart';
import '../../../viewmodels/audio_editor_view_model.dart';
import '../../../viewmodels/audio_pref_view_model.dart';

/// Bottom voice panel: play/pause + seek bar + current:total timers + record
/// button + one-at-a-time carousel over the note's recordings. Expanding shows
/// the transcript with Paraphrase (opens the AI sheet) and Insert-into-note.
/// Live recording feedback is still the separate [RecordingOverlay].
class VoicePanel extends ConsumerStatefulWidget {
  const VoicePanel({
    super.key,
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
  ConsumerState<VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends ConsumerState<VoicePanel> {
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
