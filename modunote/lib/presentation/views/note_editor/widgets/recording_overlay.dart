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
