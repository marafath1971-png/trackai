import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double zero = 0;
  static const double p4 = 4;
  static const double p8 = 8;
  static const double p12 = 12;
  static const double p16 = 16;
  static const double p20 = 20;
  static const double p24 = 24;
  static const double p32 = 32;
  static const double p40 = 40;
  static const double p48 = 48;
  static const double p64 = 64;
  static const double p80 = 80;

  // Legacy compatibility / Aliases
  static const double xxs = p4;
  static const double xs = p4;
  static const double s = p8;
  static const double m = p16;
  static const double l = p24;
  static const double xl = p32;
  static const double xxl = p48;
  static const double xxxl = p64;

  // Semantic spacing
  static const double screenPadding = p24;
  static const double fieldPadding = p16;
  static const double cardPadding = p16;
  static const double sectionGap = p32;
  static const double bottomBuffer = 120; // For floating nav
  static const double cardGap = p12; // Card-to-card gap in bento grids
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
  static const double m = 18;
  static const double l = 28;
  static const double xl = 44;
  static const double squircle = 32;
  static const double max = 999;

  static BorderRadius get roundXS => BorderRadius.circular(xs);
  static BorderRadius get roundS => BorderRadius.circular(s);
  static BorderRadius get roundM => BorderRadius.circular(m);
  static BorderRadius get roundL => BorderRadius.circular(l);
  static BorderRadius get roundXL => BorderRadius.circular(xl);
  static BorderRadius get roundSquircle => BorderRadius.circular(squircle);
  static BorderRadius get circle => BorderRadius.circular(max);
}

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        letterSpacing: -3.5,
        height: 1.0,
      );
  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        height: 1.1,
      );
  static TextStyle get displaySmall => GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.2,
      );
  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      );
  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );
  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );
  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      );
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
      );
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      );
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );
}

class AppShadows {
  /// Hyper-soft, multi-layered depth for futuristic 'iOS 26' glass cards
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 40,
          offset: const Offset(0, 20),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.01),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  /// Atmospheric 'Glass' shadow with higher spread and lower opacity
  static List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.4),
          blurRadius: 1,
          offset: const Offset(0, -1),
          spreadRadius: 0,
        ),
      ];

  /// Subtle inner-glow shadow for high-fidelity dark mode
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.04),
          blurRadius: 1,
          offset: const Offset(0, 0.5),
          spreadRadius: 0.5,
        ),
      ];

  /// Deep floating elevation for modals and popups
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 80,
          offset: const Offset(0, 40),
          spreadRadius: -20,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Atmospheric colored glow for primary actions
  static List<BoxShadow> glow(Color color, {double intensity = 0.25}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Nav bar shadow — floating pill effect with occlusion
  static List<BoxShadow> get navBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 40,
          offset: const Offset(0, 20),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppGradients {
  /// Primary brand gradient — Industrial Black to Dark Grey
  static LinearGradient get main => const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF262626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Subtle neutral tint for card backgrounds in light mode
  static LinearGradient get lightCard => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Midnight dark surface
  static LinearGradient get darkSurface => const LinearGradient(
        colors: [Color(0xFF171717), Color(0xFF000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  /// Emerald green — Neutrally adjusted for high contrast
  static LinearGradient get healthGreen => const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Warm amber — Neutrally adjusted for high contrast
  static LinearGradient get warningAmber => const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFB45309)],
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
        colors: [Color(0xFF111111), Color(0xFF000000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
