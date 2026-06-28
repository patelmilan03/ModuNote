import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_colors.dart';

/// Root navigator key — lets background operations (RAG note sync, bulk
/// re-index) show app-wide toasts without a screen [BuildContext]. Passed to
/// GoRouter (`navigatorKey`) and used by the show* helpers below. The app is
/// wrapped in a `ToastificationWrapper` (see app.dart) so toasts render in a
/// global overlay above whatever screen is currently visible.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Throttle bookkeeping: last time a given dedupe key was shown.
final Map<String, DateTime> _lastShown = {};
const Duration _defaultCooldown = Duration(seconds: 3);

bool _throttled(String key, Duration cooldown) {
  final now = DateTime.now();
  final last = _lastShown[key];
  if (last != null && now.difference(last) < cooldown) return true;
  _lastShown[key] = now;
  return false;
}

/// [dedupeKey] defaults to the message; pass a stable key (e.g. a note id) to
/// rate-limit a family of messages. Within [cooldown] of the last matching
/// toast, the call is silently dropped.
void showSuccessToast(String message, {String? dedupeKey, Duration? cooldown}) =>
    _show(message, ToastificationType.success, dedupeKey, cooldown);

void showErrorToast(String message, {String? dedupeKey, Duration? cooldown}) =>
    _show(message, ToastificationType.error, dedupeKey, cooldown);

void showInfoToast(String message, {String? dedupeKey, Duration? cooldown}) =>
    _show(message, ToastificationType.info, dedupeKey, cooldown);

void _show(
  String message,
  ToastificationType type,
  String? dedupeKey,
  Duration? cooldown,
) {
  if (_throttled(dedupeKey ?? message, cooldown ?? _defaultCooldown)) return;

  final context = rootNavigatorKey.currentContext;
  if (context == null) return; // app not mounted / backgrounded — skip silently
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = switch (type) {
    ToastificationType.error =>
      isDark ? AppColors.darkRecordRed : AppColors.lightRecordRed,
    ToastificationType.success => AppColors.accent,
    _ => Theme.of(context).colorScheme.primary,
  };

  toastification.show(
    context: context,
    type: type,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.bottomCenter,
    autoCloseDuration: const Duration(seconds: 3),
    borderRadius: BorderRadius.circular(16),
    showProgressBar: false,
    dragToClose: true,
    primaryColor: primary,
    title: Text(message),
  );
}
