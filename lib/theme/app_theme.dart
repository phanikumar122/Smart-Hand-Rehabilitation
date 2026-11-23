import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF2DD4A8);
  static const Color backgroundColor = Color(0xFF071A20);
  static const Color cardColor = Color(0xFF0D2931);
  static const Color errorColor = Color(0xFFF16067);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF086F68),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD4F0E9),
    onPrimaryContainer: Color(0xFF063D39),
    secondary: Color(0xFFB85F38),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFDBCA),
    onSecondaryContainer: Color(0xFF5B2816),
    tertiary: Color(0xFF376B87),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFD1E9F7),
    onTertiaryContainer: Color(0xFF173F55),
    error: Color(0xFFC84C55),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDADD),
    onErrorContainer: Color(0xFF6B1F29),
    surface: Color(0xFFF4F7F5),
    onSurface: Color(0xFF15312F),
    surfaceContainerHighest: Color(0xFFE5ECE8),
    onSurfaceVariant: Color(0xFF596C68),
    outline: Color(0xFF9AA9A5),
    outlineVariant: Color(0xFFD4DEDA),
    shadow: Color(0xFF12312B),
    scrim: Colors.black,
    inverseSurface: Color(0xFF213A36),
    onInverseSurface: Color(0xFFF0F7F4),
    inversePrimary: Color(0xFF69DDCB),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2DD4A8),
    onPrimary: Color(0xFF00382E),
    primaryContainer: Color(0xFF155B4D),
    onPrimaryContainer: Color(0xFFB8F5E3),
    secondary: Color(0xFFFFB07C),
    onSecondary: Color(0xFF552407),
    secondaryContainer: Color(0xFF703818),
    onSecondaryContainer: Color(0xFFFFDBC6),
    tertiary: Color(0xFF66A9FF),
    onTertiary: Color(0xFF00315D),
    tertiaryContainer: Color(0xFF164B75),
    onTertiaryContainer: Color(0xFFCFE5FF),
    error: Color(0xFFF16067),
    onError: Color(0xFF450008),
    errorContainer: Color(0xFF721B25),
    onErrorContainer: Color(0xFFFFDADD),
    surface: Color(0xFF071A20),
    onSurface: Color(0xFFE7F2EF),
    surfaceContainerHighest: Color(0xFF173940),
    onSurfaceVariant: Color(0xFFB6C9C5),
    outline: Color(0xFF708985),
    outlineVariant: Color(0xFF2D4B4D),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFDCEAE6),
    onInverseSurface: Color(0xFF17312F),
    inversePrimary: Color(0xFF086F68),
  );

  static ThemeData get lightTheme => _theme(_lightScheme);
  static ThemeData get darkTheme => _theme(_darkScheme);

  static ThemeData _theme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF0D2931) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF0A232A) : Colors.white,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();
  static const _preferenceKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _preferenceKey,
    );
    _mode = ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      _preferenceKey,
      mode.name,
    );
  }
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppMotion {
  AppMotion._();
  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);

  static Duration duration(BuildContext context, Duration preferred) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false
      ? Duration.zero
      : preferred;
}
