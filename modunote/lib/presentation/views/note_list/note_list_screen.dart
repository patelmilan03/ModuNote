import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/note.dart';
import '../../viewmodels/note_list_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../viewmodels/category_tree_view_model.dart';
import 'widgets/app_bar_section.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/note_list_states.dart';
import 'widgets/section_header.dart';
import 'widgets/swipeable_note_card.dart';

/// Home screen — Pinned + Recent sections, each a two-column masonry grid
/// of tinted note cards (UI revamp). Search and Ask are dock tabs now.
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListViewModelProvider);
    final tagsAsync = ref.watch(tagListViewModelProvider);

    // Build id→name lookup; empty map while tags are loading/errored.
    final tagMap = tagsAsync.maybeWhen(
      data: (tags) => {for (final t in tags) t.id: t.name},
      orElse: () => <String, String>{},
    );

    return notesAsync.when(
      data: (notes) {
        final pinned = notes.where((n) => n.isPinned).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final recent = notes.where((n) => !n.isPinned).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return _DataBody(
          pinned: pinned,
          recent: recent,
          tagMap: tagMap,
        );
      },
      loading: () => const LoadingBody(),
      error: (_, __) => ErrorBody(
        onRetry: () => ref.invalidate(noteListViewModelProvider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data state
// ─────────────────────────────────────────────────────────────────────────────

class _DataBody extends ConsumerWidget {
  const _DataBody({
    required this.pinned,
    required this.recent,
    required this.tagMap,
  });

  final List<Note> pinned;
  final List<Note> recent;
  final Map<String, String> tagMap;

  List<String> _tagNames(List<String> ids) =>
      ids.map((id) => tagMap[id]).whereType<String>().toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pinned.isEmpty && recent.isEmpty) {
      final filter = ref.watch(noteFilterNotifierProvider);
      if (filter.type == NoteFilterType.all) {
        return const EmptyState();
      }
      return const FilteredEmptyState();
    }

    final tintIndex = ref.watch(categoryTintIndexProvider);

    Widget card(Note note) => SwipeableNoteCard(
          note: note,
          tagNames: _tagNames(note.tagIds),
          tintIndex: note.categoryId == null ? null : tintIndex[note.categoryId],
        );

    final children = <Widget>[
      const AppBarSection(),
      const SizedBox(height: 14),
      const FilterChipBar(),
      const SizedBox(height: 4),
    ];

    if (pinned.isNotEmpty) {
      children.add(const SectionHeader(title: 'PINNED'));
      children.add(_MasonryGrid(notes: pinned, cardBuilder: card));
    }

    if (recent.isNotEmpty) {
      children.add(const SectionHeader(title: 'RECENT'));
      children.add(_MasonryGrid(notes: recent, cardBuilder: card));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 150),
      children: children,
    );
  }
}

/// Two-column masonry: each note goes to the currently shorter column, using
/// a rough height estimate (title/preview length, tags). Not lazy — fine for
/// a personal notes list.
class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({required this.notes, required this.cardBuilder});

  final List<Note> notes;
  final Widget Function(Note) cardBuilder;

  static const double _gap = 12;

  static double _estimate(Note n) {
    var h = 70.0; // padding + meta row + one title line
    h += (n.title.length ~/ 18).clamp(0, 2) * 20.0;
    final hasBody = (n.content['ops'] as List?)?.length.clamp(0, 1) ?? 0;
    h += hasBody * 40.0;
    if (n.tagIds.isNotEmpty) h += 34;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final left = <Note>[];
    final right = <Note>[];
    var lh = 0.0, rh = 0.0;
    for (final n in notes) {
      if (lh <= rh) {
        left.add(n);
        lh += _estimate(n) + _gap;
      } else {
        right.add(n);
        rh += _estimate(n) + _gap;
      }
    }

    Widget column(List<Note> ns) => Column(
          children: [
            for (final n in ns) ...[
              cardBuilder(n),
              const SizedBox(height: _gap),
            ],
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          const SizedBox(width: _gap),
          Expanded(child: column(right)),
        ],
      ),
    );
  }
}
