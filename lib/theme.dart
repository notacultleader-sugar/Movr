import 'package:flutter/material.dart';

/// Colours from the client design guide.
class MovrColors {
  static const orange = Color(0xFFFF8C00); // Safety Orange (primary)
  static const black = Color(0xFF000000); // Pure Black (secondary)
  static const background = Color(0xFFF5F5F5); // Light grey so orange pops
  static const surface = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF6E6E6E);
  static const line = Color(0xFFE2E2E2);
  static const orangeTint = Color(0xFFFFF1DF);
  static const success = Color(0xFF1E9E5A);
  static const enRoute = Color(0xFF1E6FFF);
}

/// Every button and card uses a 16px "rounded square" radius.
const double kRadius = 16;
final BorderRadius kBorderRadius = BorderRadius.circular(kRadius);

const String kHeadingFont = 'Montserrat';
const String kBodyFont = 'Inter';

List<BoxShadow> get kFloatingShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 18,
    offset: const Offset(0, 6),
  ),
];

ThemeData buildMovrTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: kBodyFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MovrColors.orange,
      primary: MovrColors.orange,
      onPrimary: Colors.white,
      secondary: MovrColors.black,
      onSecondary: Colors.white,
      surface: MovrColors.surface,
    ),
    scaffoldBackgroundColor: MovrColors.background,
  );

  final shape = RoundedRectangleBorder(borderRadius: kBorderRadius);
  const buttonText = TextStyle(
    fontFamily: kHeadingFont,
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w800,
        fontSize: 30,
        color: MovrColors.black,
      ),
      headlineSmall: const TextStyle(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w800,
        fontSize: 22,
        color: MovrColors.black,
      ),
      titleLarge: const TextStyle(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: MovrColors.black,
      ),
      titleMedium: const TextStyle(
        fontFamily: kBodyFont,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: MovrColors.black,
      ),
      bodyMedium: const TextStyle(
        fontFamily: kBodyFont,
        fontSize: 14,
        color: MovrColors.black,
      ),
      bodySmall: const TextStyle(
        fontFamily: kBodyFont,
        fontSize: 12,
        color: MovrColors.textMuted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MovrColors.background,
      foregroundColor: MovrColors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: MovrColors.black,
      ),
    ),
    cardTheme: CardThemeData(
      color: MovrColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MovrColors.orange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: MovrColors.line,
        minimumSize: const Size.fromHeight(56),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MovrColors.black,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: MovrColors.line, width: 1.5),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: MovrColors.line),
      backgroundColor: MovrColors.surface,
      selectedColor: MovrColors.orange,
      labelStyle: const TextStyle(
        fontFamily: kBodyFont,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MovrColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MovrColors.black,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MovrColors.background,
      border: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
