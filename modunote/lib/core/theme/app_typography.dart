import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale using Plus Jakarta Sans (headings) + Inter (body).
/// Sizes and weights sourced from MODUNOTE_UI_REFERENCE.md § 1.3
abstract class AppTypography {
  /// Plus Jakarta Sans — used for all titles, card headings, section labels.
  static TextStyle plusJakartaSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
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
    return GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        // Display / headline → Plus Jakarta Sans (handled by base)
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
