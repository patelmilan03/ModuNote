import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/note.dart';
import '../../router/app_router.dart';
import '../../viewmodels/note_list_view_model.dart';
import '../../viewmodels/tag_list_view_model.dart';
import '../../widgets/mn_search_field.dart';
import 'widgets/app_bar_section.dart';
import 'widgets/ask_notes_card.dart';
import 'widgets/filter_chip_bar.dart';
import 'widgets/note_list_states.dart';
import 'widgets/section_header.dart';
import 'widgets/swipeable_note_card.dart';

/// Home screen — two-section note list (Pinned + Recent).
/// Phase 4 full implementation.
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

    final children = <Widget>[
      const AppBarSection(),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MNSearchField(
          onTap: () => context.go(AppRoutes.search),
        ),
      ),
      const SizedBox(height: 10),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: AskNotesCard(),
      ),
      const SizedBox(height: 10),
      const FilterChipBar(),
    ];

    if (pinned.isNotEmpty) {
      children.add(SectionHeader(title: 'PINNED', count: pinned.length));
      for (final note in pinned) {
        children.add(const SizedBox(height: 10));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SwipeableNoteCard(
              note: note,
              tagNames: _tagNames(note.tagIds),
            ),
          ),
        );
      }
    }

    if (recent.isNotEmpty) {
      if (pinned.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(const SectionHeader(title: 'RECENT'));
      for (final note in recent) {
        children.add(const SizedBox(height: 10));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SwipeableNoteCard(
              note: note,
              tagNames: _tagNames(note.tagIds),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 150),
      children: children,
    );
  }
}
