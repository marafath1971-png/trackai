import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

// ══════════════════════════════════════════════
// PROFESSIONAL COLOR SYSTEM
// ══════════════════════════════════════════════

class AppColors {
  // ── Brand ─────────────────────────────────────────────
  // Cobalt Blue: Premium medical-grade primary
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF3B82F6);

  // ── Monochrome Base ────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Light mode surfaces (clean white)
  static const Color grey50 = Color(0xFFF8FAFF);  // Slight blue tint
  static const Color grey100 = Color(0xFFF0F4FF);
  static const Color grey200 = Color(0xFFE8ECF4);
  static const Color grey300 = Color(0xFFD0D7E8);
  static const Color grey400 = Color(0xFFABB4C8);
  static const Color grey500 = Color(0xFF7F8EA8);
  static const Color grey600 = Color(0xFF5A6680);

  // Dark mode surfaces (midnight navy)
  static const Color grey700 = Color(0xFF2D3650);
  static const Color grey800 = Color(0xFF1E2436);
  static const Color grey900 = Color(0xFF161B27);
  static const Color grey950 = Color(0xFF0D0F14);

  // ── Semantics ──────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);  // Emerald
  static const Color warning = Color(0xFFF59E0B);  // Warm amber
  static const Color info = Color(0xFF2563EB);

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
        onSurface: const Color(0xFF111827),
        error: AppColors.error,
        outline: AppColors.grey200,
        surfaceContainer: AppColors.grey50,
      ),
      textTheme: _buildTextTheme(const Color(0xFF111827)),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundL),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundL),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
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
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.fieldPadding),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        labelStyle: AppTypography.labelMedium.copyWith(color: const Color(0xFF111827)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    final bg = isAmoled ? AppColors.black : AppColors.grey950;
    final surface = isAmoled ? AppColors.black : AppColors.grey900;
    final surfaceContainer = isAmoled ? const Color(0xFF0A0A0A) : AppColors.grey800;

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
        outline: isAmoled ? AppColors.grey900 : AppColors.grey800,
        surfaceContainer: surfaceContainer,
      ),
      textTheme: _buildTextTheme(AppColors.white),
      cardTheme: CardThemeData(
        color: AppColors.grey900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundL),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundL),
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
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.fieldPadding),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey800,
        labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.white),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    final amoled = isDark && isAmoled;

    // Midnight navy dark / clean white light
    final bg = isDark
        ? (amoled ? AppColors.black : AppColors.grey950)
        : AppColors.grey50;
    final card = amoled
        ? AppColors.black
        : (isDark ? AppColors.grey900 : AppColors.white);
    final card2 = amoled
        ? const Color(0xFF080808)
        : (isDark ? AppColors.grey800 : AppColors.grey100);
    final fill = isDark
        ? AppColors.white.withValues(alpha: 0.06)
        : AppColors.grey200.withValues(alpha: 0.8);

    return AppThemeColors(
      bg: bg,
      onBg: bg.computeLuminance() > 0.5 ? const Color(0xFF111827) : AppColors.white,
      card: card,
      onCard: card.computeLuminance() > 0.5 ? const Color(0xFF111827) : AppColors.white,
      card2: card2,
      onCard2: card2.computeLuminance() > 0.5 ? const Color(0xFF111827) : AppColors.white,
      border: amoled
          ? AppColors.grey800
          : (isDark ? AppColors.grey700 : AppColors.grey200),
      text: isDark ? AppColors.white : const Color(0xFF111827),
      sub: isDark ? AppColors.grey400 : AppColors.grey500,
      fill: fill,
      onFill: fill.withValues(alpha: 1.0).computeLuminance() > 0.5
          ? const Color(0xFF111827)
          : AppColors.white,
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      secondary: scheme.secondary,
      error: AppColors.error,
      success: AppColors.success,
      warning: AppColors.warning,
      info: AppColors.info,
      purple: const Color(0xFF8B5CF6),
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
