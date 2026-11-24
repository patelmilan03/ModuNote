import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modunote/presentation/router/route_transitions.dart';

void main() {
  test('RevealOrigin survives the JSON-safe extra round trip', () {
    const o = RevealOrigin(Rect.fromLTWH(10, 20, 30, 40), circle: true);
    final back = RevealOrigin.fromExtra(o.toExtra())!;
    expect(back.rect, o.rect);
    expect(back.circle, isTrue);
    expect(RevealOrigin.fromExtra(null), isNull);
    expect(RevealOrigin.fromExtra({'revealL': 'x'}), isNull);
  });

  GoRouter router() => GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: Builder(
                builder: (cardContext) => GestureDetector(
                  key: const Key('card'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/b',
                      extra: RevealOrigin.of(cardContext)?.toExtra()),
                  child: const SizedBox(width: 100, height: 80),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/b',
          pageBuilder: (_, state) =>
              revealPage(state, const Scaffold(body: Text('editor'))),
        ),
      ]);

  /// The reveal clip's bounds, or null when no reveal is on screen.
  Rect? revealBounds(WidgetTester tester) {
    final clips = tester
        .widgetList<ClipPath>(find.byType(ClipPath))
        .where((c) => c.clipper.runtimeType.toString() == '_PathClipper');
    if (clips.isEmpty) return null;
    return clips.first.clipper!.getClip(const Size(800, 600)).getBounds();
  }

  testWidgets('editor grows out of the tapped card', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
    final card = tester.getRect(find.byKey(const Key('card')));

    await tester.tap(find.byKey(const Key('card')));
    await tester.pump(); // start the push
    await tester.pump(const Duration(milliseconds: 120));

    final mid = revealBounds(tester)!;
    expect(mid.width, greaterThan(card.width));
    expect(mid.width, lessThan(800));
    expect(mid.contains(card.center), isTrue);

    await tester.pumpAndSettle();
    expect(find.text('editor'), findsOneWidget);
  });

  testWidgets('reduced motion skips the reveal', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router()));
    await tester.tap(find.byKey(const Key('card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(revealBounds(tester), isNull);
  });
}
