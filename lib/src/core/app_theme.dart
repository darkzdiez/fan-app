import 'package:flutter/material.dart';

class FanAppTheme {
  static const Color brandBlue = Color(0xFF0B9BCB);
  static const Color brandBlueDark = Color(0xFF0A7FAF);
  static const Color ink = Color(0xFF18212B);
  static const Color muted = Color(0xFF5D6773);
  static const Color background = Color(0xFFF2F5F8);
  static const Color frame = Color(0xFFD7E0E7);
  static const Color header = Color(0xFF2F3135);
  static const Color softAccent = Color(0xFFDDECF7);

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    final colorScheme = base.colorScheme.copyWith(
      brightness: Brightness.light,
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: brandBlueDark,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: ink,
      outline: frame,
      outlineVariant: const Color(0xFFE7EDF3),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );
    final textTheme = base.textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    ).copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: muted,
        height: 1.35,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: header,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: frame),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      dividerTheme: const DividerThemeData(color: frame, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: header,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: const Color(0xFFEAF5FB),
        contentTextStyle: textTheme.bodyMedium,
        dividerColor: frame,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: muted),
        helperStyle: const TextStyle(color: muted),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: frame),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: frame),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlueDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: frame),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlueDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: softAccent,
        disabledColor: const Color(0xFFF3F5F7),
        side: const BorderSide(color: frame),
        shape: const StadiumBorder(side: BorderSide(color: frame)),
        labelStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: brandBlue,
        unselectedLabelColor: muted,
        indicatorColor: brandBlue,
        dividerColor: frame,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: softAccent,
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? brandBlueDark : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? brandBlueDark : muted,
            size: 24,
          );
        }),
      ),
    );
  }
}
