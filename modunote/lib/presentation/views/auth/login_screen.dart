import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../services/auth/firebase_auth_service.dart';
import '../../../services/sync/cloud_sync_service.dart';

/// Auth gate. Shown by the router whenever no user is signed in.
///
/// Signing in with Google gives a stable uid; on success we kick off a cloud
/// restore (notes/tags/categories) in the background and let the router redirect
/// to the home shell — the home list updates reactively as data lands.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);

    final auth = FirebaseAuthService();
    // Capture the keepAlive service now so it's safe to use after this screen
    // is disposed by the auth-driven redirect.
    final sync = ref.read(cloudSyncServiceProvider);

    try {
      final user = await auth.signInWithGoogle();
      if (user == null) {
        // Cancelled the Google picker.
        if (mounted) setState(() => _busy = false);
        return;
      }
      // Restore in the background; the router redirect takes us to home, which
      // updates reactively as the restored notes are written to Drift.
      sync.restoreFromCloud().then((count) {
        if (count > 0) {
          showSuccessToast('Welcome back — restored $count notes.');
        }
      }).catchError((Object _) {
        showErrorToast("Signed in, but couldn't restore from the cloud.");
      });
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      showErrorToast('Google sign-in failed. Please try again.');
    }
  }

  /// Escape hatch so a Firebase/Google config problem can never lock the user
  /// out of their local notes. Signs in anonymously (no cloud restore) and lets
  /// the router redirect to home. They can sign in with Google later to sync.
  Future<void> _continueWithoutAccount() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await FirebaseAuthService().signInAnonymously();
      // authStateChanges fires → router redirect takes us home.
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      showErrorToast("Couldn't continue offline. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final onSurface = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final variant = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Brand mark.
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'ModuNote',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture ideas the moment they strike — and never lose them again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.4,
                  color: variant,
                ),
              ),
              const Spacer(flex: 4),
              _GoogleButton(busy: _busy, onTap: _signIn, isDark: isDark),
              const SizedBox(height: 16),
              Text(
                'Sign in to sync your notes, tags, and folders across devices.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: variant),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy ? null : _continueWithoutAccount,
                child: Text(
                  'Continue without an account',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: variant,
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.busy,
    required this.onTap,
    required this.isDark,
  });

  final bool busy;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFF5B4EFF),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Simple Google-coloured "G" mark (no asset dependency).
                  Text(
                    'G',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
