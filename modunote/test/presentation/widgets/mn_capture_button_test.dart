import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modunote/presentation/widgets/mn_capture_button.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host(ValueChanged<CaptureKind> onCapture) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: MNCaptureButton(onCapture: onCapture),
          ),
        ),
      );

  testWidgets('tap opens the three capture actions', (tester) async {
    await tester.pumpWidget(host((_) {}));
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
    await tester.pumpWidget(host((k) => picked = k));

    await tester.tap(find.bySemanticsLabel('New note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(picked, CaptureKind.checklist);
    expect(find.text('Checklist'), findsNothing);
  });
}
