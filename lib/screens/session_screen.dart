import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'settings_screen.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final seconds = provider.sessionElapsed.inSeconds;
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final data = provider.currentData;
    final colors = Theme.of(context).colorScheme;

    Future<void> toggleSession() async {
      if (!provider.isSessionActive) {
        provider.startSession();
        return;
      }
      await provider.stopSession();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.sessionMessage == null
                ? context.strings.sessionStopped
                : context.message(provider.sessionMessage!),
          ),
        ),
      );
    }

    return Scaffold(
      body: ResponsivePage(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                title: context.strings.session,
                trailing: StatusPill(
                  label: provider.isSessionActive
                      ? context.strings.recording
                      : provider.hasLiveData
                      ? context.strings.live
                      : context.strings.noSignal,
                  icon: provider.hasLiveData
                      ? Icons.sensors_rounded
                      : Icons.sensors_off_rounded,
                  tone: provider.hasLiveData ? colors.primary : colors.error,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: ClinicalCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: seconds.toDouble(),
                          end: seconds.toDouble(),
                        ),
                        duration: AppMotion.duration(context, AppMotion.fast),
                        curve: Curves.linear,
                        builder: (context, elapsed, child) => CustomPaint(
                          painter: _SessionRingPainter(
                            active: provider.isSessionActive,
                            progress: (elapsed % 60) / 60,
                            primary: colors.primary,
                            track: colors.surfaceContainerHighest,
                          ),
                          child: child,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 180,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    provider.isSessionActive
                                        ? Icons.graphic_eq_rounded
                                        : Icons.self_improvement_rounded,
                                    color: provider.isSessionActive
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    time,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                  Text(
                                    context.strings.elapsedTime,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isSavingSession
                            ? null
                            : provider.isSessionActive ||
                                  provider.canStartSession
                            ? toggleSession
                            : null,
                        icon: Icon(
                          provider.isSavingSession
                              ? Icons.hourglass_top_rounded
                              : provider.isSessionActive
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          provider.isSavingSession
                              ? context.strings.saving
                              : provider.isSessionActive
                              ? context.strings.stopSession
                              : context.strings.startSession,
                        ),
                        style: provider.isSessionActive
                            ? ElevatedButton.styleFrom(
                                backgroundColor: colors.error,
                                foregroundColor: colors.onError,
                              )
                            : null,
                      ),
                    ),
                    if (!provider.isSessionActive &&
                        !provider.canStartSession) ...[
                      const SizedBox(height: 14),
                      Text(
                        provider.hasLiveData && !provider.legacyFirmware
                            ? context.strings.calibrateInSettings
                            : context.strings.connectToBegin,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      if (provider.hasLiveData)
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          child: Text(context.strings.openSettings),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: context.strings.liveGrip,
                      value: data?.grip.toString() ?? '--',
                      icon: Icons.back_hand_outlined,
                      tone: colors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: context.strings.averageBend,
                      value: data == null
                          ? '--'
                          : '${(data.thumb + data.index + data.middle + data.ring + data.pinky) ~/ 5}°',
                      icon: Icons.gesture_rounded,
                      tone: colors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.sessionMessage case final String message)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: ClinicalCard(
                    color: colors.primaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.message(message))),
                      ],
                    ),
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

class _SessionRingPainter extends CustomPainter {
  _SessionRingPainter({
    required this.active,
    required this.progress,
    required this.primary,
    required this.track,
  });
  final bool active;
  final double progress;
  final Color primary;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, base);
    final arc = Paint()
      ..color = active ? primary : primary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      active ? math.max(0.06, progress) * math.pi * 2 : math.pi * 0.28,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _SessionRingPainter oldDelegate) =>
      oldDelegate.active != active ||
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary;
}
