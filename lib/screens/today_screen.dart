import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../widgets/app_components.dart';
import '../widgets/haptic_control_panel.dart';
import 'settings_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    this.onStartSession,
    this.onViewLive,
    this.onViewProgress,
  });
  final VoidCallback? onStartSession;
  final VoidCallback? onViewLive;
  final VoidCallback? onViewProgress;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final data = provider.currentData;
    final average = data == null
        ? null
        : (data.thumb + data.index + data.middle + data.ring + data.pinky) ~/ 5;
    return Scaffold(
      body: ResponsivePage(
        child: ListView(
          children: [
            AppPageHeader(
              title: context.strings.today,
              trailing: IconButton.filledTonal(
                tooltip: context.strings.settings,
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClinicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(
                      label: provider.hasLiveData
                          ? context.strings.live
                          : context.strings.noSignal,
                      icon: provider.hasLiveData
                          ? Icons.sensors_rounded
                          : Icons.sensors_off_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    provider.isSessionActive
                        ? context.strings.sessionInProgress
                        : context.strings.startASession,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onStartSession,
                    icon: Icon(
                      provider.isSessionActive
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      provider.isSessionActive
                          ? context.strings.viewSession
                          : context.strings.startSession,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: context.strings.latestReadings),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(16) > 24;
                final metrics = [
                  MetricTile(
                    label: context.strings.averageBend,
                    value: average == null ? '--' : '$average/90',
                    icon: Icons.gesture_rounded,
                  ),
                  MetricTile(
                    label: context.strings.grip,
                    value: data?.grip.toString() ?? '--',
                    icon: Icons.back_hand_outlined,
                  ),
                ];
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      metrics[0],
                      const SizedBox(height: 12),
                      metrics[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(width: 12),
                    Expanded(child: metrics[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewLive,
                  icon: const Icon(Icons.front_hand_outlined),
                  label: Text(context.strings.liveHand),
                ),
                OutlinedButton.icon(
                  onPressed: onViewProgress,
                  icon: const Icon(Icons.insights_outlined),
                  label: Text(context.strings.viewProgress),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: Text(context.strings.vibration),
              leading: const Icon(Icons.vibration_rounded),
              tilePadding: EdgeInsets.zero,
              children: [
                HapticControlPanel(key: ValueKey(provider.connectedDevice)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
