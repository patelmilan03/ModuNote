import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  // Required before any async platform channel calls (Drift, flutter_sound).
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: ModuNoteApp(),
    ),
  );
}
