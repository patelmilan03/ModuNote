import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../data/models/note.dart';
import '../../data/models/tag.dart';
import 'mn_note_card.dart';

/// Shared skeleton-loader helpers (Phase 12 polish).
///
/// We feed fake domain objects into the REAL row/card widgets and wrap them in
/// a [Skeletonizer], so the loading shimmer always matches the actual layout.

const Map<String, dynamic> _skeletonContent = {
  'ops': [
    {'insert': 'Placeholder preview text for the loading skeleton.\n'},
  ],
};

/// Fake notes for skeleton lists. Stable ids/dates so they never rebuild oddly.
List<Note> skeletonNotes([int count = 6]) => [
      for (var i = 0; i < count; i++)
        Note(
          id: 'skeleton-note-$i',
          title: 'Placeholder note title',
          content: _skeletonContent,
          createdAt: DateTime(2020),
          updatedAt: DateTime(2020),
        ),
    ];

/// Fake tags for the Tags screen skeleton.
List<Tag> skeletonTags([int count = 7]) => [
      for (var i = 0; i < count; i++)
        Tag(
          id: 'skeleton-tag-$i',
          name: 'placeholder tag',
          createdAt: DateTime(2020),
        ),
    ];

/// A shimmering list of note-card skeletons (used by Search + Archive).
class MNSkeletonNoteList extends StatelessWidget {
  const MNSkeletonNoteList({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 150),
  });

  final int count;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final notes = skeletonNotes(count);
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: padding,
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => MNNoteCard(
          note: notes[i],
          tagNames: const ['placeholder'],
          onTap: () {},
        ),
      ),
    );
  }
}
