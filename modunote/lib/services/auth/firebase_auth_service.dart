import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Handles silent anonymous Firebase Authentication.
/// The developer never sees a login screen — Firebase assigns a device UID
/// automatically. Firestore security rules use this UID to scope data.
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._();
  FirebaseAuthService._();
  factory FirebaseAuthService() => _instance;

  /// Signs in anonymously if no user is currently signed in.
  /// Idempotent — safe to call multiple times.
  /// Returns the UID on success, null on failure.
  Future<String?> signInAnonymously() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return auth.currentUser!.uid;
      final credential = await auth.signInAnonymously();
      return credential.user?.uid;
    } catch (e) {
      debugPrint('FirebaseAuthService: anonymous sign-in failed: $e');
      return null;
    }
  }

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}
