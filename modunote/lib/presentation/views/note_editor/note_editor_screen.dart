import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Note editor — rich text editing with flutter_quill.
/// Phase 1: placeholder scaffold.
/// Phase 5: full implementation with Quill editor, format toolbar, tag row, audio.
class NoteEditorScreen extends ConsumerWidget {
  const NoteEditorScreen({super.key, this.noteId});

  /// Null = new note. Non-null = editing existing note.
  final String? noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(noteId == null ? 'New Note' : 'Edit Note'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✏️  Note Editor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              noteId == null
                  ? 'Phase 5 — new note, coming soon'
                  : 'Phase 5 — editing note $noteId, coming soon',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
