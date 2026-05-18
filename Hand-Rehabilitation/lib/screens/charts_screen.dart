import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/glove_data_provider.dart';
import '../utils/theme.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Trends')),
      body: Consumer<GloveDataProvider>(
        builder: (context, provider, child) {
          if (provider.history.isEmpty) {
            return const Center(child: Text("No data available yet"));
          }

          List<FlSpot> gripSpots = [];
          List<FlSpot> avgFingerSpots = [];
          
          for (int i = 0; i < provider.history.length; i++) {
            final data = provider.history[i];
            gripSpots.add(FlSpot(i.toDouble(), data.grip.toDouble() / 10.0)); // scale down for chart
            
            double avgFinger = (data.thumb + data.index + data.middle + data.ring + data.pinky) / 5.0;
            avgFingerSpots.add(FlSpot(i.toDouble(), avgFinger));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Grip Force Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: gripSpots,
                          isCurved: true,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 110,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('Average Finger Movement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: avgFingerSpots,
                          isCurved: true,
                          color: Colors.purpleAccent,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purpleAccent.withOpacity(0.2),
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 100,
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
