import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/local/database_providers.dart';
import '../views/note_list/note_list_screen.dart';
import '../views/note_editor/note_editor_screen.dart';
import '../views/qna/qna_screen.dart';
import '../views/search/search_screen.dart';
import '../views/tags/tags_screen.dart';
import '../views/archive/archived_notes_screen.dart';
import '../views/settings/settings_screen.dart';
import '../widgets/mn_bottom_nav.dart';

part 'app_router.g.dart';

/// Route path constants — single source of truth.
abstract class AppRoutes {
  static const String home = '/';
  static const String newNote = '/note/new';
  static const String editNote = '/note/:id';
  static const String search = '/search';
  static const String tags = '/tags';
  static const String settings = '/settings';
  static const String archive = '/archive';
  static const String qna = '/qna';

  /// Builds the edit-note path for a specific [id].
  static String editNotePath(String id) => '/note/$id';
}

/// GoRouter instance provided to [MaterialApp.router].
/// A [ShellRoute] wraps the 4 main tabs (Home, Explore, Tags, Settings)
/// so [MNBottomNav] persists across tab switches.
/// Note Editor routes are outside the shell (full-screen pushes).
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const NoteListScreen(),
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
        path: AppRoutes.archive,
        builder: (context, state) => const ArchivedNotesScreen(),
      ),
      GoRoute(
        path: AppRoutes.qna,
        builder: (context, state) => const QnaScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}

/// Shell scaffold shared by the 4 tab routes.
/// Provides the outer [Scaffold], [SafeArea], and persistent [MNBottomNav].
/// Listens to [AppLifecycleState.paused] to trigger best-effort Firebase sync.
/// Tab screens return their body content only — no inner Scaffold or SafeArea.
class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(syncedNoteRepositoryProvider).syncAllPending().ignore();
    }
  }

  static int _tabIndex(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/tags')) return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BottomBar(
        showIcon: true,
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          respectSafeArea: true,
          clip: Clip.none,
        ),
        theme: const BottomBarThemeData(
          barDecoration: BoxDecoration(color: Colors.transparent),
          iconDecoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          iconWidth: 52,
          iconHeight: 52,
        ),
        icon: (w, h) => Icon(
          Icons.keyboard_arrow_up_rounded,
          color: AppColors.accentOn,
          size: w * 1.4,
        ),
        scrollBehavior: const BottomBarScrollBehavior(
          hideOnScroll: true,
          deltaThreshold: 8,
        ),
        motion: const BottomBarMotion.curved(
          duration: Duration(milliseconds: 240),
          curve: Curves.easeInOut,
        ),
        body: SafeArea(child: widget.child),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            MNBottomNav(activeIndex: _tabIndex(widget.location)),
            Positioned(
              top: -20,
              child: _NavFab(onTap: () => context.push(AppRoutes.newNote)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accent-coloured circular FAB used in the nav bar notch.
/// Navigates to the new-note editor when tapped.
class _NavFab extends StatelessWidget {
  const _NavFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.accentOn,
          size: 26,
        ),
      ),
    );
  }
}

/// Controls light / dark / system theme mode.
/// Reads persisted value from SharedPreferences on build;
/// writes on every set call. Key: [AppConstants.prefThemeMode].
/// Defaults to [ThemeMode.system] for the first frame until async read resolves.
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    _loadPersistedMode();
    return ThemeMode.system;
  }

  Future<void> _loadPersistedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefThemeMode);
    if (saved != null) state = _fromString(saved);
  }

  void setLight() => _setAndPersist(ThemeMode.light);
  void setDark() => _setAndPersist(ThemeMode.dark);
  void setSystem() => _setAndPersist(ThemeMode.system);

  void toggle() {
    _setAndPersist(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _setAndPersist(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, _toString(mode));
  }

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _fromString(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
