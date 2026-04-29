import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/tag.dart';
import '../../router/app_router.dart';
import '../../viewmodels/search_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_note_card.dart';

/// Explore / Search screen — live full-text search against the note repository.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final searchState = ref.watch(searchViewModelProvider);
    final tagsAsync = ref.watch(tagListViewModelProvider);
    final tagMap = tagsAsync.maybeWhen(
      data: (tags) => {for (final Tag t in tags) t.id: t.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _SearchBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  isDark: isDark,
                  cs: cs,
                  onChanged: (q) =>
                      ref.read(searchViewModelProvider.notifier).setQuery(q),
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: _SearchBody(
                    state: searchState,
                    tagMap: tagMap,
                    onNoteTap: (id) => context.push(AppRoutes.editNotePath(id)),
                  ),
                ),
              ],
            ),
            // ── Floating bottom nav ──────────────────────────────────
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: _BottomNav(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.cs,
    required this.onChanged,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 4),
          // Editable search field
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      style: AppTypography.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search notes, tags…',
                        hintStyle: AppTypography.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: muted,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (_, value, __) => value.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              controller.clear();
                              onChanged('');
                            },
                            child: Icon(Icons.close, size: 18, color: muted),
                          )
                        : const SizedBox.shrink(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.state,
    required this.tagMap,
    required this.onNoteTap,
  });

  final SearchState state;
  final Map<String, String> tagMap;
  final void Function(String id) onNoteTap;

  List<String> _tagNames(List<String> ids) =>
      ids.map((id) => tagMap[id]).whereType<String>().toList();

  @override
  Widget build(BuildContext context) {
    if (state.query.isEmpty) return const _EmptyPrompt();

    return state.results.when(
      data: (notes) {
        if (notes.isEmpty) return _NoResults(query: state.query);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 150),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => MNNoteCard(
            note: notes[i],
            tagNames: _tagNames(notes[i].tagIds),
            onTap: () => onNoteTap(notes[i].id),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _SearchError(),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 52, color: muted),
          const SizedBox(height: 14),
          Text(
            'Search your notes',
            style: AppTypography.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Type to find notes by title or content.',
            style: AppTypography.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 52, color: muted),
          const SizedBox(height: 14),
          Text(
            'No results for "$query"',
            style: AppTypography.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Try different keywords.',
            style: AppTypography.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.error_outline,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating bottom nav — Explore tab active
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x59000000)
                : const Color(0x0A1C1B2E),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavTab(
            icon: Icons.article_outlined,
            activeIcon: Icons.article,
            isActive: false,
            onTap: () => context.go(AppRoutes.home),
          ),
          _NavTab(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            isActive: true,
            onTap: () {},
          ),
          _NavTab(
            icon: Icons.label_outline,
            activeIcon: Icons.label,
            isActive: false,
            onTap: () => context.go(AppRoutes.tags),
          ),
          _NavTab(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            isActive: false,
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? cs.primaryContainer : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 22,
            color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
