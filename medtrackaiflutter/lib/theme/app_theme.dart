import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

// ══════════════════════════════════════════════
// PROFESSIONAL COLOR SYSTEM
// ══════════════════════════════════════════════

class AppColors {
  // Brand
  static const Color lime = Color(0xFFA3E635);
  static const Color limeDark = Color(0xFF84CC16);
  
  // Monochrome Base
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9F9FB);
  static const Color grey100 = Color(0xFFF0F0F2);
  static const Color grey200 = Color(0xFFE5E5E7);
  static const Color grey300 = Color(0xFFD1D1D6);
  static const Color grey400 = Color(0xFFAEB0B3);
  static const Color grey500 = Color(0xFF8E8E93);
  static const Color grey600 = Color(0xFF636366);
  static const Color grey700 = Color(0xFF48484A);
  static const Color grey800 = Color(0xFF1C1C1E);
  static const Color grey900 = Color(0xFF111111);

  // Semantics
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF007AFF);

  // Compatibility Aliases
  static const Color lRed = error;
  static const Color dRed = error;
  static const Color oBg = black;
  static const Color oText = white;
  static const Color oBorder = grey800;
  static const Color oFill = grey900;
  static const Color oLime = lime;
  static const Color oLimeDark = limeDark;
}

class AppTheme {
  static ThemeData light({String? accentHex}) {
    final accent = accentHex != null ? hexToColor(accentHex) : AppColors.lime;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.light(
        primary: AppColors.black,
        onPrimary: AppColors.white,
        secondary: accent,
        onSecondary: AppColors.black,
        surface: AppColors.white,
        onSurface: AppColors.black,
        error: AppColors.error,
        outline: AppColors.grey200,
        surfaceContainer: AppColors.grey50,
      ),
      textTheme: _buildTextTheme(AppColors.black),
      cardTheme: CardThemeData(
        color: AppColors.grey50,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundM),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
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
        labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundS),
        side: BorderSide.none,
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          ColorScheme.light(primary: AppColors.black, secondary: accent),
          Brightness.light,
        ),
      ],
    );
  }

  static ThemeData dark({String? accentHex}) {
    final accent = accentHex != null ? hexToColor(accentHex) : AppColors.lime;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: ColorScheme.dark(
        primary: AppColors.white,
        onPrimary: AppColors.black,
        secondary: accent,
        onSecondary: AppColors.black,
        surface: AppColors.grey900,
        onSurface: AppColors.white,
        error: AppColors.error,
        outline: AppColors.grey800,
        surfaceContainer: AppColors.grey800,
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
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundS),
        side: BorderSide.none,
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          ColorScheme.dark(primary: AppColors.white, secondary: accent),
          Brightness.dark,
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
  final Color card;
  final Color card2;
  final Color border;
  final Color text;
  final Color sub;
  final Color fill;
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
    required this.card,
    required this.card2,
    required this.border,
    required this.text,
    required this.sub,
    required this.fill,
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

  static AppThemeColors fromColorScheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return AppThemeColors(
      bg: isDark ? AppColors.black : AppColors.white,
      card: isDark ? AppColors.grey900 : AppColors.grey50,
      card2: isDark ? AppColors.grey800 : AppColors.grey100,
      border: isDark ? AppColors.grey800 : AppColors.grey200,
      text: isDark ? AppColors.white : AppColors.black,
      sub: (isDark ? AppColors.grey400 : AppColors.grey600),
      fill: (isDark ? AppColors.white : AppColors.black).withValues(alpha: 0.08),
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      secondary: scheme.secondary,
      error: AppColors.error,
      success: AppColors.success,
      warning: AppColors.warning,
      info: AppColors.info,
      purple: const Color(0xFF5856D6),
      shadowSoft: isDark ? AppShadows.subtle : AppShadows.soft,
      mainGradient: AppGradients.main,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? bg,
    Color? card,
    Color? card2,
    Color? border,
    Color? text,
    Color? sub,
    Color? fill,
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
        card: card ?? this.card,
        card2: card2 ?? this.card2,
        border: border ?? this.border,
        text: text ?? this.text,
        sub: sub ?? this.sub,
        fill: fill ?? this.fill,
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
      card: Color.lerp(card, other.card, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      sub: Color.lerp(sub, other.sub, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
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
  AppThemeColors get L => Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.fromColorScheme(Theme.of(this).colorScheme, Theme.of(this).brightness);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

