import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../services/sync/cloud_sync_service.dart';
import '../views/auth/login_screen.dart';
import '../views/note_list/note_list_screen.dart';
import '../views/note_editor/note_editor_screen.dart';
import '../views/qna/qna_screen.dart';
import '../views/search/search_screen.dart';
import '../views/tags/tags_screen.dart';
import '../views/archive/archived_notes_screen.dart';
import '../views/settings/settings_screen.dart';
import '../widgets/mn_bottom_nav.dart';
import '../widgets/mn_capture_button.dart';

export '../widgets/mn_capture_button.dart' show CaptureKind;

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
  static const String login = '/login';

  /// Builds the edit-note path for a specific [id].
  static String editNotePath(String id) => '/note/$id';

  /// New-note path that asks the editor to start as [kind]
  /// (voice → recording starts, checklist → first line is a checklist item).
  static String newNoteAs(CaptureKind kind) =>
      kind == CaptureKind.text ? newNote : '$newNote?start=${kind.name}';
}

/// GoRouter instance provided to [MaterialApp.router].
/// A [ShellRoute] wraps the 4 dock tabs (Notes, Ask, Search, Tags)
/// so [MNBottomNav] persists across tab switches. Settings is pushed.
/// Note Editor routes are outside the shell (full-screen pushes).
@riverpod
GoRouter router(Ref ref) {
  // Rebuild routing decisions whenever auth state flips (sign-in / sign-out).
  Listenable refresh;
  try {
    final stream = GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges());
    ref.onDispose(stream.dispose);
    refresh = stream;
  } catch (_) {
    refresh = ValueNotifier<int>(0); // Firebase unavailable — no auth changes.
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Web portfolio demo: never gate — visitors go straight to the app with
      // no login wall (the web build is a public showcase; sync stays off and
      // AI runs against the read-only demo dataset).
      if (kIsWeb) return null;
      // If Firebase never initialised (bad/missing config), do NOT gate — run
      // local-only so the user can still reach their on-device notes instead of
      // being trapped on a login screen that can't work.
      if (Firebase.apps.isEmpty) return null;

      bool signedIn;
      try {
        signedIn = FirebaseAuth.instance.currentUser != null;
      } catch (_) {
        signedIn = false; // Firebase not ready → treat as logged out.
      }
      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!signedIn) return loggingIn ? null : AppRoutes.login;
      if (loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
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
            path: AppRoutes.qna,
            builder: (context, state) => const QnaScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.tags,
            builder: (context, state) => const TagsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newNote,
        builder: (context, state) => NoteEditorScreen(
          startMode: CaptureKind.values.asNameMap()[
                  state.uri.queryParameters['start']] ??
              CaptureKind.text,
        ),
      ),
      // Settings is pushed from the Home avatar (UI revamp — no longer a tab).
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const Scaffold(
          body: SafeArea(child: SettingsScreen()),
        ),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}

/// Bridges a [Stream] (Firebase auth state) to a [Listenable] so GoRouter can
/// re-run its [GoRouter.redirect] whenever the user signs in or out.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
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
      // Full best-effort cloud backup (notes + tags + categories) on background.
      ref.read(cloudSyncServiceProvider).backupToCloud().ignore();
    }
  }

  static int _tabIndex(String loc) {
    if (loc.startsWith(AppRoutes.qna)) return 1;
    if (loc.startsWith(AppRoutes.search)) return 2;
    if (loc.startsWith(AppRoutes.tags)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Hide the dock while the keyboard is up (Ask input, search field).
    final keyboardUp = media.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BottomBar(
        showIcon: true,
        layout: BottomBarLayout(
          width: media.size.width - 32,
          respectSafeArea: true,
          clip: Clip.none,
        ),
        theme: BottomBarThemeData(
          barDecoration: const BoxDecoration(color: Colors.transparent),
          iconDecoration: BoxDecoration(
            color: AppColors.accentOf(context),
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
        child: AnimatedSlide(
          offset: keyboardUp ? const Offset(0, 2) : Offset.zero,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              Expanded(
                child: MNBottomNav(activeIndex: _tabIndex(widget.location)),
              ),
              const SizedBox(width: 10),
              MNCaptureButton(
                onCapture: (kind) => context.push(AppRoutes.newNoteAs(kind)),
              ),
            ],
          ),
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
