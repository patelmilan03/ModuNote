import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — best-effort. Sign-in is now interactive (Google) and gated
  // by the router's login screen, so we no longer sign in silently here. If
  // init fails the app still boots; the login screen surfaces sign-in errors.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('main: Firebase init failed. $e');
  }

  runApp(
    const ProviderScope(
      child: ModuNoteApp(),
    ),
  );
}
