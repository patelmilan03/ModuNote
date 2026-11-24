import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/database_providers.dart';

part 'demo_seeder.g.dart';

/// One entry of the read-only demo dataset shown in the WEB portfolio build.
class DemoNote {
  const DemoNote(this.id, this.title, this.body, this.tags, {this.categoryId});
  final String id;
  final String title;
  final String body;
  final List<String> tags;

  /// Demo folder ([demoCategories]) — gives the web demo its note tints.
  final String? categoryId;
}

/// Demo folder: id, name, sort order (which sets its tint: 0 peach, 1 mint,
/// 2 lilac — see `categoryTintIndex`).
typedef DemoCategory = ({String id, String name, int sortOrder});

/// The three folders the web demo notes live in (UI revamp 2026-11, so the
/// portfolio shows the category tints). Web-only; not part of the RAG seed.
const List<DemoCategory> demoCategories = [
  (id: 'demo-cat-youtube', name: 'YouTube', sortOrder: 0),
  (id: 'demo-cat-instagram', name: 'Instagram', sortOrder: 1),
  (id: 'demo-cat-research', name: 'Research', sortOrder: 2),
];

/// The demo notes shown (login-free) in the web portfolio build. The SAME notes
/// (same ids/titles/bodies) are pre-indexed on the backend under the demo user
/// id by `modunote-api/scripts/seed_demo.py`, so the "Ask your notes" RAG demo
/// answers from them and its citations deep-link back to these local notes.
/// KEEP IN SYNC with that seed script.
const List<DemoNote> demoNotes = [
  DemoNote(
    'demo-1',
    'Video series ideas',
    "Series idea: '5-Minute Resets' — a quick mental and desk reset between "
        "work blocks. One reset per episode: box breathing, tidy the desk, a "
        "short walk, drink water, wrist and neck stretches. Keep each under five "
        "minutes; film vertical for Shorts and horizontal for the main channel.",
    ['ideas', 'youtube'],
    categoryId: 'demo-cat-youtube',
  ),
  DemoNote(
    'demo-2',
    'Hooks that work',
    "Best-performing hooks: 'Stop doing X if you want Y', 'I tried X for 30 "
        "days', and 'Nobody talks about X'. The first three seconds must show "
        "the payoff or the problem — cut every slow intro and open on the most "
        "interesting frame.",
    ['scripts', 'hooks'],
    categoryId: 'demo-cat-instagram',
  ),
  DemoNote(
    'demo-3',
    'Thumbnail experiments',
    "Thumbnail test results: an expressive face plus three big words beats "
        "object-only thumbnails clearly. Use one focal point, high contrast, and "
        "text that stays readable at small sizes. Yellow or orange text pops on "
        "dark backgrounds.",
    ['research', 'design'],
    categoryId: 'demo-cat-research',
  ),
  DemoNote(
    'demo-4',
    'Posting schedule',
    "My audience is most active on weekday evenings (6-9pm) and Sunday "
        "mornings. Plan: one Short every day, one long-form video per week, and "
        "cross-post Reels to Instagram the same day. Batch-film on weekends to "
        "stay ahead.",
    ['notes', 'strategy'],
    categoryId: 'demo-cat-instagram',
  ),
  DemoNote(
    'demo-5',
    'Filming setup',
    "Current setup: phone on a tripod, a softbox key light at 45 degrees, and a "
        "lav mic for talking-head shots. Shoot in 4K, edit the vertical 9:16 cut "
        "first, then reframe for horizontal. Keep b-roll organized in folders by "
        "topic.",
    ['notes', 'gear'],
    categoryId: 'demo-cat-youtube',
  ),
  DemoNote(
    'demo-6',
    'Growth research',
    "From studying channels in my niche: consistency and a recognizable format "
        "matter more than production quality early on. Playlists and series "
        "boost watch time, and titles under 60 characters tend to perform best "
        "in search.",
    ['research', 'study'],
    categoryId: 'demo-cat-research',
  ),
];

/// Seeds [demoNotes] into local Drift on the WEB build only, once, so the
/// portfolio demo shows real content with no login or sync. No-op on native and
/// when the database already has notes. Watched once at app start.
///
/// Folders: a browser seeded before [demoCategories] existed has notes but no
/// folders, so the folders are added and filed into once (only demo notes
/// that still have no folder). Once any folder exists this never runs again,
/// so a visitor's own changes stick.
@Riverpod(keepAlive: true)
Future<void> demoSeed(Ref ref) async {
  if (!kIsWeb) return;
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now().toUtc();
  final existing = await db.select(db.notesTable).get();
  final hasFolders =
      (await (db.select(db.categoriesTable)..limit(1)).get()).isNotEmpty;

  if (!hasFolders) {
    for (final c in demoCategories) {
      await db.into(db.categoriesTable).insertOnConflictUpdate(
            CategoriesTableCompanion.insert(
              id: c.id,
              name: c.name,
              sortOrder: drift.Value(c.sortOrder),
              createdAt: now,
            ),
          );
    }
    // Backfill notes seeded by an older build.
    for (final note in demoNotes) {
      await (db.update(db.notesTable)
            ..where((t) => t.id.equals(note.id) & t.categoryId.isNull()))
          .write(NotesTableCompanion(categoryId: drift.Value(note.categoryId)));
    }
  }
  if (existing.isNotEmpty) return; // already seeded / has content

  String tagId(String name) => 'demo-tag-$name';

  // Unique tags first (deterministic ids), then notes, then join rows.
  final tagNames = {for (final n in demoNotes) ...n.tags};
  for (final name in tagNames) {
    await db.into(db.tagsTable).insertOnConflictUpdate(
          TagsTableCompanion.insert(id: tagId(name), name: name, createdAt: now),
        );
  }

  for (final note in demoNotes) {
    final tagIds = [for (final t in note.tags) tagId(t)];
    await db.into(db.notesTable).insertOnConflictUpdate(
          NotesTableCompanion.insert(
            id: note.id,
            title: note.title,
            content: {
              'ops': [
                {'insert': '${note.body}\n'},
              ],
            },
            tagIds: drift.Value(tagIds),
            categoryId: drift.Value(note.categoryId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final tid in tagIds) {
      await db.into(db.noteTagsTable).insertOnConflictUpdate(
            NoteTagsTableCompanion.insert(noteId: note.id, tagId: tid),
          );
    }
  }
}
