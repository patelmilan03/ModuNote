import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// What the capture menu asks the editor to start with.
enum CaptureKind { text, voice, checklist }

/// Called with the chosen kind and the button's global rect (for the
/// circle reveal into the editor), or null if it couldn't be measured.
typedef CaptureCallback = void Function(CaptureKind kind, Rect? origin);

/// Coral capture button that sits beside the dock (Nav A, UI revamp 2026-11).
///
/// Tap → the plus spins (one full turn, landing as an x), the screen dims
/// (ink 80%) and the three labelled actions (Checklist · Text note · Voice
/// note) shoot out of the button one after another, as if the spin pushed
/// them out. Closing runs it backwards: the x spins the other way and pulls
/// them back in. Choosing one calls [onCapture] with the button's rect;
/// tapping the scrim or the x closes the menu.
///
/// The menu is drawn in the Overlay via [OverlayPortal] and pinned to the
/// button with a [LayerLink], so it lines up exactly wherever the dock sits.
class MNCaptureButton extends StatefulWidget {
  const MNCaptureButton({super.key, required this.onCapture});

  final CaptureCallback onCapture;

  static const double size = 64;

  @override
  State<MNCaptureButton> createState() => _MNCaptureButtonState();
}

class _MNCaptureButtonState extends State<MNCaptureButton>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 340),
  );

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  Future<void> _open() async {
    _portal.show();
    if (_reduceMotion) {
      _anim.value = 1;
    } else {
      await _anim.forward();
    }
  }

  Future<void> _close() async {
    if (_reduceMotion) {
      _anim.value = 0;
    } else {
      await _anim.reverse();
    }
    if (mounted) _portal.hide();
  }

  Future<void> _pick(CaptureKind kind) async {
    await _close();
    if (!mounted) return;
    final box = context.findRenderObject();
    final origin =
        box is RenderBox && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : null;
    widget.onCapture(kind, origin);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder:
            (_) => _CaptureMenu(
              animation: _anim,
              link: _link,
              onClose: _close,
              onPick: _pick,
            ),
        child: _CoralButton(animation: _anim, onTap: _open),
      ),
    );
  }
}

class _CoralButton extends StatelessWidget {
  const _CoralButton({required this.animation, required this.onTap});

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coral = AppColors.accentOf(context);
    return Semantics(
      button: true,
      label: 'New note',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MNCaptureButton.size,
          height: MNCaptureButton.size,
          decoration: BoxDecoration(
            color: coral,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: coral.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: RotationTransition(
            // One full spin plus 45° (plus → x); reversing spins it back the
            // other way.
            turns: Tween<double>(begin: 0, end: 1.125).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
                reverseCurve: Curves.easeInBack,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 30,
              color: AppColors.accentOn,
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureMenu extends StatelessWidget {
  const _CaptureMenu({
    required this.animation,
    required this.link,
    required this.onClose,
    required this.onPick,
  });

  final AnimationController animation;
  final LayerLink link;
  final VoidCallback onClose;
  final ValueChanged<CaptureKind> onPick;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tints = isDark ? AppColors.darkTints : AppColors.lightTints;
    final iconColor = isDark ? AppColors.cream : AppColors.ink;

    // Bottom-up order: closest to the button first (Voice), staggered 40 ms.
    final actions = [
      (CaptureKind.voice, 'Voice note', Icons.mic_none_rounded, tints[0]),
      (CaptureKind.text, 'Text note', Icons.notes_rounded, tints[3]),
      (CaptureKind.checklist, 'Checklist', Icons.checklist_rounded, tints[1]),
    ];

    return Stack(
      children: [
        // Scrim
        Positioned.fill(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: GestureDetector(
              onTap: onClose,
              child: ColoredBox(
                color: (isDark ? Colors.black : AppColors.ink).withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ),
        ),
        // Actions column, right-aligned above the button.
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -14),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = actions.length - 1; i >= 0; i--) ...[
                  _StaggeredAction(
                    animation: animation,
                    index: i,
                    label: actions[i].$2,
                    icon: actions[i].$3,
                    tint: actions[i].$4,
                    iconColor: iconColor,
                    onTap: () => onPick(actions[i].$1),
                  ),
                  if (i > 0) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        // A second copy of the button over the real one, so the x is
        // visible and tappable above the scrim.
        CompositedTransformFollower(
          link: link,
          child: _CoralButton(animation: animation, onTap: onClose),
        ),
      ],
    );
  }
}

class _StaggeredAction extends StatelessWidget {
  const _StaggeredAction({
    required this.animation,
    required this.index,
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final Animation<double> animation;
  final int index;
  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  /// Distance from an action tile's centre down to the button's centre:
  /// 14 px gap + half a 52 px tile + half the 64 px button, then 66 px
  /// (tile + gap) per step further up.
  static double _dropToButton(int index) => 72.0 + index * 66.0;

  @override
  Widget build(BuildContext context) {
    // Nearest action first, each ~50 ms after the previous one. Reversing
    // the same intervals pulls the farthest one back in first.
    final start = (index * 0.12).clamp(0.0, 0.5);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + 0.62).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
      reverseCurve: Interval(
        start,
        (start + 0.62).clamp(0.0, 1.0),
        curve: Curves.easeIn,
      ),
    );
    final labelBg = AppColors.cardOf(context);
    final labelFg = Theme.of(context).colorScheme.onSurface;
    final drop = _dropToButton(index);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value; // may overshoot past 1 on the way out
        final shown = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform((shown * 2).clamp(0.0, 1.0)),
          child: Transform.translate(
            // Starts tucked under the button, ends in place.
            offset: Offset(0, drop * (1 - t)),
            child: Transform.rotate(
              // A quarter-turn twist that follows the button's spin.
              angle: (1 - t) * -math.pi / 2,
              alignment: Alignment.centerRight,
              origin: const Offset(-32, 0), // tile centre, over the button
              child: Transform.scale(
                scale: 0.25 + 0.75 * t,
                alignment: Alignment.centerRight,
                origin: const Offset(-32, 0),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: AppTypography.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: labelFg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              // Align the 52 px tiles over the centre of the 64 px button.
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
