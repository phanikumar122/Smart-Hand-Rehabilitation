import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import 'bluetooth_screen.dart';
import 'dashboard_screen.dart';
import 'hand_viz_screen.dart';
import 'charts_screen.dart';
import 'session_screen.dart';
import 'history_screen.dart';
import '../utils/theme.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HandVizScreen(),
    const ChartsScreen(),
    const SessionScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!context.watch<GloveDataProvider>().isConnected) {
      return const BluetoothScreen();
    }
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.front_hand), label: 'Hand'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Session'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
