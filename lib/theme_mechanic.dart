import 'package:material_ui/material_ui.dart';

/// Dark "neon" palette used by the mechanic space.
class MechColors {
  static const Color bg = Color(0xFF060A12);
  static const Color surface = Color(0xFF0E1522);
  static const Color surface2 = Color(0xFF141D2E);
  static const Color border = Color(0xFF1F2B42);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color lime = Color(0xFFA3E635);
  static const Color amber = Color(0xFFFBBF24);
  static const Color red = Color(0xFFF87171);
  static const Color text = Color(0xFFE6EDF7);
  static const Color muted = Color(0xFF8A97AD);

  /// Text color for buttons that have a bright neon background.
  static const Color onNeon = Color(0xFF04121A);
}

ThemeData buildMechanicTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MechColors.cyan,
    brightness: Brightness.dark,
  ).copyWith(
    primary: MechColors.cyan,
    secondary: MechColors.violet,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MechColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: MechColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MechColors.surface,
      indicatorColor: MechColors.cyan.withAlpha(48),
    ),
    dialogBackgroundColor: MechColors.surface2,
  );
}
