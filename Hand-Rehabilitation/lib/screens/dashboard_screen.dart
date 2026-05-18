import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glove_data_provider.dart';
import '../widgets/progress_bar.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dashboard'),
        actions: [
          Consumer<GloveDataProvider>(
            builder: (context, provider, child) {
              return Icon(
                provider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: provider.isConnected ? AppTheme.primaryColor : Colors.grey,
              );
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<GloveDataProvider>(
        builder: (context, provider, child) {
          final data = provider.currentData;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(provider.isConnected, data.grip),
                const SizedBox(height: 24),
                Text('Finger Bending Angles', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        AnimatedProgressBar(label: 'Thumb', value: (data.thumb / 90.0).clamp(0.0, 1.0)),
                        AnimatedProgressBar(label: 'Index', value: (data.index / 90.0).clamp(0.0, 1.0)),
                        AnimatedProgressBar(label: 'Middle', value: (data.middle / 90.0).clamp(0.0, 1.0)),
                        AnimatedProgressBar(label: 'Ring', value: (data.ring / 90.0).clamp(0.0, 1.0)),
                        AnimatedProgressBar(label: 'Pinky', value: (data.pinky / 90.0).clamp(0.0, 1.0)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Grip Pressure', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: (data.grip / 1023.0).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 15,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            );
                          },
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            data.grip.toString(),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const Text('RAW FORCE', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isConnected, int grip) {
    String status = isConnected ? (grip > 500 ? "Excellent Grip!" : "Keep Moving") : "Disconnected";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected 
              ? [const Color(0xFF00FFCC), const Color(0xFF0088AA)] 
              : [Colors.grey.shade800, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Status', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            status,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
