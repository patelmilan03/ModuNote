import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'remote_note_service.dart';

part 'remote_note_service_provider.g.dart';

/// Provides the [RemoteNoteService] used for Phase 12 AI calls.
///
/// Default base URL targets the Android emulator loopback (`10.0.2.2`).
/// Override the base URL at build time for physical devices / production
/// (Stage 4 — via `--dart-define`).
@Riverpod(keepAlive: true)
RemoteNoteService remoteNoteService(Ref ref) => RemoteNoteService();
