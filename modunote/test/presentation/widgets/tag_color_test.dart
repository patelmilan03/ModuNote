import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modunote/core/theme/app_colors.dart';
import 'package:modunote/data/models/note.dart';
import 'package:modunote/presentation/widgets/mn_note_card.dart';

void main() {
  group('AppColors.tagTintIndex', () {
    test('is stable, case-insensitive and within the tint range', () {
      for (final name in [
        'ideas',
        'youtube',
        'reels',
        'x',
        'a long tag name',
      ]) {
        final i = AppColors.tagTintIndex(name);
        expect(i, inInclusiveRange(0, AppColors.lightTints.length - 1));
        expect(AppColors.tagTintIndex(name), i);
        expect(AppColors.tagTintIndex(name.toUpperCase()), i);
      }
    });

    test('spreads different tags across more than one tint', () {
      final used = {
        for (final n in ['ideas', 'youtube', 'reels', 'research', 'script'])
          AppColors.tagTintIndex(n),
      };
      expect(used.length, greaterThan(1));
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('note card tag chip uses the tag colour ($brightness)', (
      tester,
    ) async {
      final note = Note(
        id: 'n1',
        title: 'Title',
        content: const {'ops': []},
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: MNNoteCard(
              note: note,
              tagNames: const ['ideas'],
              onTap: () {},
            ),
          ),
        ),
      );

      final chip = tester.widget<Container>(
        find
            .ancestor(of: find.text('#ideas'), matching: find.byType(Container))
            .first,
      );
      final deco = chip.decoration! as BoxDecoration;
      final tints =
          brightness == Brightness.dark
              ? AppColors.darkTints
              : AppColors.lightTints;
      expect(deco.color, tints[AppColors.tagTintIndex('ideas')]);
    });
  }
}
