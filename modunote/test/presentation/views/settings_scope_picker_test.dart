import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modunote/data/datasources/local/database_providers.dart';
import 'package:modunote/data/models/tag.dart';
import 'package:modunote/data/repositories/interfaces/i_tag_repository.dart';
import 'package:modunote/presentation/views/settings/settings_screen.dart';

class _MockTagRepo extends Mock implements ITagRepository {}

void main() {
  // Regression for the "Ask your notes — scope" picker showing NO existing tags.
  // Root cause: _RagTagsCard read the auto-dispose tagListViewModelProvider
  // (AsyncLoading → empty) instead of watching it. The fix watches it in build.
  testWidgets('scope picker lists the user\'s existing tags', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _MockTagRepo();
    // Neither tag is in the default scope {study, notes, research}, so both
    // should be offered by the picker.
    when(() => repo.watchAll()).thenAnswer(
      (_) => Stream.value([
        Tag(id: 't1', name: 'ideas', createdAt: DateTime(2020)),
        Tag(id: 't2', name: 'project', createdAt: DateTime(2020)),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('add tag'), findsOneWidget);
    await tester.tap(find.text('add tag'));
    await tester.pumpAndSettle();

    // The picker sheet surfaces the existing tags (the bug showed none).
    expect(find.text('#ideas'), findsOneWidget);
    expect(find.text('#project'), findsOneWidget);
  });
}
