import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modunote/presentation/widgets/mn_capture_button.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host(CaptureCallback onCapture) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: MNCaptureButton(onCapture: onCapture),
          ),
        ),
      );

  testWidgets('tap opens the three capture actions', (tester) async {
    await tester.pumpWidget(host((_, __) {}));
    expect(find.text('Checklist'), findsNothing);

    await tester.tap(find.bySemanticsLabel('New note'));
    await tester.pumpAndSettle();

    expect(find.text('Voice note'), findsOneWidget);
    expect(find.text('Text note'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
  });

  testWidgets('picking an action closes the menu and reports the kind',
      (tester) async {
    CaptureKind? picked;
    Rect? origin;
    await tester.pumpWidget(host((k, o) {
      picked = k;
      origin = o;
    }));

    await tester.tap(find.bySemanticsLabel('New note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(picked, CaptureKind.checklist);
    expect(origin?.size, const Size.square(MNCaptureButton.size));
    expect(find.text('Checklist'), findsNothing);
  });

  testWidgets('actions fly out of the button and get pulled back in',
      (tester) async {
    await tester.pumpWidget(host((_, __) {}));
    final button = tester.getCenter(find.bySemanticsLabel('New note'));

    await tester.tap(find.bySemanticsLabel('New note'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final early = tester.getCenter(find.text('Voice note')).dy;

    await tester.pumpAndSettle();
    final settled = tester.getCenter(find.text('Voice note')).dy;
    // Starts down near the button, ends above it.
    expect(early, greaterThan(settled));
    expect(settled, lessThan(button.dy));

    // Closing reverses it: mid-way the action is back on its way down.
    await tester.tap(find.bySemanticsLabel('New note').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getCenter(find.text('Voice note')).dy, greaterThan(settled));
    await tester.pumpAndSettle();
    expect(find.text('Voice note'), findsNothing);
  });
}
