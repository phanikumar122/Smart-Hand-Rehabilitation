import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/glove_data_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_locale_controller.dart';
import 'l10n/app_strings.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.instance.load();
  await AppLocaleController.instance.load();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GloveDataProvider())],
      child: const SmartGloveApp(),
    ),
  );
}

class SmartGloveApp extends StatelessWidget {
  const SmartGloveApp({super.key, this.localeController});
  final AppLocaleController? localeController;

  @override
  Widget build(BuildContext context) {
    final languages = localeController ?? AppLocaleController.instance;
    return AppLocaleScope(
      controller: languages,
      child: AnimatedBuilder(
        animation: Listenable.merge([AppThemeController.instance, languages]),
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => context.strings.appTitle,
          locale: languages.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          builder: (context, child) => Theme(
            data: AppTheme.forLocale(
              Theme.of(context).brightness,
              Localizations.localeOf(context).languageCode,
            ),
            child: child!,
          ),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppThemeController.instance.mode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
