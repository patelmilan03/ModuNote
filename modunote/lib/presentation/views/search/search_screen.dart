import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/note.dart';
import '../../../data/models/tag.dart';
import '../../router/app_router.dart';
import '../../router/route_transitions.dart';
import '../../viewmodels/search_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../../core/extensions/quill_extensions.dart';
import '../../viewmodels/category_tree_view_model.dart';
import '../../widgets/mn_empty_badge.dart';
import '../../widgets/mn_note_card.dart' show noteTimestamp;
import '../../widgets/mn_skeletons.dart';

/// Search tab — live full-text search against the note repository.
/// UI revamp 2026-11: big title, white pill field, result cards with a
/// category-coloured stripe and the matched words highlighted in butter.
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
    final searchState = ref.watch(searchViewModelProvider);
    final tagsAsync = ref.watch(tagListViewModelProvider);
    final tagMap = tagsAsync.maybeWhen(
      data: (tags) => {for (final Tag t in tags) t.id: t.name},
      orElse: () => <String, String>{},
    );
    final tintIndex = ref.watch(categoryTintIndexProvider);
    void open(String id, RevealOrigin? origin) =>
        context.push(AppRoutes.editNotePath(id), extra: origin?.toExtra());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Text(
            'Search',
            style: AppTypography.heading(
              fontSize: 34,
              letterSpacing: -0.8,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        _SearchBar(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (q) =>
              ref.read(searchViewModelProvider.notifier).setQuery(q),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: searchState.query.isEmpty
              ? ref.watch(recentNotesProvider).when(
                    data: (notes) => notes.isEmpty
                        ? const _EmptyPrompt()
                        : _ResultList(
                            header: 'Recent',
                            notes: notes,
                            query: '',
                            tagMap: tagMap,
                            tintIndex: tintIndex,
                            onNoteTap: open,
                          ),
                    loading: () => const MNSkeletonNoteList(),
                    error: (_, __) => const _EmptyPrompt(),
                  )
              : searchState.results.when(
                  data: (notes) => notes.isEmpty
                      ? _NoResults(query: searchState.query)
                      : _ResultList(
                          header:
                              '${notes.length} result${notes.length == 1 ? '' : 's'}',
                          notes: notes,
                          query: searchState.query,
                          tagMap: tagMap,
                          tintIndex: tintIndex,
                          onNoteTap: open,
                        ),
                  loading: () => const MNSkeletonNoteList(),
                  error: (_, __) => const _SearchError(),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = AppColors.mutedOf(context);

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search notes and tags',
                hintStyle: AppTypography.inter(
                  fontSize: 15,
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
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: Icon(Icons.close_rounded, size: 20, color: muted),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results
// ─────────────────────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.header,
    required this.notes,
    required this.query,
    required this.tagMap,
    required this.tintIndex,
    required this.onNoteTap,
  });

  final String header;
  final List<Note> notes;
  final String query;
  final Map<String, String> tagMap;
  final Map<String, int> tintIndex;
  final void Function(String id, RevealOrigin? origin) onNoteTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 150),
      itemCount: notes.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
            child: Text(
              header.toUpperCase(),
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.mutedOf(context),
              ),
            ),
          );
        }
        final note = notes[i - 1];
        final cat = note.categoryId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ResultCard(
            note: note,
            query: query,
            tagNames: note.tagIds
                .map((id) => tagMap[id])
                .whereType<String>()
                .toList(),
            tintIndex: cat == null ? null : tintIndex[cat],
            onTap: (origin) => onNoteTap(note.id, origin),
          ),
        );
      },
    );
  }
}

/// White card with a 6 px stripe in the category's colour, the title with
/// the query highlighted, two lines of preview and a tags · time row.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.note,
    required this.query,
    required this.tagNames,
    required this.tintIndex,
    required this.onTap,
  });

  final Note note;
  final String query;
  final List<String> tagNames;
  final int? tintIndex;
  final ValueChanged<RevealOrigin?> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stripe = tintIndex == null
        ? cs.outlineVariant
        : AppColors.tintStripes[tintIndex! % AppColors.tintStripes.length];
    final preview = plainTextFromDelta(note.content).replaceAll('\n', ' ');
    final metaStyle = AppTypography.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
    );
    // Butter highlight; on dark the butter tint is too dark, so use the
    // butter stripe at low alpha instead.
    final highlight = isDark
        ? AppColors.tintStripes[3].withValues(alpha: 0.35)
        : AppColors.lightTints[3];

    return Material(
      color: AppColors.cardOf(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onTap(RevealOrigin.of(context)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: stripe,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        _highlighted(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          AppTypography.heading(
                            fontSize: 16.5,
                            letterSpacing: -0.3,
                            height: 1.2,
                            color: cs.onSurface,
                          ),
                          highlight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text.rich(
                          _highlighted(
                            preview,
                            AppTypography.inter(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ).copyWith(height: 1.4),
                            highlight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tagNames.map((t) => '#$t').join(' '),
                              style: metaStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(noteTimestamp(note.updatedAt), style: metaStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Splits [text] on case-insensitive matches of [query] and paints each
  /// match on a rounded-looking butter background.
  TextSpan _highlighted(String text, TextStyle style, Color highlight) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return TextSpan(text: text, style: style);
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final hit = lower.indexOf(q, start);
      if (hit < 0) break;
      if (hit > start) spans.add(TextSpan(text: text.substring(start, hit)));
      spans.add(TextSpan(
        text: text.substring(hit, hit + q.length),
        style: TextStyle(background: Paint()..color = highlight),
      ));
      start = hit + q.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(style: style, children: spans);
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return const _Message(
      icon: Icons.search_rounded,
      tintIndex: 4,
      title: 'Search your notes',
      body: 'Type to find notes by title, content or tag.',
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: Icons.search_off_rounded,
      tintIndex: 3,
      title: 'Nothing matches "$query"',
      body: 'Try a shorter word or a tag name.',
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError();

  @override
  Widget build(BuildContext context) {
    return const _Message(
      icon: Icons.error_outline_rounded,
      tintIndex: 0,
      title: "Search didn't work",
      body: 'Try again in a moment.',
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.tintIndex,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final int tintIndex;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MNEmptyBadge(icon: icon, tintIndex: tintIndex),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.heading(
                fontSize: 19,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13.5,
                color: AppColors.mutedOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
