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
}

class AppRadius {
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double max = 999;
  
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
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppGradients {
  static LinearGradient get main => const LinearGradient(
        colors: [Color(0xFFA3E635), Color(0xFF84CC16)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkSurface => LinearGradient(
        colors: [Colors.black, Colors.black.withValues(alpha: 0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

