import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════
// COLOR TOKENS (matching JSX L_LIGHT / L_DARK)
// ══════════════════════════════════════════════

class AppColors {
  // Light theme
  static const Color lBg = Color(0xFFF5F5F5);
  static const Color lCard = Color(0xFFFFFFFF);
  static const Color lCard2 = Color(0xFFFAFAFA);
  static const Color lBorder = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color lText = Color(0xFF111111);
  static const Color lSub = Color(0x72000000); // rgba(0,0,0,0.45)
  static const Color lFill = Color(0x0F000000); // rgba(0,0,0,0.06)

  static const Color lGreen = Color(0xFF22C55E);
  static const Color lGreenDark = Color(0xFF16A34A);
  static const Color lGreenLight = Color(0xFFDCFCE7);
  static const Color lRed = Color(0xFFEF4444);
  static const Color lRedLight = Color(0xFFFEE2E2);
  static const Color lAmber = Color(0xFFF97316);
  static const Color lAmberLight = Color(0xFFFFF0E6);
  static const Color lBlue = Color(0xFF3B82F6);
  static const Color lBlueLight = Color(0xFFEFF6FF);
  static const Color lPurple = Color(0xFF8B5CF6);
  static const Color lPurpleLight = Color(0xFFEDE9FE);
  static const Color lIndigo = Color(0xFF6366F1);
  static const Color lPink = Color(0xFFEC4899);
  static const Color lTeal = Color(0xFF06B6D4);
  static const Color lAccent = Color(0xFF111111);
  static const Color lAccentText = Color(0xFFFFFFFF);

  // Dark theme
  static const Color dBg = Color(0xFF0A0A0F);
  static const Color dCard = Color(0xFF1C1C1E);
  static const Color dCard2 = Color(0xFF2C2C2E);
  static const Color dBorder = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const Color dText = Color(0xFFFFFFFF);
  static const Color dSub = Color(0x8CFFFFFF); // rgba(255,255,255,0.55)
  static const Color dFill = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  static const Color dGreen = Color(0xFF34C759);
  static const Color dGreenDark = Color(0xFF248A3D);
  static const Color dGreenLight = Color(0x2634C759); // 0.15 opacity
  static const Color dRed = Color(0xFFFF453A);
  static const Color dRedLight = Color(0x2EFF453A);
  static const Color dAmber = Color(0xFFFF9F0A);
  static const Color dAmberLight = Color(0x26FF9F0A);
  static const Color dBlue = Color(0xFF0A84FF);
  static const Color dBlueLight = Color(0x260A84FF);
  static const Color dPurple = Color(0xFFBF5AF2);
  static const Color dPurpleLight = Color(0x26BF5AF2);
  static const Color dTeal = Color(0xFF5AC8FA);
  static const Color dIndigo = Color(0xFF5E5CE6);
  static const Color dPink = Color(0xFFFF375F);

  // Onboarding dark theme (D object)
  static const Color oBg = Color(0xFF0A0A0F);
  static const Color oCard = Color(0xFF13131A);
  static const Color oBorder = Color(0xFF1E1E2A);
  static const Color oText = Color(0xFFF0F0F5);
  static const Color oSub = Color(0xFF8080A0);
  static const Color oLime = Color(0xFFA3E635);
  static const Color oLimeDark = Color(0xFF84CC16);
  static const Color oLimeDim = Color(0x1FA3E635); // rgba(163,230,53,0.12)
  static const Color oGreen = Color(0xFF10B981);

  // Black (Cal AI style)
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
}

// ══════════════════════════════════════════════
// APP THEME
// ══════════════════════════════════════════════

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lAccent,
        surface: AppColors.lCard,
        onPrimary: AppColors.white,
        onSurface: AppColors.lText,
        secondary: AppColors.lGreen,
        error: AppColors.lRed,
      ),
      textTheme: _buildTextTheme(AppColors.lText),
      cardTheme: const CardThemeData(
        color: AppColors.lCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lBg,
        foregroundColor: AppColors.lText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.white,
        surface: AppColors.dCard,
        onPrimary: AppColors.black,
        onSurface: AppColors.dText,
        secondary: AppColors.dGreen,
        error: AppColors.dRed,
      ),
      textTheme: _buildTextTheme(AppColors.dText),
      cardTheme: const CardThemeData(
        color: AppColors.dCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dBg,
        foregroundColor: AppColors.dText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.interTextTheme(TextTheme(
      displayLarge: TextStyle(
          fontWeight: FontWeight.w900, color: textColor, letterSpacing: -2),
      displayMedium: TextStyle(
          fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1),
      headlineLarge: TextStyle(
          fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: textColor),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: textColor),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: textColor),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, color: textColor),
    ));
  }
}

// ══════════════════════════════════════════════
// THEME EXTENSION (holds semantic colors like useTheme() in JSX)
// ══════════════════════════════════════════════

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color card;
  final Color card2;
  final Color border;
  final Color text;
  final Color sub;
  final Color fill;
  final Color green;
  final Color greenDark;
  final Color greenLight;
  final Color red;
  final Color redLight;
  final Color amber;
  final Color amberLight;
  final Color blue;
  final Color blueLight;
  final Color purple;
  final Color purpleLight;
  final Color teal;

  const AppThemeColors({
    required this.bg,
    required this.card,
    required this.card2,
    required this.border,
    required this.text,
    required this.sub,
    required this.fill,
    required this.green,
    required this.greenDark,
    required this.greenLight,
    required this.red,
    required this.redLight,
    required this.amber,
    required this.amberLight,
    required this.blue,
    required this.blueLight,
    required this.purple,
    required this.purpleLight,
    required this.teal,
  });

  static const light = AppThemeColors(
    bg: AppColors.lBg,
    card: AppColors.lCard,
    card2: AppColors.lCard2,
    border: AppColors.lBorder,
    text: AppColors.lText,
    sub: AppColors.lSub,
    fill: AppColors.lFill,
    green: AppColors.lGreen,
    greenDark: AppColors.lGreenDark,
    greenLight: AppColors.lGreenLight,
    red: AppColors.lRed,
    redLight: AppColors.lRedLight,
    amber: AppColors.lAmber,
    amberLight: AppColors.lAmberLight,
    blue: AppColors.lBlue,
    blueLight: AppColors.lBlueLight,
    purple: AppColors.lPurple,
    purpleLight: AppColors.lPurpleLight,
    teal: AppColors.lTeal,
  );

  static const dark = AppThemeColors(
    bg: AppColors.dBg,
    card: AppColors.dCard,
    card2: AppColors.dCard2,
    border: AppColors.dBorder,
    text: AppColors.dText,
    sub: AppColors.dSub,
    fill: AppColors.dFill,
    green: AppColors.dGreen,
    greenDark: AppColors.dGreenDark,
    greenLight: AppColors.dGreenLight,
    red: AppColors.dRed,
    redLight: AppColors.dRedLight,
    amber: AppColors.dAmber,
    amberLight: AppColors.dAmberLight,
    blue: AppColors.dBlue,
    blueLight: AppColors.dBlueLight,
    purple: AppColors.dPurple,
    purpleLight: AppColors.dPurpleLight,
    teal: AppColors.dTeal,
  );

  @override
  AppThemeColors copyWith({
    Color? bg,
    Color? card,
    Color? card2,
    Color? border,
    Color? text,
    Color? sub,
    Color? fill,
    Color? green,
    Color? greenDark,
    Color? greenLight,
    Color? red,
    Color? redLight,
    Color? amber,
    Color? amberLight,
    Color? blue,
    Color? blueLight,
    Color? purple,
    Color? purpleLight,
    Color? teal,
  }) =>
      AppThemeColors(
        bg: bg ?? this.bg,
        card: card ?? this.card,
        card2: card2 ?? this.card2,
        border: border ?? this.border,
        text: text ?? this.text,
        sub: sub ?? this.sub,
        fill: fill ?? this.fill,
        green: green ?? this.green,
        greenDark: greenDark ?? this.greenDark,
        greenLight: greenLight ?? this.greenLight,
        red: red ?? this.red,
        redLight: redLight ?? this.redLight,
        amber: amber ?? this.amber,
        amberLight: amberLight ?? this.amberLight,
        blue: blue ?? this.blue,
        blueLight: blueLight ?? this.blueLight,
        purple: purple ?? this.purple,
        purpleLight: purpleLight ?? this.purpleLight,
        teal: teal ?? this.teal,
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
      green: Color.lerp(green, other.green, t)!,
      greenDark: Color.lerp(greenDark, other.greenDark, t)!,
      greenLight: Color.lerp(greenLight, other.greenLight, t)!,
      red: Color.lerp(red, other.red, t)!,
      redLight: Color.lerp(redLight, other.redLight, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberLight: Color.lerp(amberLight, other.amberLight, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueLight: Color.lerp(blueLight, other.blueLight, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      purpleLight: Color.lerp(purpleLight, other.purpleLight, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
    );
  }
}

// Helper extension to get AppThemeColors from context
extension ThemeContextExtension on BuildContext {
  AppThemeColors get L =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
