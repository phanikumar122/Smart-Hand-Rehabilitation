import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/sensor_data.dart';
import '../providers/glove_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import '../widgets/finger_mobility_bar.dart';

class LiveHandScreen extends StatelessWidget {
  const LiveHandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final data = provider.currentData;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: ResponsivePage(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: 'Live biofeedback',
                title: 'Hand Visualization',
                subtitle:
                    'See each movement respond as your glove measures it.',
                trailing: StatusPill(
                  label: data == null ? 'No signal' : 'Live signal',
                  icon: data == null
                      ? Icons.sensors_off_rounded
                      : Icons.sensors_rounded,
                  tone: data == null ? colors.error : colors.primary,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: ClinicalCard(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.95,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: data?.grip.toDouble() ?? 0),
                        duration: AppMotion.duration(
                          context,
                          AppMotion.standard,
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, grip, _) => CustomPaint(
                          painter: _HandPainter(
                            data: data,
                            grip: grip,
                            primary: colors.primary,
                            secondary: colors.secondary,
                            outline: colors.outlineVariant,
                            surface: colors.surfaceContainerHighest,
                          ),
                          child: _HandLabels(data: data),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.duration(context, AppMotion.standard),
                      child: data == null
                          ? Text(
                              'No signal',
                              key: const ValueKey('no-signal'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            )
                          : StatusPill(
                              key: ValueKey(data.grip),
                              label: 'Grip: ${data.grip} / 1023',
                              icon: Icons.back_hand_rounded,
                              tone: colors.secondary,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: ClinicalCard(
                child: ExpansionTile(
                  initiallyExpanded: MediaQuery.sizeOf(context).height > 700,
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Sensor detail'),
                  subtitle: const Text('Individual bend angles'),
                  leading: const Icon(Icons.tune_rounded),
                  children: [
                    FingerMobilityBar(label: 'Thumb', angle: data?.thumb),
                    FingerMobilityBar(label: 'Index', angle: data?.index),
                    FingerMobilityBar(label: 'Middle', angle: data?.middle),
                    FingerMobilityBar(label: 'Ring', angle: data?.ring),
                    FingerMobilityBar(label: 'Pinky', angle: data?.pinky),
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

class _HandLabels extends StatelessWidget {
  const _HandLabels({required this.data});
  final SensorData? data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final labels = [
        ('Thumb', data?.thumb, const Alignment(-0.88, 0.18)),
        ('Index', data?.index, const Alignment(-0.53, -0.74)),
        ('Middle', data?.middle, const Alignment(-0.12, -0.94)),
        ('Ring', data?.ring, const Alignment(0.32, -0.78)),
        ('Pinky', data?.pinky, const Alignment(0.72, -0.5)),
      ];
      return Stack(
        children: [
          for (final label in labels)
            Align(
              alignment: label.$3,
              child: _FingerBadge(name: label.$1, value: label.$2),
            ),
        ],
      );
    },
  );
}

class _FingerBadge extends StatelessWidget {
  const _FingerBadge({required this.name, required this.value});
  final String name;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: Theme.of(context).textTheme.labelSmall),
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.fast),
            child: Text(
              value == null ? '--' : '$value°',
              key: ValueKey(value),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: value == null ? colors.onSurfaceVariant : colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter({
    required this.data,
    required this.grip,
    required this.primary,
    required this.secondary,
    required this.outline,
    required this.surface,
  });

  final SensorData? data;
  final double grip;
  final Color primary;
  final Color secondary;
  final Color outline;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.63);
    final pressure = (grip / 1023).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..color = secondary.withValues(alpha: 0.08 + pressure * 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, w * (0.13 + pressure * 0.11), glowPaint);

    final hand = Path()
      ..moveTo(w * 0.32, h * 0.88)
      ..cubicTo(w * 0.28, h * 0.74, w * 0.26, h * 0.62, w * 0.2, h * 0.55)
      ..cubicTo(w * 0.12, h * 0.46, w * 0.14, h * 0.37, w * 0.2, h * 0.37)
      ..cubicTo(w * 0.25, h * 0.37, w * 0.3, h * 0.45, w * 0.34, h * 0.49)
      ..lineTo(w * 0.32, h * 0.23)
      ..cubicTo(w * 0.32, h * 0.13, w * 0.43, h * 0.12, w * 0.44, h * 0.23)
      ..lineTo(w * 0.46, h * 0.12)
      ..cubicTo(w * 0.47, h * 0.02, w * 0.58, h * 0.03, w * 0.58, h * 0.14)
      ..lineTo(w * 0.58, h * 0.23)
      ..lineTo(w * 0.61, h * 0.15)
      ..cubicTo(w * 0.64, h * 0.06, w * 0.74, h * 0.1, w * 0.72, h * 0.2)
      ..lineTo(w * 0.7, h * 0.3)
      ..lineTo(w * 0.74, h * 0.27)
      ..cubicTo(w * 0.8, h * 0.2, w * 0.88, h * 0.27, w * 0.84, h * 0.36)
      ..lineTo(w * 0.76, h * 0.55)
      ..cubicTo(w * 0.72, h * 0.65, w * 0.68, h * 0.74, w * 0.66, h * 0.88)
      ..close();
    canvas.drawPath(hand, Paint()..color = surface.withValues(alpha: 0.7));
    canvas.drawPath(
      hand,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final values = data == null
        ? <int>[0, 0, 0, 0, 0]
        : [data!.thumb, data!.index, data!.middle, data!.ring, data!.pinky];
    final points = [
      Offset(w * 0.24, h * 0.43),
      Offset(w * 0.38, h * 0.22),
      Offset(w * 0.52, h * 0.14),
      Offset(w * 0.66, h * 0.2),
      Offset(w * 0.78, h * 0.33),
    ];
    for (var i = 0; i < points.length; i++) {
      final progress = values[i] / 90;
      final rect = Rect.fromCircle(center: points[i], radius: w * 0.07);
      canvas.drawArc(
        rect,
        math.pi * 0.75,
        math.pi * 1.5,
        false,
        Paint()
          ..color = outline.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5,
      );
      canvas.drawArc(
        rect,
        math.pi * 0.75,
        math.pi * 1.5 * progress,
        false,
        Paint()
          ..color = data == null ? outline : primary
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.grip != grip ||
      oldDelegate.primary != primary;
}
