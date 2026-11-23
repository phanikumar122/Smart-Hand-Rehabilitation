import 'package:material_ui/material_ui.dart';

import '../utils/theme.dart';

class AnimatedProgressBar extends StatelessWidget {
  final String label;
  final int? angle;
  const AnimatedProgressBar({
    super.key,
    required this.label,
    required this.angle,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(angle == null ? '--' : '$angle°'),
          ],
        ),
        const SizedBox(height: 6),
        if (angle != null)
          LinearProgressIndicator(
            value: angle! / 90,
            color: AppTheme.primaryColor,
            minHeight: 12,
          )
        else
          const Text('No signal', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
