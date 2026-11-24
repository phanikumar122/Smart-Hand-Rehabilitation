import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Colors.white;
  static const Color backgroundColor = Color(0xFF0B0B0B);
  static const Color cardColor = Color(0xFF141414);
  static const Color errorColor = Colors.white;

  // All roles stay neutral, including status, fixed and elevated surfaces.
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEFEFEF),
    onPrimaryContainer: Colors.black,
    primaryFixed: Color(0xFFE4E4E4),
    primaryFixedDim: Color(0xFFCCCCCC),
    onPrimaryFixed: Colors.black,
    onPrimaryFixedVariant: Color(0xFF454545),
    secondary: Colors.black,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFEFEFEF),
    onSecondaryContainer: Colors.black,
    secondaryFixed: Color(0xFFE4E4E4),
    secondaryFixedDim: Color(0xFFCCCCCC),
    onSecondaryFixed: Colors.black,
    onSecondaryFixedVariant: Color(0xFF454545),
    tertiary: Colors.black,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFEFEFEF),
    onTertiaryContainer: Colors.black,
    tertiaryFixed: Color(0xFFE4E4E4),
    tertiaryFixedDim: Color(0xFFCCCCCC),
    onTertiaryFixed: Colors.black,
    onTertiaryFixedVariant: Color(0xFF454545),
    error: Colors.black,
    onError: Colors.white,
    errorContainer: Color(0xFFEFEFEF),
    onErrorContainer: Colors.black,
    surface: Color(0xFFF7F7F7),
    onSurface: Color(0xFF111111),
    surfaceDim: Color(0xFFE5E5E5),
    surfaceBright: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF5F5F5),
    surfaceContainer: Color(0xFFF0F0F0),
    surfaceContainerHigh: Color(0xFFEAEAEA),
    surfaceContainerHighest: Color(0xFFE4E4E4),
    onSurfaceVariant: Color(0xFF595959),
    outline: Color(0xFF737373),
    outlineVariant: Color(0xFFDDDDDD),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF202020),
    onInverseSurface: Colors.white,
    inversePrimary: Colors.white,
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF222222),
    onPrimaryContainer: Colors.white,
    primaryFixed: Color(0xFFE4E4E4),
    primaryFixedDim: Color(0xFFCCCCCC),
    onPrimaryFixed: Colors.black,
    onPrimaryFixedVariant: Color(0xFF454545),
    secondary: Colors.white,
    onSecondary: Colors.black,
    secondaryContainer: Color(0xFF222222),
    onSecondaryContainer: Colors.white,
    secondaryFixed: Color(0xFFE4E4E4),
    secondaryFixedDim: Color(0xFFCCCCCC),
    onSecondaryFixed: Colors.black,
    onSecondaryFixedVariant: Color(0xFF454545),
    tertiary: Colors.white,
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFF222222),
    onTertiaryContainer: Colors.white,
    tertiaryFixed: Color(0xFFE4E4E4),
    tertiaryFixedDim: Color(0xFFCCCCCC),
    onTertiaryFixed: Colors.black,
    onTertiaryFixedVariant: Color(0xFF454545),
    error: Colors.white,
    onError: Colors.black,
    errorContainer: Color(0xFF222222),
    onErrorContainer: Colors.white,
    surface: backgroundColor,
    onSurface: Color(0xFFF5F5F5),
    surfaceDim: backgroundColor,
    surfaceBright: Color(0xFF333333),
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: cardColor,
    surfaceContainer: Color(0xFF1A1A1A),
    surfaceContainerHigh: Color(0xFF242424),
    surfaceContainerHighest: Color(0xFF303030),
    onSurfaceVariant: Color(0xFFB8B8B8),
    outline: Color(0xFF8A8A8A),
    outlineVariant: Color(0xFF383838),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFEAEAEA),
    onInverseSurface: Colors.black,
    inversePrimary: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get lightTheme => _theme(_lightScheme);
  static ThemeData get darkTheme => _theme(_darkScheme);

  static ThemeData forLocale(Brightness brightness, String languageCode) =>
      _theme(
        brightness == Brightness.dark ? _darkScheme : _lightScheme,
        fontFamily: switch (languageCode) {
          'te' => 'NotoSansTelugu',
          'hi' => 'NotoSansDevanagari',
          _ => null,
        },
      );

  static ThemeData _theme(ColorScheme scheme, {String? fontFamily}) {
    final dark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      applyElevationOverlayColor: false,
      fontFamily: fontFamily,
      fontFamilyFallback: const ['NotoSansTelugu', 'NotoSansDevanagari'],
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: fontFamily == null ? -2 : 0,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: fontFamily == null ? -1.5 : 0,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: fontFamily == null ? -0.8 : 0,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: fontFamily == null ? -0.5 : 0,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: dark ? cardColor : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? cardColor : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
            size: 24,
          ),
        ),
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
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? cardColor : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
