import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Semantic spacing
  static const double screenPadding = 24;
  static const double fieldPadding = 16;
  static const double cardPadding = 16;
  static const double sectionGap = 32;
  static const double bottomBuffer = 120; // For floating nav
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration bounce = Duration(milliseconds: 600);
}

class AppRadius {
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double max = 999;

  static BorderRadius get roundXS => BorderRadius.circular(xs);
  static BorderRadius get roundS => BorderRadius.circular(s);
  static BorderRadius get roundM => BorderRadius.circular(m);
  static BorderRadius get roundL => BorderRadius.circular(l);
  static BorderRadius get roundXL => BorderRadius.circular(xl);
  static BorderRadius get circle => BorderRadius.circular(max);
}

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
      );
  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      );
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );
  // ⬇️ Previously undefined — now properly defined
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );
}

class AppShadows {
  /// Soft lift shadow — for cards in light mode
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Very subtle shadow — for dark mode cards
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -4,
        ),
      ];

  /// Elevated card — modal-level depth
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  /// Colored glow — for accented CTAs
  static List<BoxShadow> glow(Color color, {double intensity = 0.15}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.5),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Nav bar shadow — floating pill effect
  static List<BoxShadow> get navBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppGradients {
  /// Primary brand gradient — Cobalt Blue to Indigo
  static LinearGradient get main => const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Subtle blue tint for card backgrounds in light mode
  static LinearGradient get lightCard => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Midnight dark surface
  static LinearGradient get darkSurface => const LinearGradient(
        colors: [Color(0xFF161B27), Color(0xFF0D0F14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  /// Emerald green — for success / health states
  static LinearGradient get healthGreen => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Warm amber — for warning / refill states
  static LinearGradient get warningAmber => const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Red gradient — for danger / missed dose
  static LinearGradient get dangerRed => const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dark card gradient — premium night surface
  static LinearGradient get darkCard => const LinearGradient(
        colors: [Color(0xFF1E2436), Color(0xFF161B27)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
