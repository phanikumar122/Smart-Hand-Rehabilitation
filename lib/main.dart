import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/glove_data_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GloveDataProvider()),
      ],
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
      theme: AppTheme.darkTheme, // Enforcing dark mode as requested
      home: const SplashScreen(),
    );
  }
}
