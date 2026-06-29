import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/tag.dart';
import '../../router/app_router.dart';
import '../../viewmodels/audio_pref_view_model.dart';
import '../../viewmodels/rag_reindex_view_model.dart';
import '../../viewmodels/rag_settings_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';

/// Settings screen — Appearance theme toggle + Archive link.
/// The shell [_AppShell] provides the outer Scaffold and SafeArea;
/// this screen returns body content only (no Scaffold wrapper).
/// Spec: MODUNOTE_UI_REFERENCE.md § 3.6 | Decision: D9.5
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
      children: [
        _SettingsAppBar(isDark: isDark),
        const SizedBox(height: 16),
        _AppearanceCard(
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
        _ArchiveCard(isDark: isDark),
        const SizedBox(height: 16),
        _VoiceNotesCard(
          isDark: isDark,
          confirmDelete: ref.watch(audioDeleteConfirmProvider),
          onChanged: (v) =>
              ref.read(audioDeleteConfirmProvider.notifier).setAsk(v),
        ),
        const SizedBox(height: 16),
        _RagTagsCard(isDark: isDark),
      ],
    );
  }
}

// ── RAG trigger tags card (Phase 12 Stage 2) ─────────────────────────────────

/// Lets the user choose which tags mark a note for "Ask your notes" indexing.
class _RagTagsCard extends ConsumerWidget {
  const _RagTagsCard({required this.isDark});

  final bool isDark;

  /// Adds a trigger tag by picking from the user's EXISTING tags only — no
  /// free-text creation (a trigger tag matching no real tag can never index
  /// anything). Lists tags from [tagListViewModelProvider] minus those already
  /// selected.
  Future<void> _pickExistingTag(
      BuildContext context, WidgetRef ref, List<Tag> allTags) async {
    if (allTags.isEmpty) {
      // Rate-limited (see app_toast) so rapid taps don't stack toasts.
      showInfoToast('Create some tags on your notes first.');
      return;
    }
    final scope = ref.read(ragIndexTagsProvider);
    if (allTags.every((t) => scope.contains(t.name))) {
      showInfoToast('All your tags are already in the scope.');
      return;
    }

    // useRootNavigator so the sheet renders ABOVE the floating bottom bar.
    // The sheet is self-contained (multi-add): tapping a tag adds it to the
    // scope and the remaining tags reflow, so no return value is needed.
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagPickerSheet(allTags: allTags, isDark: isDark),
    );
  }

  /// Re-indexes every existing note that carries a scope tag, then reports the
  /// outcome via an app-wide toast.
  Future<void> _reindexAll(WidgetRef ref) async {
    final result = await ref.read(ragReindexProvider.notifier).reindexAll();
    if (result.ok == 0 && result.fail == 0) {
      showInfoToast('No notes match your scope tags yet.');
    } else if (result.fail == 0) {
      showSuccessToast(
        'Indexed ${result.ok} note${result.ok == 1 ? '' : 's'} for AI search.',
      );
    } else {
      showErrorToast(
        '${result.ok} indexed, ${result.fail} failed — check connection.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(ragIndexTagsProvider).toList()..sort();
    // Watch (not read) so the tag list stays alive + populated on this screen;
    // a bare read of this auto-dispose provider returns AsyncLoading (empty).
    final allTags =
        ref.watch(tagListViewModelProvider).valueOrNull ?? const <Tag>[];
    final isReindexing = ref.watch(ragReindexProvider);
    final cs = Theme.of(context).colorScheme;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: muted),
              const SizedBox(width: 10),
              Text(
                'Ask your notes — scope',
                style: AppTypography.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Notes with any of these tags are indexed for AI answers. '
            'Reopen a note after changing tags here to apply the change.',
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                _TriggerTagChip(
                  label: tag,
                  isDark: isDark,
                  onRemove: () =>
                      ref.read(ragIndexTagsProvider.notifier).removeTag(tag),
                ),
              _AddTriggerTagChip(
                isDark: isDark,
                onTap: () => _pickExistingTag(context, ref, allTags),
              ),
            ],
          ),
          if (tags.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No tags selected — no notes will be indexed for QnA.',
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: isReindexing ? null : () => _reindexAll(ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReindexing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimaryContainer,
                      ),
                    )
                  else
                    Icon(Icons.sync, size: 18, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    isReindexing
                        ? 'Re-indexing…'
                        : 'Re-index all notes now',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerTagChip extends StatelessWidget {
  const _TriggerTagChip({
    required this.label,
    required this.isDark,
    required this.onRemove,
  });

  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 15, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _AddTriggerTagChip extends StatelessWidget {
  const _AddTriggerTagChip({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: outlineStrong, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 15, color: muted),
            const SizedBox(width: 4),
            Text(
              'add tag',
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the user's existing tags to add to the RAG scope.
/// Self-contained multi-add: tapping a tag adds it to the scope immediately,
/// the tag disappears from the list, and the remaining tags reflow. Dismiss by
/// swiping down or tapping the backdrop.
class _TagPickerSheet extends ConsumerWidget {
  const _TagPickerSheet({required this.allTags, required this.isDark});

  final List<Tag> allTags;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(ragIndexTagsProvider);
    final available = allTags.where((t) => !scope.contains(t.name)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final chipBg = isDark ? AppColors.darkChipBg : AppColors.lightChipBg;
    final chipText = isDark ? AppColors.darkChipText : AppColors.lightChipText;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: outlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add tags to the scope',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: available.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'All your tags are in the scope.',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: muted,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in available)
                            GestureDetector(
                              onTap: () => ref
                                  .read(ragIndexTagsProvider.notifier)
                                  .addTag(tag.name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add,
                                        size: 14, color: chipText),
                                    const SizedBox(width: 4),
                                    Text(
                                      '#${tag.name}',
                                      style: AppTypography.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: chipText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice notes card ─────────────────────────────────────────────────────────

class _VoiceNotesCard extends StatelessWidget {
  const _VoiceNotesCard({
    required this.isDark,
    required this.confirmDelete,
    required this.onChanged,
  });

  final bool isDark;
  final bool confirmDelete;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_none, size: 22, color: muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm before deleting voice notes',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask for confirmation when removing a recording.',
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: confirmDelete,
            onChanged: onChanged,
            // Explicit colors so BOTH states read clearly in light & dark
            // (the default off-state thumb/track was hard to see).
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : muted,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.accent
                  : surfaceContainer,
            ),
            trackOutlineColor: WidgetStateProperty.all(outline),
          ),
        ],
      ),
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────

class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Text(
        'Settings',
        style: AppTypography.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: onSurface,
        ),
      ),
    );
  }
}

// ── Appearance card ────────────────────────────────────────────────────────────

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.themeMode,
    required this.isDark,
    required this.onSelectLight,
    required this.onSelectDark,
    required this.onSelectSystem,
  });

  final ThemeMode themeMode;
  final bool isDark;
  final VoidCallback onSelectLight;
  final VoidCallback onSelectDark;
  final VoidCallback onSelectSystem;

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: AppTypography.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how ModuNote looks on your device.',
            style: AppTypography.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ThemeTile(
                label: 'Light',
                icon: Icons.light_mode_outlined,
                isSelected: themeMode == ThemeMode.light,
                previewType: _PreviewType.light,
                isDark: isDark,
                onTap: onSelectLight,
              ),
              const SizedBox(width: 8),
              _ThemeTile(
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                isSelected: themeMode == ThemeMode.dark,
                previewType: _PreviewType.dark,
                isDark: isDark,
                onTap: onSelectDark,
              ),
              const SizedBox(width: 8),
              _ThemeTile(
                label: 'System',
                icon: Icons.brightness_auto_outlined,
                isSelected: themeMode == ThemeMode.system,
                previewType: _PreviewType.system,
                isDark: isDark,
                onTap: onSelectSystem,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Theme tile ─────────────────────────────────────────────────────────────────

enum _PreviewType { light, dark, system }

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.previewType,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final _PreviewType previewType;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;
    final surfaceContainer =
        isDark ? AppColors.darkSurfaceContainer : AppColors.lightSurfaceContainer;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: outlineStrong, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniPreview(previewType: previewType),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  _RadioDot(isSelected: isSelected, isDark: isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini preview ───────────────────────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.previewType});

  final _PreviewType previewType;

  @override
  Widget build(BuildContext context) {
    if (previewType == _PreviewType.system) {
      return _SystemMiniPreview();
    }
    final isDarkPreview = previewType == _PreviewType.dark;
    final cardBg =
        isDarkPreview ? AppColors.darkCard : AppColors.lightCard;
    final lineBg = isDarkPreview
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: lineBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: lineBg,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: lineBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemMiniPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: AppColors.lightCard,
                child: const Center(
                  child: Icon(Icons.light_mode_outlined,
                      size: 18, color: AppColors.lightPrimary),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.darkCard,
                child: const Center(
                  child: Icon(Icons.dark_mode_outlined,
                      size: 18, color: AppColors.darkPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radio dot ─────────────────────────────────────────────────────────────────

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected, required this.isDark});

  final bool isSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outlineStrong =
        isDark ? AppColors.darkOutlineStrong : AppColors.lightOutlineStrong;

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? cs.primary : Colors.transparent,
        border: isSelected
            ? null
            : Border.all(color: outlineStrong, width: 1.5),
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.circle, size: 7, color: Colors.white),
            )
          : null,
    );
  }
}

// ── Archive card ───────────────────────────────────────────────────────────────

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final outline = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final onSurface =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.archive),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: outline, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.archive_outlined, size: 22, color: muted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Archived Notes',
                    style: AppTypography.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View, restore, or permanently delete archived notes.',
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}
