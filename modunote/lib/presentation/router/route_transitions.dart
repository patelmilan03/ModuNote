import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page transitions for the UI revamp (2026-11). Every one collapses to an
/// instant switch when the OS asks for reduced motion.
///
/// - Dock tabs: fade-through.
/// - Settings / Archive: horizontal shared axis.
/// - Note editor: grows out of the tapped card (rounded rect) or the capture
///   button (circle) when the push passes a [RevealOrigin] as `extra`;
///   otherwise falls back to the shared axis.

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Fade-through page for the shell tabs.
Page<void> fadeThroughPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondary, child) =>
          _reduceMotion(context)
              ? child
              : FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondary,
                  fillColor: Colors.transparent,
                  child: child,
                ),
    );

/// Horizontal shared-axis page for pushed screens (Settings, Archive).
Page<void> sharedAxisPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondary, child) =>
          _reduceMotion(context)
              ? child
              : SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondary,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  child: child,
                ),
    );

/// Where an editor push starts from: the global rect of the tapped widget.
/// Travels as GoRouter `extra` in a JSON-safe map so web history can
/// serialise it.
class RevealOrigin {
  const RevealOrigin(this.rect, {this.circle = false});

  final Rect rect;

  /// true = circle reveal (capture button), false = card grow.
  final bool circle;

  /// Measures [context]'s render box. Null if it isn't laid out yet.
  static RevealOrigin? of(BuildContext context, {bool circle = false}) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return RevealOrigin(box.localToGlobal(Offset.zero) & box.size,
        circle: circle);
  }

  Map<String, Object> toExtra() => {
        'revealL': rect.left,
        'revealT': rect.top,
        'revealW': rect.width,
        'revealH': rect.height,
        'revealCircle': circle,
      };

  static RevealOrigin? fromExtra(Object? extra) {
    if (extra is! Map) return null;
    final l = extra['revealL'], t = extra['revealT'];
    final w = extra['revealW'], h = extra['revealH'];
    if (l is! num || t is! num || w is! num || h is! num) return null;
    return RevealOrigin(
      Rect.fromLTWH(l.toDouble(), t.toDouble(), w.toDouble(), h.toDouble()),
      circle: extra['revealCircle'] == true,
    );
  }
}

/// Editor page: grows from the [RevealOrigin] in `state.extra`, else a
/// shared-axis slide.
Page<void> revealPage(GoRouterState state, Widget child) {
  final origin = RevealOrigin.fromExtra(state.extra);
  if (origin == null) return sharedAxisPage(state, child);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondary, child) =>
        _reduceMotion(context)
            ? child
            : _RevealTransition(
                animation: animation, origin: origin, child: child),
  );
}

class _RevealTransition extends StatelessWidget {
  const _RevealTransition({
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final RevealOrigin origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCubic.flipped,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final full = Offset.zero & c.biggest;
        return AnimatedBuilder(
          animation: curved,
          builder: (context, child) {
            final t = curved.value;
            final Path clip;
            if (origin.circle) {
              final centre = origin.rect.center;
              final far = [
                full.topLeft,
                full.topRight,
                full.bottomLeft,
                full.bottomRight,
              ].map((p) => (p - centre).distance).reduce(math.max);
              final r = origin.rect.shortestSide / 2 +
                  (far - origin.rect.shortestSide / 2) * t;
              clip = Path()
                ..addOval(Rect.fromCircle(center: centre, radius: r));
            } else {
              final rect = Rect.lerp(origin.rect, full, t)!;
              clip = Path()
                ..addRRect(RRect.fromRectAndRadius(
                    rect, Radius.circular(22 * (1 - t))));
            }
            return ClipPath(
              clipper: _PathClipper(clip),
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Opacity(
                  // Content fades in over the first 40% so the shape leads.
                  opacity: const Interval(0, 0.4).transform(t),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}
