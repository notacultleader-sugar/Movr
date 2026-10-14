import 'package:flutter/material.dart';

/// Colours from the client design guide.
class MovrColors {
  static const orange = Color(0xFFFF8C00); // Safety Orange (primary)
  // Client feedback (Oct 14): charcoal instead of pure black everywhere
  // except the logo, which is an image and keeps its own black.
  static const black = Color(0xFF2B2B2F); // Charcoal (secondary)
  static const charcoalDeep = Color(0xFF16161A); // Gradient end on dark cards
  static const background = Color(0xFFF4F2EF); // Warm off-white
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

/// Page background: warm off-white with a soft peach glow toward the
/// bottom, so screens have depth instead of flat white (client feedback).
const kPageGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8F7F5), Color(0xFFF3EFEB), Color(0xFFF2E3D7)],
  stops: [0, 0.55, 1],
);

/// Charcoal fill for the primary dark cards, lighter at the top.
const kCharcoalGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF34343A), MovrColors.charcoalDeep],
);

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
    // Each page paints kPageGradient behind its Scaffold; see
    // _GradientPageTransitions.
    scaffoldBackgroundColor: Colors.transparent,
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
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: _GradientPageTransitions(
            const PageTransitionsTheme().builders[p] ??
                const ZoomPageTransitionsBuilder(),
          ),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
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
      fillColor: MovrColors.surface,
      border: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

/// Wraps every page in the warm background gradient, then runs the
/// platform's usual page transition.
class _GradientPageTransitions extends PageTransitionsBuilder {
  const _GradientPageTransitions(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    DecoratedBox(
      decoration: const BoxDecoration(gradient: kPageGradient),
      child: child,
    ),
  );
}
