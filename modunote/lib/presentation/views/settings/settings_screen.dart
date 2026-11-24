import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/app_router.dart';
import '../../viewmodels/audio_pref_view_model.dart';
import 'widgets/account_card.dart';
import 'widgets/appearance_card.dart';
import 'widgets/archive_card.dart';
import 'widgets/rag_tags_card.dart';
import 'widgets/settings_app_bar.dart';
import 'widgets/voice_notes_card.dart';

/// Settings screen — account, appearance, archive, voice notes, Ask scope.
/// Pushed from the Home avatar (UI revamp); the route wraps it in a
/// Scaffold + SafeArea, so this returns body content only.
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.6 | Decision: D9.5
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        SettingsAppBar(isDark: isDark),
        const SizedBox(height: 8),
        const AccountCard(),
        const SizedBox(height: 16),
        AppearanceCard(
          themeMode: themeMode,
          isDark: isDark,
          onSelectLight: () =>
              ref.read(themeModeNotifierProvider.notifier).setLight(),
          onSelectDark: () =>
              ref.read(themeModeNotifierProvider.notifier).setDark(),
          onSelectSystem: () =>
              ref.read(themeModeNotifierProvider.notifier).setSystem(),
        ),
        const SizedBox(height: 16),
        ArchiveCard(isDark: isDark),
        const SizedBox(height: 16),
        VoiceNotesCard(
          isDark: isDark,
          confirmDelete: ref.watch(audioDeleteConfirmProvider),
          onChanged: (v) =>
              ref.read(audioDeleteConfirmProvider.notifier).setAsk(v),
        ),
        const SizedBox(height: 16),
        RagTagsCard(isDark: isDark),
      ],
    );
  }
}
