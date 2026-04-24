import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Global Tech Conference app.
/// Deep-space dark with electric-cyan primary and violet accent.
class AppTheme {
  AppTheme._();

  // ── Colour Palette ────────────────────────────────────────────────────────
  static const Color kBackground   = Color(0xFF0A0E27);
  static const Color kSurface      = Color(0xFF131830);
  static const Color kCard         = Color(0xFF1C2240);
  static const Color kCardBorder   = Color(0xFF2A3158);

  static const Color kPrimary      = Color(0xFF00D4FF); // electric cyan
  static const Color kPrimaryDark  = Color(0xFF0099BB);
  static const Color kAccent       = Color(0xFF7C3AED); // violet
  static const Color kAccentLight  = Color(0xFFA855F7);

  static const Color kSuccess      = Color(0xFF10B981); // emerald
  static const Color kWarning      = Color(0xFFF59E0B); // amber
  static const Color kError        = Color(0xFFEF4444); // red
  static const Color kPending      = Color(0xFF6B7280); // slate

  static const Color kTextPrimary  = Color(0xFFE2E8F0);
  static const Color kTextSecondary= Color(0xFF94A3B8);
  static const Color kTextMuted    = Color(0xFF475569);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient kHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E27), Color(0xFF1a1040)],
  );

  static const LinearGradient kPrimaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0099BB)],
  );

  static const LinearGradient kAccentGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  );

  static const LinearGradient kSuccessGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  // ── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: kBackground,
      colorScheme: const ColorScheme.dark(
        primary: kPrimary,
        secondary: kAccent,
        surface: kSurface,
        error: kError,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32, fontWeight: FontWeight.w700, color: kTextPrimary,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26, fontWeight: FontWeight.w700, color: kTextPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w600, color: kTextPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600, color: kTextPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w500, color: kTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, color: kTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, color: kTextSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: kBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600, color: kTextPrimary,
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: kCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kCardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCard,
        hintStyle: GoogleFonts.inter(color: kTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: kBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: kCard,
        contentTextStyle: TextStyle(color: kTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
