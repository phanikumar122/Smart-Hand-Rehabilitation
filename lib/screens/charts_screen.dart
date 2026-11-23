import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../utils/theme.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Trends')),
      body: Consumer<GloveDataProvider>(
        builder: (context, provider, child) {
          if (provider.currentData == null || provider.history.isEmpty) {
            return const Center(child: Text('No signal'));
          }

          List<FlSpot> gripSpots = [];
          List<FlSpot> avgFingerSpots = [];

          final history = provider.history;
          final stride = (history.length / 300).ceil().clamp(1, 10);
          final selected = <int>{
            for (int i = 0; i < history.length; i += stride) i,
            history.length - 1,
          };
          for (final i in selected) {
            final data = history[i];
            final seconds =
                data.timestamp
                    .difference(history.first.timestamp)
                    .inMilliseconds /
                1000;
            gripSpots.add(FlSpot(seconds, data.grip.toDouble()));

            double avgFinger =
                (data.thumb +
                    data.index +
                    data.middle +
                    data.ring +
                    data.pinky) /
                5.0;
            avgFingerSpots.add(FlSpot(seconds, avgFinger));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Grip Force · raw (0–1023) · last 5 minutes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: gripSpots,
                          isCurved: false,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 1023,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Average Finger Angle · degrees',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: avgFingerSpots,
                          isCurved: false,
                          color: Colors.purpleAccent,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purpleAccent.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 90,
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
}
