import 'package:material_ui/material_ui.dart';

/// Futuristic dark palette. Names are kept from the first version so every
/// screen picks up the new look: `teal` is now neon cyan, `orange` is now
/// electric violet.
class AppColors {
  // Brand
  static const Color teal = Color(0xFF22D3EE); // neon cyan (primary)
  static const Color orange = Color(0xFFA78BFA); // electric violet (accent)
  static const Color magenta = Color(0xFFF472B6); // hot highlight

  // Surfaces
  static const Color background = Color(0xFF060A13);
  static const Color surface = Color(0xFF0E1526);
  static const Color surfaceHi = Color(0xFF151E36);
  static const Color border = Color(0xFF1F2B47);
  static const Color chipBg = Color(0xFF141D33);

  // Text
  static const Color ink = Color(0xFFEAF2FF);
  static const Color muted = Color(0xFF8B98B8);
  static const Color onNeon = Color(0xFF031018); // text on cyan/violet fills

  // Status
  static const Color green = Color(0xFF34D399);
  static const Color greenBg = Color(0x2234D399);
  static const Color warn = Color(0xFFFB7185);
  static const Color warnBg = Color(0x22FB7185);
}

class AppGradients {
  /// Cyan to violet: used for primary buttons, logo, highlights.
  static const LinearGradient neon = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.teal, AppColors.orange],
  );

  /// Soft glass fill used by cards.
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF131C33), Color(0xFF0B1222)],
  );
}

ThemeData buildTheme() {
  final scheme = const ColorScheme.dark().copyWith(
    primary: AppColors.teal,
    onPrimary: AppColors.onNeon,
    secondary: AppColors.orange,
    onSecondary: AppColors.onNeon,
    secondaryContainer: const Color(0xFF12324A),
    onSecondaryContainer: AppColors.teal,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.warn,
    outline: AppColors.border,
  );

  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final textTheme = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.ink,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      height: 68,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: inputBorder(AppColors.border),
      enabledBorder: inputBorder(AppColors.border),
      focusedBorder: inputBorder(AppColors.teal, 1.6),
      errorBorder: inputBorder(AppColors.warn),
      focusedErrorBorder: inputBorder(AppColors.warn, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.onNeon,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: Color(0x6622D3EE)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.teal),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.orange,
      foregroundColor: AppColors.onNeon,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHi,
      contentTextStyle: const TextStyle(color: AppColors.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerColor: AppColors.border,
  );
}
