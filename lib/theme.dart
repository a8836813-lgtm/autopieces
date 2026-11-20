import 'package:material_ui/material_ui.dart';

class AppColors {
  static const Color teal = Color(0xFF0F4C5C);
  static const Color orange = Color(0xFFC2410C);
  static const Color background = Color(0xFFF6F5F2);
  static const Color ink = Color(0xFF14181F);
  static const Color muted = Color(0xFF5B6370);
  static const Color border = Color(0xFFE3E1DB);
  static const Color green = Color(0xFF14532D);
  static const Color greenBg = Color(0xFFDDEFE3);
  static const Color warn = Color(0xFF7C2D12);
  static const Color chipBg = Color(0xFFECEAE4);
  static const Color star = Color(0xFFD97706);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFBE4E4);
  static const Color warnBg = Color(0xFFFDE7D9);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.teal).copyWith(
    primary: AppColors.teal,
    secondary: AppColors.orange,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
    ),
  );
}
