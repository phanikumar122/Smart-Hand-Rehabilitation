import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/glove_data_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() {
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Assistive Glove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
