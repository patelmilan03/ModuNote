import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../views/note_list/note_list_screen.dart';
import '../views/note_editor/note_editor_screen.dart';
import '../views/search/search_screen.dart';
import '../views/tags/tags_screen.dart';
import '../views/settings/settings_screen.dart';

part 'app_router.g.dart';

/// Route path constants — single source of truth.
abstract class AppRoutes {
  static const String home       = '/';
  static const String newNote    = '/note/new';
  static const String editNote   = '/note/:id';
  static const String search     = '/search';
  static const String tags       = '/tags';
  static const String settings   = '/settings';

  /// Builds the edit-note path for a specific [id].
  static String editNotePath(String id) => '/note/$id';
}

/// GoRouter instance provided to [MaterialApp.router].
/// Phase 9 will add shell routes for the persistent bottom nav bar.
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const NoteListScreen(),
      ),
      GoRoute(
        path: AppRoutes.newNote,
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.editNote,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoteEditorScreen(noteId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.tags,
        builder: (context, state) => const TagsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}

/// Controls light / dark / system theme mode.
/// Persisted via SharedPreferences in Phase 9.
/// Default: ThemeMode.system.
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void setLight()  => state = ThemeMode.light;
  void setDark()   => state = ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Convenience provider — exposes [ThemeMode] directly for [MaterialApp.router].
@riverpod
ThemeMode themeMode(Ref ref) {
  return ref.watch(themeModeNotifierProvider);
}
