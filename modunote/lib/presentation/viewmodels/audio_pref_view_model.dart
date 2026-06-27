import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'audio_pref_view_model.g.dart';

/// Whether to show the confirmation dialog before deleting a voice recording.
///
/// Persisted in SharedPreferences. Default `true` (ask). The "Don't ask again"
/// checkbox sets it to `false`; the Settings toggle re-enables it.
@Riverpod(keepAlive: true)
class AudioDeleteConfirm extends _$AudioDeleteConfirm {
  static const _key = 'ask_before_delete_audio';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_key);
    if (v != null && v != state) state = v;
  }

  Future<void> setAsk(bool ask) async {
    state = ask;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, ask);
  }
}
