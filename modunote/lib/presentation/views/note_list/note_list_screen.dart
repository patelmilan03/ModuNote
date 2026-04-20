import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';

/// Home screen — displays the list of notes.
/// Phase 1: placeholder scaffold.
/// Phase 4: full implementation with MNNoteCard, pinned section, search bar, FAB.
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ModuNote')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📝  Note List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Phase 4 — coming soon',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newNote),
        child: const Icon(Icons.add),
      ),
    );
  }
}
