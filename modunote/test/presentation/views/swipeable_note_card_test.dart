import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/presentation/views/note_list/widgets/swipeable_note_card.dart';

import '../../util/mocks.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final note = Note(
    id: 'n1',
    title: 'Hook ideas',
    content: const {'ops': []},
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );

  // Mirrors Home: the card lives in a *nested* navigator (the ShellRoute's),
  // inside the root navigator that also hosts the floating dock.
  Future<MockNoteRepository> pumpHome(WidgetTester tester) async {
    final repo = MockNoteRepository();
    when(() => repo.watchAll()).thenAnswer((_) => Stream.value([note]));
    when(() => repo.togglePin(any())).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: SwipeableNoteCard(note: note, tagNames: const []),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return repo;
  }

  testWidgets('long-press sheet opens on the root navigator, above the shell',
      (tester) async {
    await pumpHome(tester);

    await tester.longPress(find.text('Hook ideas'));
    await tester.pumpAndSettle();

    expect(find.text('Pin to top'), findsOneWidget);
    // The sheet must NOT be inside the nested navigator, which is the subtree
    // the floating nav is drawn over.
    final nested = find.byType(Navigator).last;
    expect(
      find.descendant(of: nested, matching: find.text('Pin to top')),
      findsNothing,
    );
  });

  testWidgets('picking an action closes only the sheet and runs the action',
      (tester) async {
    final repo = await pumpHome(tester);

    await tester.longPress(find.text('Hook ideas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin to top'));
    await tester.pumpAndSettle();

    expect(find.text('Pin to top'), findsNothing);
    expect(find.text('Hook ideas'), findsOneWidget,
        reason: 'the nested Home page must not be popped');
    verify(() => repo.togglePin('n1')).called(1);
  });
}
