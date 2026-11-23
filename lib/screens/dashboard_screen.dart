import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../widgets/progress_bar.dart';
import '../widgets/vibration_panel.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final data = provider.currentData;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dashboard'),
        actions: [
          Icon(
            provider.isConnected
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('System Status'),
                      Text(
                        provider.status,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (provider.connectedDevice case final device?)
                        Text(device.displayName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Finger Bending Angles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnimatedProgressBar(label: 'Thumb', angle: data?.thumb),
                      AnimatedProgressBar(label: 'Index', angle: data?.index),
                      AnimatedProgressBar(label: 'Middle', angle: data?.middle),
                      AnimatedProgressBar(label: 'Ring', angle: data?.ring),
                      AnimatedProgressBar(label: 'Pinky', angle: data?.pinky),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Grip Force · raw (0–1023)'),
                      Text(
                        data?.grip.toString() ?? '--',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      if (data == null)
                        const Text('No signal')
                      else
                        LinearProgressIndicator(
                          value: data.grip / 1023,
                          minHeight: 12,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              VibrationPanel(key: ValueKey(provider.connectedDevice)),
            ],
          ),
        ),
      ),
    );
  }
}
