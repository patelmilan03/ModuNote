import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../note_list/widgets/app_bar_section.dart';

/// Account card at the top of Settings (UI revamp): avatar, who is signed in
/// and sync state. Tapping opens the account sheet with Sign out (moved here
/// from the Home avatar, which now opens Settings). Inverted colours: ink in
/// light mode, cream in dark mode.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      // Web portfolio demo — no Firebase, no account.
      return const _CardBody(
        title: 'Demo mode',
        subtitle: 'Not signed in · notes stay in this browser',
        onTap: null,
      );
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isAnon = user?.isAnonymous ?? true;
        final name = user?.displayName?.trim();
        final title = (name != null && name.isNotEmpty)
            ? name
            : (isAnon ? 'Guest' : (user?.email ?? 'Your account'));
        return _CardBody(
          title: title,
          subtitle: isAnon
              ? 'Not signed in · tap to sign in and sync'
              : 'Signed in · synced to cloud',
          onTap: () => showAccountSheet(context),
        );
      },
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const ProfileAvatar(size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading(
                        fontSize: 18,
                        color: cs.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.inter(
                        fontSize: 12.5,
                        color: cs.onPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: cs.onPrimary.withValues(alpha: 0.75)),
            ],
          ),
        ),
      ),
    );
  }
}
