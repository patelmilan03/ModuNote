import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale using Bricolage Grotesque (headings) + Inter (body).
/// UI revamp 2026-11: headings moved from Plus Jakarta Sans to Bricolage
/// Grotesque. Sizes: ModuNote UI Revamp design doc (typography section).
abstract class AppTypography {
  /// Bricolage Grotesque — titles, card headings, sheet titles.
  static TextStyle heading({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w800,
    double? letterSpacing,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
      );

  /// Inter — used for body text, labels, metadata, chips.
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
        decoration: decoration,
        fontStyle: fontStyle,
      );

  /// Builds a Material TextTheme with our font choices pre-applied.
  static TextTheme buildTextTheme({Color? displayColor, Color? bodyColor}) {
    return GoogleFonts.bricolageGrotesqueTextTheme(
      TextTheme(
        // Display / headline → Bricolage Grotesque (handled by base)
        bodyLarge:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall:  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
