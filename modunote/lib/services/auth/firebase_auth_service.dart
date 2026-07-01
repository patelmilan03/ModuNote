import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication with Google Sign-In.
///
/// The app is auth-gated: the router redirects to the login screen until a user
/// is signed in. A Google account gives a STABLE uid that survives reinstalls —
/// so cloud sync + restore (see CloudSyncService) make data durable, unlike the
/// old silent-anonymous approach where every reinstall produced a new uid and
/// orphaned the previous data.
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._();
  FirebaseAuthService._();
  factory FirebaseAuthService() => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Emits on every sign-in / sign-out — used by the router's refreshListenable.
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  User? get currentUser => FirebaseAuth.instance.currentUser;
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
  bool get isSignedIn => currentUser != null;

  /// Interactive Google sign-in. Returns the signed-in [User], or null if the
  /// user cancelled. Throws [FirebaseAuthException] / [Exception] on real
  /// failures so the caller can surface a message.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled the picker
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    return result.user;
  }

  /// Escape hatch: signs in anonymously so the user can reach their LOCAL notes
  /// even if Google isn't configured yet / sign-in fails. No cloud restore runs
  /// for an anonymous session (its uid isn't stable across reinstalls). Returns
  /// the uid, or null on failure. Idempotent.
  Future<String?> signInAnonymously() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser!.uid;
    final credential = await auth.signInAnonymously();
    return credential.user?.uid;
  }

  /// Signs out of both Google and Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('FirebaseAuthService: google signOut failed: $e');
    }
    await FirebaseAuth.instance.signOut();
  }
}
