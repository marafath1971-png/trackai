import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

// ══════════════════════════════════════════════
// PROFESSIONAL COLOR SYSTEM
// ══════════════════════════════════════════════

class AppColors {
  // ── Brand ─────────────────────────────────────────────
  // Cal AI Premium Industrial Black
  static const Color primaryBlue = Color(0xFF000000);
  static const Color primaryBlueDark = Color(0xFF000000);
  static const Color primaryBlueLight = Color(0xFF1A1A1A);

  // ── Monochrome Base ────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color meshBg = Color(0xFFF9F9F9); // User-updated near-white background

  // Light mode surfaces (clean white)
  static const Color grey50 = Color(0xFFFFFFFF);  // Pure white background
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey300 = Color(0xFFD4D4D4);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey600 = Color(0xFF525252);

  // Dark mode surfaces (pure neutrals)
  static const Color grey700 = Color(0xFF404040);
  static const Color grey800 = Color(0xFF262626);
  static const Color grey900 = Color(0xFF171717);
  static const Color grey950 = Color(0xFF000000); // Pure Black

  // ── Semantics ──────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);  // Emerald
  static const Color warning = Color(0xFFF59E0B);  // Warm amber
  static const Color info = Color(0xFF4B5563); // Charcoal Grey for info

  // ── Compatibility Aliases ─────────────────────────────
  static const Color lRed = error;
  static const Color dRed = error;
  static const Color oBg = grey950;
  static const Color oText = white;
  static const Color oBorder = grey800;
  static const Color oFill = grey900;
  static const Color oLime = primaryBlue;     // Legacy alias
  static const Color oLimeDark = primaryBlueDark; // Legacy alias
}

class AppTheme {
  static ThemeData light({String? accentHex}) {
    final accent = accentHex != null ? hexToColor(accentHex) : AppColors.primaryBlue;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.grey50,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.white,
        secondary: accent,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.black,
        error: AppColors.error,
        outline: AppColors.grey200,
        surfaceContainer: AppColors.grey100,
      ),
      textTheme: _buildTextTheme(AppColors.black),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey500),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundM,
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundM,
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundM,
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.fieldPadding),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.black),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
        side: BorderSide.none,
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          ColorScheme.light(primary: AppColors.primaryBlue, secondary: accent),
          Brightness.light,
        ),
      ],
    );
  }

  static ThemeData dark({String? accentHex, bool isAmoled = false}) {
    final accent = accentHex != null ? hexToColor(accentHex) : AppColors.primaryBlueLight;
    const bg = AppColors.black;
    const surface = AppColors.black;
    const surfaceContainer = Color(0xFF0A0A0A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlueLight,
        onPrimary: AppColors.white,
        secondary: accent,
        onSecondary: AppColors.white,
        surface: surface,
        onSurface: AppColors.white,
        error: AppColors.error,
        outline: AppColors.grey900,
        surfaceContainer: surfaceContainer,
      ),
      textTheme: _buildTextTheme(AppColors.white),
      cardTheme: CardThemeData(
        color: AppColors.grey900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey900,
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey500),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundM,
          borderSide: const BorderSide(color: AppColors.grey800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundM,
          borderSide: const BorderSide(color: AppColors.grey800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundM,
          borderSide: const BorderSide(color: AppColors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.fieldPadding),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey900,
        labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.white),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
        side: BorderSide.none,
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          ColorScheme.dark(primary: AppColors.primaryBlueLight, secondary: accent),
          Brightness.dark,
          isAmoled: isAmoled,
        ),
      ],
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: textColor),
      displayMedium: AppTypography.displayMedium.copyWith(color: textColor),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: textColor),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: textColor),
      titleLarge: AppTypography.titleLarge.copyWith(color: textColor),
      titleMedium: AppTypography.titleMedium.copyWith(color: textColor),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: textColor),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: textColor),
      labelLarge: AppTypography.labelLarge.copyWith(color: textColor),
      labelSmall: AppTypography.labelMedium.copyWith(color: textColor),
    );
  }
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color onBg; // NEW: High contrast for background
  final Color card;
  final Color onCard; // NEW: High contrast for card
  final Color card2;
  final Color onCard2; // NEW: High contrast for card2
  final Color border;
  final Color text;
  final Color sub;
  final Color fill;
  final Color onFill; // NEW: High contrast for filled areas
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color purple;
  final Color meshBg; // NEW: Cal AI soft background
  final List<BoxShadow> shadowSoft;
  final LinearGradient mainGradient;

  const AppThemeColors({
    required this.bg,
    required this.onBg,
    required this.card,
    required this.onCard,
    required this.card2,
    required this.onCard2,
    required this.border,
    required this.text,
    required this.sub,
    required this.fill,
    required this.onFill,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.purple,
    required this.meshBg,
    required this.shadowSoft,
    required this.mainGradient,
  });

  // Semantic aliases for compatibility
  Color get red => error;
  Color get green => success;
  Color get amber => warning;
  Color get blue => info;

  Color get redLight => red.withValues(alpha: 0.1);
  Color get greenLight => green.withValues(alpha: 0.1);
  Color get amberLight => amber.withValues(alpha: 0.1);

  static AppThemeColors fromColorScheme(
      ColorScheme scheme, Brightness brightness,
      {bool isAmoled = false}) {
    final isDark = brightness == Brightness.dark;
    
    // PURE MONOCHROME BASE
    final bg = isDark ? AppColors.black : AppColors.white;
    final card = isDark ? AppColors.grey900 : AppColors.white;
    final card2 = isDark ? const Color(0xFF0A0A0A) : AppColors.grey100;
    
    final fill = isDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.black.withValues(alpha: 0.04);

    return AppThemeColors(
      bg: bg,
      onBg: isDark ? AppColors.white : AppColors.black,
      card: card,
      onCard: isDark ? AppColors.white : AppColors.black,
      card2: card2,
      onCard2: isDark ? AppColors.white : AppColors.black,
      border: isDark ? AppColors.grey800 : AppColors.grey200,
      text: isDark ? AppColors.white : AppColors.black,
      sub: isDark ? AppColors.grey500 : AppColors.grey600,
      fill: fill,
      onFill: isDark ? AppColors.white : AppColors.black,
      primary: isDark ? AppColors.white : AppColors.black,
      onPrimary: isDark ? AppColors.black : AppColors.white,
      secondary: scheme.secondary,
      error: AppColors.error,
      success: AppColors.success,
      warning: AppColors.warning,
      info: AppColors.info,
      purple: const Color(0xFF8B5CF6),
      meshBg: isDark ? AppColors.black : AppColors.meshBg,
      shadowSoft: isDark ? AppShadows.subtle : AppShadows.soft,
      mainGradient: AppGradients.main,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? bg,
    Color? onBg,
    Color? card,
    Color? onCard,
    Color? card2,
    Color? onCard2,
    Color? border,
    Color? text,
    Color? sub,
    Color? fill,
    Color? onFill,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? error,
    Color? success,
    Color? warning,
    Color? info,
    Color? purple,
    Color? meshBg,
    List<BoxShadow>? shadowSoft,
    LinearGradient? mainGradient,
  }) =>
      AppThemeColors(
        bg: bg ?? this.bg,
        onBg: onBg ?? this.onBg,
        card: card ?? this.card,
        onCard: onCard ?? this.onCard,
        card2: card2 ?? this.card2,
        onCard2: onCard2 ?? this.onCard2,
        border: border ?? this.border,
        text: text ?? this.text,
        sub: sub ?? this.sub,
        fill: fill ?? this.fill,
        onFill: onFill ?? this.onFill,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        secondary: secondary ?? this.secondary,
        error: error ?? this.error,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        purple: purple ?? this.purple,
        meshBg: meshBg ?? this.meshBg,
        shadowSoft: shadowSoft ?? this.shadowSoft,
        mainGradient: mainGradient ?? this.mainGradient,
      );

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      onBg: Color.lerp(onBg, other.onBg, t)!,
      card: Color.lerp(card, other.card, t)!,
      onCard: Color.lerp(onCard, other.onCard, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      onCard2: Color.lerp(onCard2, other.onCard2, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      sub: Color.lerp(sub, other.sub, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      meshBg: Color.lerp(meshBg, other.meshBg, t)!,
      shadowSoft: BoxShadow.lerpList(shadowSoft, other.shadowSoft, t)!,
      mainGradient: LinearGradient.lerp(mainGradient, other.mainGradient, t)!,
    );
  }
}

extension ThemeContextExtension on BuildContext {
  AppThemeColors get L =>
      Theme.of(this).extension<AppThemeColors>() ??
      AppThemeColors.fromColorScheme(
          Theme.of(this).colorScheme, Theme.of(this).brightness);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
