import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_colors.dart';

/// Root navigator key — lets background operations (RAG note sync, bulk
/// re-index) show app-wide toasts without a screen [BuildContext]. Passed to
/// GoRouter (`navigatorKey`) and used by the show* helpers below. The app is
/// wrapped in a `ToastificationWrapper` (see app.dart) so toasts render in a
/// global overlay above whatever screen is currently visible.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void showSuccessToast(String message) =>
    _show(message, ToastificationType.success);

void showErrorToast(String message) =>
    _show(message, ToastificationType.error);

void showInfoToast(String message) => _show(message, ToastificationType.info);

void _show(String message, ToastificationType type) {
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
    primaryColor: primary,
    title: Text(message),
  );
}
