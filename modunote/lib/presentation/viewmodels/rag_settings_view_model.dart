import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/string_extensions.dart';

part 'rag_settings_view_model.g.dart';

/// The user-editable set of tag names (lowercase) that mark a note for RAG
/// indexing (Phase 12 Stage 2). Edited from Settings, persisted in
/// SharedPreferences. Defaults to [AppConstants.ragIndexTags].
///
/// Read by the note editor's save-close hook (`_scheduleRagSync`) to decide
/// whether a note is indexed or deindexed. `keepAlive` so the current set is
/// always available synchronously to that hook.
@Riverpod(keepAlive: true)
class RagIndexTags extends _$RagIndexTags {
  static const _key = AppConstants.prefRagIndexTags;

  @override
  Set<String> build() {
    _load();
    return AppConstants.ragIndexTags;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null) state = saved.toSet();
  }

  /// Adds a normalised (lowercase, trimmed) tag to the trigger set.
  Future<void> addTag(String name) async {
    final tag = name.normalised;
    if (tag.isEmpty || state.contains(tag)) return;
    state = {...state, tag};
    await _persist();
  }

  /// Removes a tag from the trigger set.
  Future<void> removeTag(String tag) async {
    if (!state.contains(tag)) return;
    state = {...state}..remove(tag);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }
}
