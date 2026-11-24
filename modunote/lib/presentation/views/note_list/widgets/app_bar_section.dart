import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/auth/firebase_auth_service.dart';
import '../../../router/app_router.dart';

/// Home app bar: date label + "Your notes" + profile avatar (UI revamp).
/// The avatar opens Settings, which is no longer a dock tab.
class AppBarSection extends StatelessWidget {
  const AppBarSection({super.key});

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final now = DateTime.now();
    final today =
        '${_days[now.weekday - 1]} ${now.day} ${_months[now.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  today.toUpperCase(),
                  style: AppTypography.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your notes',
                  style: AppTypography.heading(
                    fontSize: 34,
                    letterSpacing: -0.6,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Tappable account avatar — opens Settings.
          ProfileAvatar(
            heroTag: ProfileAvatar.settingsHeroTag,
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

/// Circular account avatar. Shows the signed-in Google account's profile
/// photo; falls back to initials (from display name / email) on coral, or a
/// person icon for an anonymous session. [onTap] runs on tap (Home → Settings;
/// the Settings account card → [showAccountSheet]).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.onTap, this.size = 44, this.heroTag});

  /// Shared by the Home avatar and the Settings account card so the avatar
  /// flies between them.
  static const String settingsHeroTag = 'profile-avatar';

  final VoidCallback? onTap;
  final double size;

  /// When set, the avatar is wrapped in a [Hero] with this tag.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    // Firebase may be uninitialised (e.g. the web portfolio build has no web
    // config). Touching FirebaseAuth.instance then throws and crashes the whole
    // home screen — so render a static, non-interactive avatar instead.
    if (Firebase.apps.isEmpty) return _tappable(_buildAvatar(context, null));

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder:
          (context, snapshot) =>
              _tappable(_buildAvatar(context, snapshot.data)),
    );
  }

  Widget _tappable(Widget avatar) {
    final child = heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar);
    return onTap == null
        ? child
        : Semantics(
          button: true,
          label: 'Account and settings',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: child,
          ),
        );
  }

  Widget _buildAvatar(BuildContext context, User? user) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentOf(context),
      ),
      child: _initialsLabel(user),
    );

    final photo = user?.photoURL;
    if (photo == null || photo.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _initialsLabel(User? user) {
    final initials = _initials(user);
    if (initials == null) {
      return Icon(Icons.person, color: AppColors.accentOn, size: size * 0.5);
    }
    return Text(
      initials,
      style: AppTypography.heading(
        fontSize: size * 0.32,
        fontWeight: FontWeight.w800,
        color: AppColors.accentOn,
      ),
    );
  }

  /// Two letters from the display name, else the first letter of the email,
  /// else null (anonymous → person icon).
  String? _initials(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      final first = parts.first[0];
      final last = parts.length > 1 ? parts.last[0] : '';
      return (first + last).toUpperCase();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return null;
  }
}

/// Account sheet (moved from the Home avatar to the Settings account card in
/// the UI revamp): shows who is signed in, with a Sign-out action that
/// returns the user to the login screen (the router redirects once Firebase
/// auth state clears). No-op when Firebase is unavailable (web demo).
void showAccountSheet(BuildContext context) {
  if (Firebase.apps.isEmpty) return;
  final User? user = FirebaseAuth.instance.currentUser;
  {
    final isAnon = user?.isAnonymous ?? true;
    final name = user?.displayName?.trim();
    final email = user?.email;
    final title =
        (name != null && name.isNotEmpty)
            ? name
            : (isAnon ? 'Guest' : (email ?? 'Signed in'));
    final subtitle =
        isAnon ? 'Not signed in — sign in to sync & back up' : (email ?? '');

    showModalBottomSheet<void>(
      context: context,
      // Render above the floating bottom nav (root navigator, like the other
      // editor/settings sheets).
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const ProfileAvatar(),
                title: Text(
                  title,
                  style: AppTypography.heading(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                subtitle:
                    subtitle.isEmpty
                        ? null
                        : Text(
                          subtitle,
                          style: AppTypography.inter(fontSize: 12.5),
                        ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: cs.error),
                title: Text(
                  isAnon ? 'Sign in with a different account' : 'Sign out',
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.error,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  // Clears Firebase auth → the router's refreshListenable fires
                  // and redirects to the login screen.
                  await FirebaseAuthService().signOut();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
