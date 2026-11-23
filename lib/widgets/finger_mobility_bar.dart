import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class FingerMobilityBar extends StatelessWidget {
  final String label;
  final int? angle;
  const FingerMobilityBar({
    super.key,
    required this.label,
    required this.angle,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = angle == null ? 0.0 : (angle! / 90).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.fast),
                child: Text(
                  angle == null ? '--' : '$angle°',
                  key: ValueKey(angle),
                  style: TextStyle(
                    color: angle == null
                        ? colors.onSurfaceVariant
                        : colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: AppMotion.duration(context, AppMotion.standard),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) => LinearProgressIndicator(
                value: animatedValue,
                minHeight: 10,
                color: angle == null ? colors.outlineVariant : colors.primary,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
          ),
          if (angle == null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No signal',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
