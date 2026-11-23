import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/glove_data_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController.instance.load();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GloveDataProvider())],
      child: const SmartGloveApp(),
    ),
  );
}

class SmartGloveApp extends StatelessWidget {
  const SmartGloveApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppThemeController.instance,
    builder: (context, _) => MaterialApp(
      title: 'NerveLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppThemeController.instance.mode,
      home: const SplashScreen(),
    ),
  );
}
