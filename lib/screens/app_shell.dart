import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
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
      TodayScreen(onStartSession: () => setState(() => _currentIndex = 2)),
      const LiveHandScreen(),
      const SessionScreen(),
      const ProgressScreen(),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.02, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.front_hand_outlined),
              selectedIcon: Icon(Icons.front_hand_rounded),
              label: 'Live',
            ),
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline_rounded),
              selectedIcon: Icon(Icons.play_circle_fill_rounded),
              label: 'Session',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
