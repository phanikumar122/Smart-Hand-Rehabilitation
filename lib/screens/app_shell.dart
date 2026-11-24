import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../theme/app_theme.dart';
import 'connection_screen.dart';
import 'today_screen.dart';
import 'live_hand_screen.dart';
import 'progress_screen.dart';
import 'session_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<GloveDataProvider>().isConnected) {
      return const ConnectionScreen();
    }
    final screens = [
      TodayScreen(
        onStartSession: () => setState(() => _currentIndex = 2),
        onViewLive: () => setState(() => _currentIndex = 1),
        onViewProgress: () => setState(() => _currentIndex = 3),
      ),
      const LiveHandScreen(),
      const SessionScreen(),
      const ProgressScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var index = 0; index < screens.length; index++)
            TickerMode(
              enabled: index == _currentIndex,
              child: AnimatedOpacity(
                opacity: index == _currentIndex ? 1 : 0,
                duration: AppMotion.duration(context, AppMotion.fast),
                child: screens[index],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: context.strings.today,
            ),
            NavigationDestination(
              icon: Icon(Icons.front_hand_outlined),
              selectedIcon: Icon(Icons.front_hand_rounded),
              label: context.strings.live,
            ),
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline_rounded),
              selectedIcon: Icon(Icons.play_circle_fill_rounded),
              label: context.strings.session,
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: context.strings.progress,
            ),
          ],
        ),
      ),
    );
  }
}
