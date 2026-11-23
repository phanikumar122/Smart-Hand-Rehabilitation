import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../utils/theme.dart';

class HandVizScreen extends StatelessWidget {
  const HandVizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hand Visualization')),
      body: Consumer<GloveDataProvider>(
        builder: (context, provider, child) {
          final data = provider.currentData;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Simplified Hand Icon representation since we don't have SVG
                Icon(
                  Icons.pan_tool_rounded,
                  size: 300,
                  color: AppTheme.cardColor,
                ),
                // Thumb
                Positioned(
                  left: 20,
                  top: 150,
                  child: _buildFingerLabel('Thumb', data?.thumb),
                ),
                // Index
                Positioned(
                  left: 80,
                  top: 40,
                  child: _buildFingerLabel('Index', data?.index),
                ),
                // Middle
                Positioned(
                  left: 140,
                  top: 20,
                  child: _buildFingerLabel('Middle', data?.middle),
                ),
                // Ring
                Positioned(
                  right: 80,
                  top: 40,
                  child: _buildFingerLabel('Ring', data?.ring),
                ),
                // Pinky
                Positioned(
                  right: 20,
                  top: 100,
                  child: _buildFingerLabel('Pinky', data?.pinky),
                ),
                // Palm/Grip
                Positioned(
                  bottom: 120,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: Text(
                      data == null
                          ? 'Grip: --\nNo signal'
                          : 'Grip: ${data.grip}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFingerLabel(String name, int? angle) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor),
          ),
          child: Text(
            angle == null ? '--' : '$angle°',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
