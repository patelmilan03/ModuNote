import 'package:flutter/material.dart';

/// All design tokens — "Tangerine Pop" palette (UI revamp, 2026-11).
/// Warm paper + ink + coral, with five pastel note tints chosen by category.
/// Token NAMES are unchanged from the original violet palette so every
/// widget restyles through the theme; only the values moved.
/// Spec: ModuNote UI Revamp design doc (palette section).
abstract class AppColors {
  // ─── Light surfaces ───────────────────────────────────────────
  static const Color lightBg                   = Color(0xFFFBF6EC); // paper
  static const Color lightCard                 = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer     = Color(0xFFF1EADD);
  static const Color lightSurfaceContainerHigh = Color(0xFFE9E1D1);

  // ─── Light brand (ink) ────────────────────────────────────────
  static const Color lightPrimary            = Color(0xFF211B2E); // ink
  static const Color lightPrimaryContainer   = Color(0xFFEDE4D3);
  static const Color lightOnPrimaryContainer = Color(0xFF211B2E);

  // ─── Light text ───────────────────────────────────────────────
  static const Color lightOnSurface        = Color(0xFF211B2E);
  static const Color lightOnSurfaceVariant = Color(0xFF4A4358);
  static const Color lightOnSurfaceMuted   = Color(0xFF6B6478);

  // ─── Light lines ──────────────────────────────────────────────
  static const Color lightOutline       = Color(0x14211B2E); // ink 8%
  static const Color lightOutlineStrong = Color(0x29211B2E); // ink 16%

  // ─── Light misc ───────────────────────────────────────────────
  static const Color lightPinTint   = Color(0xFFFFFFFF); // pinned tint retired
  static const Color lightRecordRed = Color(0xFFE5484D);
  static const Color lightChipBg   = Color(0xFFEFE8DC);
  static const Color lightChipText = Color(0xFF211B2E);
  static const Color lightAccent   = Color(0xFFFF5C3A); // coral

  // ─── Dark surfaces ────────────────────────────────────────────
  static const Color darkBg                   = Color(0xFF16131F); // night
  static const Color darkCard                 = Color(0xFF221E2F);
  static const Color darkSurfaceContainer     = Color(0xFF2B2639);
  static const Color darkSurfaceContainerHigh = Color(0xFF352F45);

  // ─── Dark brand (cream takes the ink role) ────────────────────
  static const Color darkPrimary            = Color(0xFFF4EEE2); // cream
  static const Color darkPrimaryContainer   = Color(0xFF2B2639);
  static const Color darkOnPrimaryContainer = Color(0xFFF4EEE2);

  // ─── Dark text ────────────────────────────────────────────────
  static const Color darkOnSurface        = Color(0xFFF4EEE2);
  static const Color darkOnSurfaceVariant = Color(0xFFCFC8DD);
  static const Color darkOnSurfaceMuted   = Color(0xFFA39CB0);

  // ─── Dark lines ───────────────────────────────────────────────
  static const Color darkOutline       = Color(0x1AF4EEE2); // cream 10%
  static const Color darkOutlineStrong = Color(0x33F4EEE2); // cream 20%

  // ─── Dark misc ────────────────────────────────────────────────
  static const Color darkPinTint   = Color(0xFF221E2F); // pinned tint retired
  static const Color darkRecordRed = Color(0xFFFF6369);
  static const Color darkChipBg   = Color(0xFF2B2639);
  static const Color darkChipText = Color(0xFFF4EEE2);
  static const Color darkAccent   = Color(0xFFFF7A5C); // coral, lifted

  // ─── Shared ───────────────────────────────────────────────────
  /// Light coral. Prefer [accentOf] where the theme is known.
  static const Color accent     = lightAccent;
  /// Text / icons on coral — ink in BOTH themes (contrast > 4.5:1).
  static const Color accentOn   = Color(0xFF211B2E);
  static const Color ink        = Color(0xFF211B2E);
  static const Color cream      = Color(0xFFF4EEE2);
  static const Color savedGreen = Color(0xFF1F9D55);
  static const Color darkSavedGreen = Color(0xFF4ADE80);

  /// Dock (floating nav) background per theme.
  static const Color lightDock = ink;
  static const Color darkDock  = darkSurfaceContainer;

  // ─── Note tints (peach, mint, lilac, butter, sky) ─────────────
  static const List<Color> lightTints = [
    Color(0xFFFFD9C7),
    Color(0xFFCDEFD9),
    Color(0xFFDCD3FF),
    Color(0xFFFFE9A8),
    Color(0xFFCFE6FF),
  ];
  static const List<Color> darkTints = [
    Color(0xFF4A2B22),
    Color(0xFF1F3B2F),
    Color(0xFF33294F),
    Color(0xFF4A3E16),
    Color(0xFF1D3550),
  ];

  /// Saturated companion of each tint — search stripes, and the accent
  /// (pin icon, editor headings) drawn ON a dark tint.
  static const List<Color> tintStripes = [
    Color(0xFFFF9A78),
    Color(0xFF4FBF85),
    Color(0xFF8C7CF0),
    Color(0xFFE7C24A),
    Color(0xFF5BA4E6),
  ];

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Coral for the current theme.
  static Color accentOf(BuildContext context) =>
      _isDark(context) ? darkAccent : lightAccent;

  /// Muted text colour for the current theme.
  static Color mutedOf(BuildContext context) =>
      _isDark(context) ? darkOnSurfaceMuted : lightOnSurfaceMuted;

  /// Card background for the current theme.
  static Color cardOf(BuildContext context) =>
      _isDark(context) ? darkCard : lightCard;

  /// Dock background for the current theme.
  static Color dockOf(BuildContext context) =>
      _isDark(context) ? darkDock : lightDock;

  /// Stable tint index (0..4) for a tag, derived from its lowercase name so a
  /// tag keeps one colour on the Tags tab, note cards and the editor — across
  /// launches and devices. (FNV-1a; `String.hashCode` isn't stable.)
  static int tagTintIndex(String tagName) {
    var h = 0x811c9dc5;
    for (final u in tagName.toLowerCase().codeUnits) {
      h = ((h ^ u) * 0x01000193) & 0xFFFFFFFF;
    }
    return h % lightTints.length;
  }

  /// Fill for a tag chip/bubble: the tag's tint in the current theme.
  static Color tagTintOf(BuildContext context, String tagName) =>
      tintOf(context, tagTintIndex(tagName));

  /// Outline for a tag chip so it stays visible on a card of the same tint.
  static Color tagStripeOf(String tagName) =>
      tintStripes[tagTintIndex(tagName)].withValues(alpha: 0.7);

  /// Tint for tint index [i] (wraps) in the current theme.
  static Color tintOf(BuildContext context, int i) =>
      (_isDark(context) ? darkTints : lightTints)[i % lightTints.length];
}
