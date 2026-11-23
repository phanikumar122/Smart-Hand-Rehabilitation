import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../widgets/app_components.dart';
import '../widgets/finger_mobility_bar.dart';
import '../widgets/haptic_control_panel.dart';
import 'settings_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.onStartSession});

  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final data = provider.currentData;
    final colors = Theme.of(context).colorScheme;
    final average = data == null
        ? null
        : (data.thumb + data.index + data.middle + data.ring + data.pinky) ~/ 5;

    return Scaffold(
      body: ResponsivePage(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: 'Smart Glove App · Today',
                title: 'Your recovery, in motion',
                subtitle:
                    'Small, consistent sessions create meaningful progress.',
                trailing: IconButton.filledTonal(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: StaggeredReveal(
                index: 0,
                child: ClinicalCard(
                  color: colors.primaryContainer,
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 560;
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusPill(
                            label: provider.status,
                            icon: provider.hasLiveData
                                ? Icons.sensors_rounded
                                : Icons.sensors_off_rounded,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            provider.isSessionActive
                                ? 'Session in progress'
                                : 'Ready for today’s session?',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: colors.onPrimaryContainer),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.isSessionActive
                                ? 'Keep moving comfortably. Your readings are being recorded.'
                                : provider.hasLiveData
                                ? 'Your glove is live and ready to record movement.'
                                : 'Waiting for a fresh sensor reading from your glove.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.onPrimaryContainer.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                          ),
                        ],
                      );
                      final button = ElevatedButton.icon(
                        onPressed: onStartSession,
                        icon: Icon(
                          provider.isSessionActive
                              ? Icons.graphic_eq_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          provider.isSessionActive
                              ? 'View Session'
                              : 'Start Session',
                        ),
                      );
                      return compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                details,
                                const SizedBox(height: 20),
                                button,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: details),
                                const SizedBox(width: 24),
                                button,
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: StaggeredReveal(
                index: 1,
                child: ClinicalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Live snapshot',
                        caption: 'System Status · Finger Bending Angles',
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.sizeOf(context).width > 600
                            ? 3
                            : 2,
                        childAspectRatio: 1.45,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          MetricTile(
                            label: 'Average mobility',
                            value: average == null ? '--' : '$average°',
                            icon: Icons.gesture_rounded,
                          ),
                          MetricTile(
                            label: 'Grip Force · raw (0–1023)',
                            value: data?.grip.toString() ?? '--',
                            icon: Icons.back_hand_outlined,
                            tone: colors.secondary,
                          ),
                          MetricTile(
                            label: 'Glove',
                            value:
                                provider.connectedDevice?.displayName ??
                                'Connected',
                            icon: Icons.bluetooth_connected_rounded,
                            tone: colors.tertiary,
                          ),
                        ],
                      ),
                      if (data == null) ...[
                        const SizedBox(height: 14),
                        Text(
                          'No signal',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: StaggeredReveal(
                index: 2,
                child: ClinicalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Finger mobility',
                        caption: 'Real-time bend range from 0° to 90°',
                      ),
                      const SizedBox(height: 12),
                      FingerMobilityBar(label: 'Thumb', angle: data?.thumb),
                      FingerMobilityBar(label: 'Index', angle: data?.index),
                      FingerMobilityBar(label: 'Middle', angle: data?.middle),
                      FingerMobilityBar(label: 'Ring', angle: data?.ring),
                      FingerMobilityBar(label: 'Pinky', angle: data?.pinky),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: StaggeredReveal(
                index: 3,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('Glove controls'),
                  subtitle: const Text('Haptic feedback and vibration'),
                  leading: const Icon(Icons.vibration_rounded),
                  children: [
                    HapticControlPanel(key: ValueKey(provider.connectedDevice)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}
