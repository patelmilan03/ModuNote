import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// Makes a native sqlite3 library available to `NativeDatabase` for the
/// in-memory Drift repository tests.
///
/// `flutter test` runs on the host Dart VM, so it needs a host sqlite3 library.
/// On Linux/macOS one is normally already installed (the probe in step 1 just
/// succeeds). On Windows there is no preinstalled library, so this downloads the
/// official `sqlite3.dll` **once** into a gitignored cache (`test/.cache/`) and
/// points sqlite3 at it.
///
/// Returns `true` if in-memory Drift tests can run. Callers should skip the
/// repo-layer tests (not fail the whole suite) when this returns `false` — e.g.
/// offline on Windows with no cached DLL. The other test layers (models,
/// view-models, RemoteNoteService) never touch sqlite3 and run regardless.
Future<bool> ensureSqlite3() async {
  if (_attempted) return _ready;
  _attempted = true;

  // 1. Already loadable? (system lib on Linux/macOS, or a prior override.)
  if (_probe()) {
    _ready = true;
    return true;
  }

  // 2. Windows: download + cache the official DLL once, then override.
  if (Platform.isWindows) {
    try {
      final dll = await _ensureWindowsDll();
      open.overrideForAll(() => DynamicLibrary.open(dll.path));
      _ready = _probe();
      return _ready;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  _ready = false;
  return false;
}

bool _attempted = false;
bool _ready = false;

/// Touching `sqlite3.version` forces the library to load; any failure means no
/// usable library is currently available.
bool _probe() {
  try {
    sqlite3.version;
    return true;
  } catch (_) {
    return false;
  }
}

/// Ensures `test/.cache/sqlite3.dll` exists, downloading + extracting the
/// official SQLite Windows binary if it is missing.
Future<File> _ensureWindowsDll() async {
  final cacheDir = Directory('test/.cache');
  final dll = File('${cacheDir.path}/sqlite3.dll');
  if (dll.existsSync()) return dll;
  cacheDir.createSync(recursive: true);

  // sqlite.org keeps old releases, so these pinned URLs are stable. The DLL
  // archive naming has changed over releases, so try a few candidates and use
  // the first that resolves.
  const candidates = [
    'https://www.sqlite.org/2024/sqlite-dll-win-x64-3460100.zip',
    'https://www.sqlite.org/2024/sqlite-dll-win-x64-3450300.zip',
    'https://www.sqlite.org/2023/sqlite-dll-win64-x64-3430200.zip',
  ];

  for (final url in candidates) {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) continue;
    final archive = ZipDecoder().decodeBytes(resp.bodyBytes);
    final entry = archive.files.firstWhere(
      (f) => f.isFile && f.name.toLowerCase().endsWith('sqlite3.dll'),
      orElse: () => throw StateError('sqlite3.dll not found in $url'),
    );
    dll.writeAsBytesSync(entry.content as List<int>);
    return dll;
  }

  throw StateError(
    'Could not download sqlite3.dll from any known URL. '
    'Place a sqlite3.dll in test/.cache/ manually to run the repo tests.',
  );
}
