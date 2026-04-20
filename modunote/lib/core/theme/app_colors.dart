import 'package:flutter/material.dart';

/// All design tokens from the ModuNote UI Reference Document.
/// Seed: #5B4EFF (indigo-violet). Accent: #F59E0B (warm amber).
abstract class AppColors {
  // ─── Light surfaces ───────────────────────────────────────────
  static const Color lightBg                   = Color(0xFFFEFBFF);
  static const Color lightCard                 = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer     = Color(0xFFF4F0FA);
  static const Color lightSurfaceContainerHigh = Color(0xFFEDE8F5);

  // ─── Light brand ──────────────────────────────────────────────
  static const Color lightPrimary            = Color(0xFF5B4EFF);
  static const Color lightPrimaryContainer   = Color(0xFFE4E0FF);
  static const Color lightOnPrimaryContainer = Color(0xFF1A0F8A);

  // ─── Light text ───────────────────────────────────────────────
  static const Color lightOnSurface        = Color(0xFF1C1B2E);
  static const Color lightOnSurfaceVariant = Color(0xFF4A4858);
  static const Color lightOnSurfaceMuted   = Color(0xFF6F6C7D);

  // ─── Light lines ──────────────────────────────────────────────
  static const Color lightOutline       = Color(0x1F1C1B2E);
  static const Color lightOutlineStrong = Color(0x381C1B2E);

  // ─── Light misc ───────────────────────────────────────────────
  static const Color lightPinTint   = Color(0xFFFFF4D6);
  static const Color lightRecordRed = Color(0xFFE5484D);
  static const Color lightChipBg   = Color(0xFFEEEBFF);
  static const Color lightChipText = Color(0xFF3F2FE0);

  // ─── Dark surfaces ────────────────────────────────────────────
  static const Color darkBg                   = Color(0xFF1C1B2E);
  static const Color darkCard                 = Color(0xFF232238);
  static const Color darkSurfaceContainer     = Color(0xFF2A2942);
  static const Color darkSurfaceContainerHigh = Color(0xFF33324E);

  // ─── Dark brand ───────────────────────────────────────────────
  static const Color darkPrimary            = Color(0xFFB7AFFF);
  static const Color darkPrimaryContainer   = Color(0xFF3D33C7);
  static const Color darkOnPrimaryContainer = Color(0xFFE4E0FF);

  // ─── Dark text ────────────────────────────────────────────────
  static const Color darkOnSurface        = Color(0xFFEDECF5);
  static const Color darkOnSurfaceVariant = Color(0xFFBDBAD0);
  static const Color darkOnSurfaceMuted   = Color(0xFF8A8799);

  // ─── Dark lines ───────────────────────────────────────────────
  static const Color darkOutline       = Color(0x1FEDECF5);
  static const Color darkOutlineStrong = Color(0x38EDECF5);

  // ─── Dark misc ────────────────────────────────────────────────
  static const Color darkPinTint   = Color(0xFF3A3320);
  static const Color darkRecordRed = Color(0xFFFF6369);
  static const Color darkChipBg   = Color(0xFF2F2A5E);
  static const Color darkChipText = Color(0xFFB7AFFF);

  // ─── Shared ───────────────────────────────────────────────────
  static const Color accent     = Color(0xFFF59E0B);
  static const Color accentOn   = Color(0xFF1C1B2E);
  static const Color savedGreen = Color(0xFF22C55E);
}
