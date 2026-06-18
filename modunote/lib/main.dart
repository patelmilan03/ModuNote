import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init + anonymous auth — best-effort. If this fails (e.g., before
  // flutterfire configure is run), the app boots normally with sync disabled.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuthService().signInAnonymously();
  } catch (e) {
    debugPrint('main: Firebase unavailable — sync disabled. $e');
  }

  runApp(
    const ProviderScope(
      child: ModuNoteApp(),
    ),
  );
}
