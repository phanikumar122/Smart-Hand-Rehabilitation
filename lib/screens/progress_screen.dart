import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

import 'package:provider/provider.dart';

import '../models/sensor_data.dart';
import '../providers/glove_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'session_history_view.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final hasLiveData = context.watch<GloveDataProvider>().currentData != null;
    return Scaffold(
      body: ResponsivePage(
        child: Column(
          children: [
            AppPageHeader(title: context.strings.progress),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.show_chart_rounded),
                    label: Text(context.strings.liveTrends),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.history_rounded),
                    label: Text(context.strings.sessions),
                  ),
                ],
                selected: {_section},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _section = value.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _section == 0
                  ? hasLiveData
                        ? const _LiveTrends(key: ValueKey('trends'))
                        : EmptyState(
                            key: ValueKey('no-signal'),
                            icon: Icons
                                .signal_cellular_connected_no_internet_0_bar_rounded,
                            title: context.strings.noSignal,
                            message: context.strings.connectForTrends,
                          )
                  : const SessionHistoryView(
                      key: ValueKey('sessions'),
                      embedded: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrends extends StatefulWidget {
  const _LiveTrends({super.key});
  @override
  State<_LiveTrends> createState() => _LiveTrendsState();
}

class _LiveTrendsState extends State<_LiveTrends> {
  int _windowSeconds = 300;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final history = provider.history;
    if (history.isEmpty) {
      return EmptyState(
        icon: Icons.signal_cellular_connected_no_internet_0_bar_rounded,
        title: context.strings.noSignal,
        message: context.strings.connectForTrends,
      );
    }
    final cutoff = history.last.timestamp.subtract(
      Duration(seconds: _windowSeconds),
    );
    final filtered = history
        .where((item) => !item.timestamp.isBefore(cutoff))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 30, label: Text(context.strings.live)),
              ButtonSegment(value: 60, label: Text(context.strings.oneMinute)),
              ButtonSegment(
                value: 300,
                label: Text(context.strings.fiveMinutes),
              ),
            ],
            selected: {_windowSeconds},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _windowSeconds = value.first),
          ),
        ),
        const SizedBox(height: 14),
        _TrendCard(
          title: context.strings.grip,
          caption: context.strings.sensorReading,
          history: filtered,
          accessor: (data) => data.grip.toDouble(),
          maxY: 1023,
          tone: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 14),
        _TrendCard(
          title: context.strings.averageBend,
          caption: context.strings.movementScale,
          history: filtered,
          accessor: (data) =>
              (data.thumb + data.index + data.middle + data.ring + data.pinky) /
              5,
          maxY: 90,
          tone: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.caption,
    required this.history,
    required this.accessor,
    required this.maxY,
    required this.tone,
  });
  final String title;
  final String caption;
  final List<SensorData> history;
  final double Function(SensorData) accessor;
  final double maxY;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stride = (history.length / 300).ceil().clamp(1, 10);
    final selected = <int>{
      for (var i = 0; i < history.length; i += stride) i,
      history.length - 1,
    };
    final spots = [
      for (final index in selected)
        FlSpot(
          history[index].timestamp
                  .difference(history.first.timestamp)
                  .inMilliseconds /
              1000,
          accessor(history[index]),
        ),
    ];
    return ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, caption: caption),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.inverseSurface,
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            spot.y.toStringAsFixed(0),
                            TextStyle(
                              color: colors.onInverseSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: spots.length > 2,
                    curveSmoothness: 0.25,
                    color: tone,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY / 2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.outlineVariant, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
              duration: AppMotion.duration(context, AppMotion.fast),
            ),
          ),
        ],
      ),
    );
  }
}
