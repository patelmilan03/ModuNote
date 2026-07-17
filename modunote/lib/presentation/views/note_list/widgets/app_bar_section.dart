import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/auth/firebase_auth_service.dart';

/// Home app bar: weekday label + "ModuNote" wordmark + profile avatar.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkOnSurfaceMuted : AppColors.lightOnSurfaceMuted;
    final today = _days[DateTime.now().weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ModuNote',
                  style: AppTypography.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Tappable account avatar — Google profile photo + sign-out sheet.
          const _ProfileAvatar(),
        ],
      ),
    );
  }
}

/// Circular account avatar in the app bar. Shows the signed-in Google account's
/// profile photo; falls back to initials (from display name / email) on the
/// brand gradient, or a person icon for an anonymous session. Tapping opens an
/// account sheet with a Sign-out action that returns the user to the login
/// screen (the router redirects once Firebase auth state clears).
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    // Firebase may be uninitialised (e.g. the web portfolio build has no web
    // config). Touching FirebaseAuth.instance then throws and crashes the whole
    // home screen — so render a static, non-interactive avatar instead.
    if (Firebase.apps.isEmpty) return _buildAvatar(context, null);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showAccountSheet(context, user),
          child: _buildAvatar(context, user),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, User? user) {
    final cs = Theme.of(context).colorScheme;
    final fallback = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, AppColors.accent],
        ),
      ),
      child: _initialsLabel(user),
    );

    final photo = user?.photoURL;
    if (photo == null || photo.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        photo,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _initialsLabel(User? user) {
    final initials = _initials(user);
    if (initials == null) {
      return const Icon(Icons.person, color: Colors.white, size: 22);
    }
    return Text(
      initials,
      style: AppTypography.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.white,
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

  void _showAccountSheet(BuildContext context, User? user) {
    final isAnon = user?.isAnonymous ?? true;
    final name = user?.displayName?.trim();
    final email = user?.email;
    final title = (name != null && name.isNotEmpty)
        ? name
        : (isAnon ? 'Guest' : (email ?? 'Signed in'));
    final subtitle = isAnon
        ? 'Not signed in — sign in to sync & back up'
        : (email ?? '');

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
                leading: SizedBox(
                  width: _size,
                  height: _size,
                  child: _buildAvatar(sheetContext, user),
                ),
                title: Text(
                  title,
                  style: AppTypography.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(subtitle, style: AppTypography.inter(fontSize: 12.5)),
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
