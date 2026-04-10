import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/color_utils.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

// ══════════════════════════════════════════════
// PROFESSIONAL COLOR SYSTEM
// ══════════════════════════════════════════════

class AppColors {
  // ── Brand ─────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF000000);
  static const Color primaryBlueDark = Color(0xFF000000);
  static const Color primaryBlueLight = Color(0xFF1A1A1A);
  static const Color limeAccent = Color(0xFFCDFF00); // 2026 Core Accent

  // ── Monochrome Base ────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color meshBg = Color(0xFFF5F5F7);

  static const Color grey50 = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey300 = Color(0xFFD4D4D4);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey700 = Color(0xFF404040);
  static const Color grey800 = Color(0xFF262626);
  static const Color grey900 = Color(0xFF171717);
  static const Color grey950 = Color(0xFF000000);

  // ── Muted Functional Semantics ─────────────────────────
  static const Color error = Color(0xFF991B1B); // Crimson Rose (Light)
  static const Color success = Color(0xFF2D6A4F); // Sage Emerald (Light)
  static const Color warning = Color(0xFFB45309); // Amber Ocher (Light)

  static const Color errorDark = Color(0xFFF87171); // Light Crimson (Dark Mode)
  static const Color successDark = Color(0xFF52B788); // Light Sage (Dark Mode)
  static const Color warningDark = Color(0xFFFBBF24); // Light Amber (Dark Mode)

  static const Color info = Color(0xFF1E293B); // deep slate

  // ── Compatibility Aliases ─────────────────────────────
  static const Color lRed = error;
  static const Color dRed = error;
  static const Color oBg = grey950;
  static const Color oText = white;
  static const Color oBorder = grey800;
  static const Color oFill = grey900;
  static const Color oLime = limeAccent;
  static const Color oLimeDark = limeAccent;
}

class AppTheme {
  static ThemeData light({String? accentHex}) {
    final accent =
        accentHex != null ? hexToColor(accentHex) : AppColors.primaryBlue;

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.meshBg,
      colorScheme: ColorScheme.light(
        primary: AppColors.black,
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.grey400),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.black
                : AppColors.grey200),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        splashRadius: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundXL,
          borderSide: const BorderSide(color: AppColors.black, width: 0.5),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.fieldPadding),
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

  static ThemeData dark({bool isAmoled = true, String? accentHex}) {
    const accent = AppColors.limeAccent;
    const bg = AppColors.black; // OLED Perfect Black strictly enforced
    const surface = AppColors.black; // Surfaces meld into background
    const surfaceContainer = AppColors.grey950; // Ultra subtle lift

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.white,
        onPrimary: AppColors.black,
        secondary: accent,
        onSecondary: AppColors.black,
        surface: surface,
        onSurface: AppColors.white,
        error: AppColors.error,
        outline: AppColors.grey800,
        surfaceContainer: surfaceContainer,
      ),
      textTheme: _buildTextTheme(AppColors.white),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.black
                : AppColors.grey600),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.grey900),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        splashRadius: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.grey950, // Darker card for true black bg
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundXL),
          elevation: 0,
        ),
      ),
    ).copyWith(
      extensions: [
        AppThemeColors.fromColorScheme(
          const ColorScheme.dark(
              primary: AppColors.primaryBlueLight, secondary: accent),
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
      labelMedium: AppTypography.labelMedium.copyWith(color: textColor),
      labelSmall: AppTypography.labelMedium.copyWith(color: textColor),
    );
  }
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color onBg;
  final Color card;
  final Color onCard;
  final Color card2;
  final Color onCard2;
  final Color border;
  final Color text;
  final Color sub;
  final Color fill;
  final Color onFill;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color error;
  final Color red;
  final Color redLight;
  final Color success;
  final Color green;
  final Color greenLight;
  final Color warning;
  final Color amber;
  final Color info;
  final Color purple;
  final Color meshBg;
  final Color glass;
  final Color glassBorder;
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
    required this.red,
    required this.redLight,
    required this.success,
    required this.green,
    required this.greenLight,
    required this.warning,
    required this.amber,
    required this.info,
    required this.purple,
    required this.meshBg,
    required this.glass,
    required this.glassBorder,
    required this.shadowSoft,
    required this.mainGradient,
  });

  factory AppThemeColors.fromColorScheme(
      ColorScheme colorScheme, Brightness brightness,
      {bool isAmoled = false}) {
    final isDark = brightness == Brightness.dark;

    return AppThemeColors(
      bg: isDark ? Colors.black : AppColors.meshBg,
      onBg: isDark ? AppColors.white : AppColors.black,
      card: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.white,
      onCard: isDark ? AppColors.white : AppColors.black,
      card2: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
      onCard2: isDark ? AppColors.white : AppColors.black,
      border: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.grey200,
      text: isDark ? AppColors.white : AppColors.black,
      sub: isDark ? AppColors.grey500 : AppColors.grey500,
      fill: isDark ? Colors.white.withValues(alpha: 0.10) : AppColors.grey100,
      onFill: isDark ? AppColors.white : AppColors.black,
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      secondary: colorScheme.secondary,
      error: isDark ? AppColors.errorDark : AppColors.error,
      red: isDark ? AppColors.errorDark : AppColors.error,
      redLight: isDark
          ? (isDark ? AppColors.errorDark : AppColors.error)
              .withValues(alpha: 0.15)
          : AppColors.error.withValues(alpha: 0.15),
      success: isDark ? AppColors.successDark : AppColors.success,
      green: isDark ? AppColors.successDark : AppColors.success,
      greenLight: isDark
          ? (isDark ? AppColors.successDark : AppColors.success)
              .withValues(alpha: 0.15)
          : AppColors.success.withValues(alpha: 0.15),
      warning: isDark ? AppColors.warningDark : AppColors.warning,
      amber: isDark ? AppColors.warningDark : AppColors.warning,
      info: AppColors.info,
      purple: const Color(0xFF7C3AED),
      meshBg: isDark ? AppColors.black : AppColors.meshBg,
      glass: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.7),
      glassBorder: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      shadowSoft: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ],
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
    Color? red,
    Color? redLight,
    Color? success,
    Color? green,
    Color? greenLight,
    Color? warning,
    Color? amber,
    Color? info,
    Color? purple,
    Color? meshBg,
    Color? glass,
    Color? glassBorder,
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
        red: red ?? this.red,
        redLight: redLight ?? this.redLight,
        success: success ?? this.success,
        green: green ?? this.green,
        greenLight: greenLight ?? this.greenLight,
        warning: warning ?? this.warning,
        amber: amber ?? this.amber,
        info: info ?? this.info,
        purple: purple ?? this.purple,
        meshBg: meshBg ?? this.meshBg,
        glass: glass ?? this.glass,
        glassBorder: glassBorder ?? this.glassBorder,
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
      red: Color.lerp(red, other.red, t)!,
      redLight: Color.lerp(redLight, other.redLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenLight: Color.lerp(greenLight, other.greenLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      info: Color.lerp(info, other.info, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      meshBg: Color.lerp(meshBg, other.meshBg, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
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
