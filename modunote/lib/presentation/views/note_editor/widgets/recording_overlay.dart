import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Floating card shown while a recording is in progress: pulsing stop button,
/// timer, live transcript preview, and an amplitude-driven waveform.
class RecordingOverlay extends StatelessWidget {
  const RecordingOverlay({
    super.key,
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
    // Revamp: same ink / dock pill as the voice panel it replaces.
    final pillBg = AppColors.dockOf(context);
    const recordRed = AppColors.darkRecordRed; // reads on ink in both themes
    final mutedColor = AppColors.cream.withValues(alpha: 0.6);
    const wave = AppColors.darkAccent;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final timerText =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: recordRed.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: recordRed.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                      style: AppTypography.heading(
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
          _WaveformBars(recordRed: wave, amplitude: amplitude),
        ],
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({required this.recordRed, required this.amplitude});

  final Color recordRed;
  final double amplitude;

  // Per-bar scale coefficients — gives each bar a distinct relative height.
  static const List<double> _coefficients = [
    0.33,
    0.67,
    0.50,
    1.00,
    0.67,
    0.83,
    0.33,
    0.58,
    0.75,
    0.42,
    0.92,
    0.67,
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
    );
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat(reverse: true);
    }
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
      child: Semantics(
        button: true,
        label: 'Stop recording',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 48,
            height: 48,
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
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
